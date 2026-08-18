// اللعبة: مشهد Three.js فوق شوارع ومباني حقيقية (مجلوبة من OpenStreetMap)
// مع فيزياء دريفت أركيدية وكاميرا مطاردة.
import * as THREE from "../vendor/three/three.module.min.js";

const els = {
  canvas: document.getElementById("scene"),
  loading: document.getElementById("loading"),
  loadingText: document.getElementById("loading-text"),
  errorBox: document.getElementById("error-box"),
  retryBtn: document.getElementById("retry-btn"),
  resetBtn: document.getElementById("reset-btn"),
  speed: document.getElementById("stat-speed"),
  score: document.getElementById("stat-score"),
  joystick: document.getElementById("joystick"),
  joystickKnob: document.getElementById("joystick-knob"),
  handbrakeBtn: document.getElementById("handbrake-btn"),
};

let currentCityId = "riyadh";
let car = null;
let score = 0;
const input = { steer: 0, throttle: 0, handbrake: false };
const keysDown = new Set();

let renderer, scene, camera;
let cityGroup = null;
let carMesh, carBodyMesh;
let trailPositions;
let trailGeometry;
let trailLine;
const MAX_TRAIL_POINTS = 500;
let trailWriteIndex = 0;
let trailFilled = 0;

function initRenderer() {
  renderer = new THREE.WebGLRenderer({ canvas: els.canvas, antialias: true });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  renderer.setSize(window.innerWidth, window.innerHeight - topbarHeight());
  window.addEventListener("resize", onResize);
}

function topbarHeight() {
  return document.getElementById("topbar").offsetHeight;
}

function onResize() {
  const h = window.innerHeight - topbarHeight();
  renderer.setSize(window.innerWidth, h);
  camera.aspect = window.innerWidth / h;
  camera.updateProjectionMatrix();
}

function initScene() {
  scene = new THREE.Scene();
  scene.background = new THREE.Color(0x0b1220);
  scene.fog = new THREE.Fog(0x0b1220, 200, 900);

  camera = new THREE.PerspectiveCamera(
    62,
    window.innerWidth / (window.innerHeight - topbarHeight()),
    0.1,
    2000
  );

  const ambient = new THREE.AmbientLight(0xffffff, 0.55);
  scene.add(ambient);
  const sun = new THREE.DirectionalLight(0xfff2d9, 1.1);
  sun.position.set(300, 400, 150);
  scene.add(sun);

  const groundGeo = new THREE.PlaneGeometry(4000, 4000);
  const groundMat = new THREE.MeshStandardMaterial({ color: 0x5b6350, roughness: 1 });
  const ground = new THREE.Mesh(groundGeo, groundMat);
  ground.rotation.x = -Math.PI / 2;
  ground.position.y = -0.05;
  scene.add(ground);

  // مسارات آثار الإطارات (دريفت)
  trailPositions = new Float32Array(MAX_TRAIL_POINTS * 3);
  trailGeometry = new THREE.BufferGeometry();
  trailGeometry.setAttribute("position", new THREE.BufferAttribute(trailPositions, 3));
  trailGeometry.setDrawRange(0, 0);
  const trailMat = new THREE.LineBasicMaterial({ color: 0x111111, transparent: true, opacity: 0.6 });
  trailLine = new THREE.LineSegments(trailGeometry, trailMat);
  scene.add(trailLine);
}

function buildCarMesh() {
  const group = new THREE.Group();
  const bodyGeo = new THREE.BoxGeometry(1.8, 0.8, 3.6);
  const bodyMat = new THREE.MeshStandardMaterial({ color: 0xef4444, roughness: 0.4, metalness: 0.2 });
  carBodyMesh = new THREE.Mesh(bodyGeo, bodyMat);
  carBodyMesh.position.y = 0.55;
  group.add(carBodyMesh);

  const cabinGeo = new THREE.BoxGeometry(1.3, 0.5, 1.6);
  const cabinMat = new THREE.MeshStandardMaterial({ color: 0x1e293b, roughness: 0.3 });
  const cabin = new THREE.Mesh(cabinGeo, cabinMat);
  cabin.position.set(0, 1.0, -0.2);
  group.add(cabin);

  const wheelGeo = new THREE.BoxGeometry(0.4, 0.55, 0.7);
  const wheelMat = new THREE.MeshStandardMaterial({ color: 0x111111 });
  const offsets = [
    [-1.0, 0.3, 1.3], [1.0, 0.3, 1.3],
    [-1.0, 0.3, -1.3], [1.0, 0.3, -1.3],
  ];
  for (const [x, y, z] of offsets) {
    const wheel = new THREE.Mesh(wheelGeo, wheelMat);
    wheel.position.set(x, y, z);
    group.add(wheel);
  }

  return group;
}

function clearCityGroup() {
  if (cityGroup) {
    scene.remove(cityGroup);
    cityGroup.traverse((obj) => {
      if (obj.geometry) obj.geometry.dispose();
      if (obj.material) obj.material.dispose();
    });
  }
  cityGroup = new THREE.Group();
  scene.add(cityGroup);
}

function buildCityMeshes(cityData) {
  clearCityGroup();

  const roadMat = new THREE.MeshStandardMaterial({
    color: 0x2b2f36,
    roughness: 0.95,
    side: THREE.DoubleSide,
  });
  for (const road of cityData.roads) {
    const geo = buildRoadRibbon(road.points, road.width);
    if (!geo) continue;
    const bufferGeo = new THREE.BufferGeometry();
    bufferGeo.setAttribute("position", new THREE.BufferAttribute(geo.positions, 3));
    bufferGeo.setIndex(new THREE.BufferAttribute(geo.indices, 1));
    bufferGeo.computeVertexNormals();
    const mesh = new THREE.Mesh(bufferGeo, roadMat);
    mesh.position.y = 0.01;
    cityGroup.add(mesh);
  }

  const buildingMat = new THREE.MeshStandardMaterial({
    color: 0x8a94a6,
    roughness: 0.85,
    side: THREE.DoubleSide,
  });
  for (const b of cityData.buildings) {
    const shape = new THREE.Shape(b.points.map((p) => new THREE.Vector2(p.x, p.z)));
    const geo = new THREE.ExtrudeGeometry(shape, { depth: b.height, bevelEnabled: false });
    geo.rotateX(-Math.PI / 2);
    const mesh = new THREE.Mesh(geo, buildingMat);
    cityGroup.add(mesh);
  }
}

function resetTrail() {
  trailWriteIndex = 0;
  trailFilled = 0;
  trailGeometry.setDrawRange(0, 0);
}

function pushTrailSegment(fromX, fromZ, toX, toZ) {
  const i = trailWriteIndex;
  trailPositions[i * 3 + 0] = fromX;
  trailPositions[i * 3 + 1] = 0.03;
  trailPositions[i * 3 + 2] = fromZ;
  trailPositions[(i + 1) * 3 + 0] = toX;
  trailPositions[(i + 1) * 3 + 1] = 0.03;
  trailPositions[(i + 1) * 3 + 2] = toZ;
  trailWriteIndex = (trailWriteIndex + 2) % MAX_TRAIL_POINTS;
  trailFilled = Math.min(MAX_TRAIL_POINTS, trailFilled + 2);
  trailGeometry.attributes.position.needsUpdate = true;
  trailGeometry.setDrawRange(0, trailFilled);
}

function showLoading(text) {
  els.loading.classList.remove("hidden");
  els.errorBox.classList.add("hidden");
  els.loadingText.textContent = text || "تحميل شوارع ومباني المدينة الحقيقية...";
}

function showError() {
  els.loading.classList.add("hidden");
  els.errorBox.classList.remove("hidden");
}

function hideOverlays() {
  els.loading.classList.add("hidden");
  els.errorBox.classList.add("hidden");
}

async function loadCity(cityId) {
  currentCityId = cityId;
  showLoading();
  document.querySelectorAll(".city-btn").forEach((btn) => {
    btn.classList.toggle("active", btn.dataset.city === cityId);
  });

  const city = CITIES[cityId];
  const bbox = cityBBox(city);

  try {
    const data = await fetchCityData(bbox, city.center.lng, city.center.lat);
    buildCityMeshes(data);
    car = createCar(0, 0, 0);
    score = 0;
    resetTrail();
    hideOverlays();
  } catch (err) {
    console.error(err);
    showError();
  }
}

function updateCamera() {
  if (!car) return;
  const distanceBehind = 9;
  const heightAbove = 4.2;
  const headingRad = (car.headingDeg * Math.PI) / 180;
  const camX = car.x - Math.sin(headingRad) * distanceBehind;
  const camZ = car.z - Math.cos(headingRad) * distanceBehind;
  camera.position.set(camX, heightAbove, camZ);
  camera.lookAt(car.x, 1.2, car.z);
}

let lastTime = performance.now();
function animate(now) {
  requestAnimationFrame(animate);
  let dt = (now - lastTime) / 1000;
  lastTime = now;
  dt = Math.min(dt, 0.05);

  if (car) {
    updateInputFromKeys();
    const prevX = car.x, prevZ = car.z;
    const { driftScoreDelta } = stepCar(car, input, dt);
    score += driftScoreDelta;

    if (carMesh) {
      carMesh.position.set(car.x, 0, car.z);
      carMesh.rotation.y = (car.headingDeg * Math.PI) / 180;
    }

    if (car.isDrifting) {
      pushTrailSegment(prevX, prevZ, car.x, car.z);
    }

    updateCamera();

    els.speed.textContent = Math.round(Math.abs(car.forwardSpeed) * 3.6);
    els.score.textContent = Math.round(score);
  }

  renderer.render(scene, camera);
}

function updateInputFromKeys() {
  let steer = 0;
  let throttle = 0;
  if (keysDown.has("ArrowLeft") || keysDown.has("KeyA")) steer -= 1;
  if (keysDown.has("ArrowRight") || keysDown.has("KeyD")) steer += 1;
  if (keysDown.has("ArrowUp") || keysDown.has("KeyW")) throttle += 1;
  if (keysDown.has("ArrowDown") || keysDown.has("KeyS")) throttle -= 1;

  // عصا التحكم اللمسية (إن استُخدمت) لها الأولوية إن كانت نشطة
  if (input._joystickActive) {
    steer = input._joystickSteer;
    throttle = input._joystickThrottle;
  } else {
    input.steer = steer;
    input.throttle = throttle;
  }
  input.handbrake = keysDown.has("Space") || input._handbrakeHeld;
}

function initInput() {
  window.addEventListener("keydown", (e) => keysDown.add(e.code));
  window.addEventListener("keyup", (e) => keysDown.delete(e.code));

  const stick = els.joystick;
  const knob = els.joystickKnob;
  const radius = 55;

  function update(clientX, clientY) {
    const rect = stick.getBoundingClientRect();
    const center = { x: rect.left + rect.width / 2, y: rect.top + rect.height / 2 };
    let dx = clientX - center.x;
    let dy = clientY - center.y;
    const dist = Math.hypot(dx, dy);
    if (dist > radius) {
      dx = (dx / dist) * radius;
      dy = (dy / dist) * radius;
    }
    knob.style.transform = `translate(${dx - 24}px, ${dy - 24}px)`;
    input._joystickActive = true;
    input._joystickSteer = dx / radius;
    input._joystickThrottle = -dy / radius;
  }

  function reset() {
    knob.style.transform = "translate(-50%, -50%)";
    input._joystickActive = false;
    input._joystickSteer = 0;
    input._joystickThrottle = 0;
  }

  stick.addEventListener("pointerdown", (e) => {
    stick.setPointerCapture(e.pointerId);
    update(e.clientX, e.clientY);
  });
  stick.addEventListener("pointermove", (e) => {
    if (e.buttons || e.pointerType === "touch") update(e.clientX, e.clientY);
  });
  stick.addEventListener("pointerup", reset);
  stick.addEventListener("pointercancel", reset);

  const hb = els.handbrakeBtn;
  const setHandbrake = (v) => {
    input._handbrakeHeld = v;
    hb.classList.toggle("active", v);
  };
  hb.addEventListener("pointerdown", () => setHandbrake(true));
  hb.addEventListener("pointerup", () => setHandbrake(false));
  hb.addEventListener("pointercancel", () => setHandbrake(false));
  hb.addEventListener("pointerleave", () => setHandbrake(false));

  document.querySelectorAll(".city-btn").forEach((btn) => {
    btn.addEventListener("click", () => loadCity(btn.dataset.city));
  });

  els.resetBtn.addEventListener("click", () => {
    if (!car) return;
    car.x = 0;
    car.z = 0;
    car.headingDeg = 0;
    car.forwardSpeed = 0;
    car.lateralSpeed = 0;
    resetTrail();
  });

  els.retryBtn.addEventListener("click", () => loadCity(currentCityId));
}

function main() {
  initRenderer();
  initScene();
  carMesh = buildCarMesh();
  scene.add(carMesh);
  initInput();
  loadCity(currentCityId);
  requestAnimationFrame(animate);
}

main();
