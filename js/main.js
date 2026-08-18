// ربط الخريطة ثلاثية الأبعاد (MapLibre GL) بمنطق اللعبة والتحكم بالسيارة
const MAP_STYLE_URL = "https://tiles.openfreemap.org/styles/liberty";

let map;
let currentCityId = localStorage.getItem("citygame3d_current_city") || "riyadh";
let state = loadCityState(currentCityId);
let selectedBuildingType = null;

let mode = "build"; // "build" | "drive"
let car = null;
let carMarker = null;
let driveTimer = null;
let joystickInput = { x: 0, y: 0 };

const els = {
  gold: document.getElementById("stat-gold"),
  population: document.getElementById("stat-population"),
  capacity: document.getElementById("stat-capacity"),
  happiness: document.getElementById("stat-happiness"),
  palette: document.getElementById("building-palette"),
  cancelBtn: document.getElementById("cancel-build"),
  resetBtn: document.getElementById("reset-city"),
  sidebar: document.getElementById("sidebar"),
  modeToggle: document.getElementById("mode-toggle"),
  driveSpeed: document.getElementById("drive-speed"),
  speedValue: document.getElementById("speed-value"),
  joystick: document.getElementById("joystick"),
  joystickKnob: document.getElementById("joystick-knob"),
};

function initMap() {
  const city = CITIES[currentCityId];
  map = new maplibregl.Map({
    container: "map",
    style: MAP_STYLE_URL,
    center: city.center,
    zoom: city.zoom,
    pitch: city.pitch,
    bearing: city.bearing,
    antialias: true,
  });
  map.addControl(new maplibregl.NavigationControl({ visualizePitch: true }), "top-left");

  map.on("load", () => {
    map.addSource("player-buildings", { type: "geojson", data: buildingsToGeoJSON(state.buildings) });
    map.addLayer({
      id: "player-buildings-3d",
      type: "fill-extrusion",
      source: "player-buildings",
      paint: {
        "fill-extrusion-color": ["get", "color"],
        "fill-extrusion-height": ["get", "height"],
        "fill-extrusion-base": 0,
        "fill-extrusion-opacity": 0.92,
      },
    });

    map.addSource("player-building-icons", {
      type: "geojson",
      data: buildingsToPointsGeoJSON(state.buildings),
    });
    map.addLayer({
      id: "player-building-icons-layer",
      type: "symbol",
      source: "player-building-icons",
      layout: {
        "text-field": ["get", "icon"],
        "text-size": 20,
        "text-allow-overlap": true,
        "text-anchor": "bottom",
      },
    });
  });

  map.on("click", (e) => {
    if (mode !== "build" || !selectedBuildingType) return;
    const { lng, lat } = e.lngLat;
    if (placeBuilding(state, selectedBuildingType, lng, lat)) {
      refreshBuildingLayers();
      saveCityState(currentCityId, state);
      renderPalette();
    }
  });
}

function refreshBuildingLayers() {
  if (!map.getSource("player-buildings")) return;
  map.getSource("player-buildings").setData(buildingsToGeoJSON(state.buildings));
  map.getSource("player-building-icons").setData(buildingsToPointsGeoJSON(state.buildings));
}

function renderPalette() {
  els.palette.innerHTML = "";
  for (const def of Object.values(BUILDING_TYPES)) {
    const affordable = state.gold >= def.cost;
    const card = document.createElement("div");
    card.className =
      "building-card" +
      (def.id === selectedBuildingType ? " selected" : "") +
      (affordable ? "" : " disabled");
    card.innerHTML = `
      <span class="icon">${def.icon}</span>
      <span class="info">
        <div class="name">${def.name}</div>
        <div class="cost">💰 ${def.cost}</div>
      </span>
    `;
    card.addEventListener("click", () => {
      if (!affordable) return;
      selectedBuildingType = def.id === selectedBuildingType ? null : def.id;
      els.cancelBtn.classList.toggle("hidden", !selectedBuildingType);
      renderPalette();
    });
    els.palette.appendChild(card);
  }
}

function renderStats() {
  const derived = computeDerivedStats(state);
  els.gold.textContent = Math.floor(state.gold);
  els.population.textContent = Math.floor(state.population);
  els.capacity.textContent = derived.capacity;
  els.happiness.textContent = derived.happiness;
}

function switchCity(cityId) {
  if (mode === "drive") exitDriveMode();

  currentCityId = cityId;
  localStorage.setItem("citygame3d_current_city", cityId);
  state = loadCityState(cityId);
  selectedBuildingType = null;
  els.cancelBtn.classList.add("hidden");

  const city = CITIES[cityId];
  map.flyTo({ center: city.center, zoom: city.zoom, pitch: city.pitch, bearing: city.bearing, duration: 1600 });
  refreshBuildingLayers();
  renderPalette();
  renderStats();

  document.querySelectorAll(".city-btn").forEach((btn) => {
    btn.classList.toggle("active", btn.dataset.city === cityId);
  });
}

function initUI() {
  document.querySelectorAll(".city-btn").forEach((btn) => {
    btn.addEventListener("click", () => switchCity(btn.dataset.city));
  });

  els.cancelBtn.addEventListener("click", () => {
    selectedBuildingType = null;
    els.cancelBtn.classList.add("hidden");
    renderPalette();
  });

  els.resetBtn.addEventListener("click", () => {
    if (!confirm(`تصفير كل مباني مدينة ${CITIES[currentCityId].name}؟`)) return;
    state = defaultCityState();
    saveCityState(currentCityId, state);
    refreshBuildingLayers();
    renderPalette();
    renderStats();
  });

  els.modeToggle.addEventListener("click", () => {
    if (mode === "build") enterDriveMode();
    else exitDriveMode();
  });

  initJoystick();
}

function startGameLoop() {
  setInterval(() => {
    tickState(state, 1);
    saveCityState(currentCityId, state);
    renderStats();
    renderPalette();
  }, 1000);
}

// ---------------- وضع القيادة ثلاثي الأبعاد ----------------

function enterDriveMode() {
  mode = "drive";
  selectedBuildingType = null;
  els.cancelBtn.classList.add("hidden");
  els.sidebar.style.display = "none";
  els.driveSpeed.classList.remove("hidden");
  els.joystick.classList.remove("hidden");
  els.modeToggle.textContent = "🏗️";
  els.modeToggle.classList.add("driving");

  const city = CITIES[currentCityId];
  if (!car) car = createCar(city.center[0], city.center[1]);

  if (!carMarker) {
    const el = document.createElement("div");
    el.style.fontSize = "30px";
    el.textContent = "🚗";
    carMarker = new maplibregl.Marker({ element: el, rotationAlignment: "map" })
      .setLngLat([car.lng, car.lat])
      .addTo(map);
  }

  driveTimer = setInterval(() => {
    stepCar(car, { steer: joystickInput.x, throttle: joystickInput.y, dt: 0.05 });
    carMarker.setLngLat([car.lng, car.lat]);
    carMarker.setRotation(car.headingDeg);
    updateChaseCamera();
    els.speedValue.textContent = Math.round(Math.abs(car.speed) * 3.6);
  }, 50);
}

function exitDriveMode() {
  mode = "build";
  clearInterval(driveTimer);
  driveTimer = null;
  joystickInput = { x: 0, y: 0 };
  els.joystickKnob.style.transform = "translate(-50%, -50%)";

  els.sidebar.style.display = "";
  els.driveSpeed.classList.add("hidden");
  els.joystick.classList.add("hidden");
  els.modeToggle.textContent = "🚗";
  els.modeToggle.classList.remove("driving");

  const city = CITIES[currentCityId];
  map.flyTo({ center: city.center, zoom: city.zoom, pitch: city.pitch, bearing: city.bearing, duration: 1200 });
}

function updateChaseCamera() {
  const distanceBehind = 45; // متر خلف السيارة
  const heightAbove = 28; // متر فوق الأرض
  const headingRad = (car.headingDeg * Math.PI) / 180;
  const metersPerDegLng = METERS_PER_DEG_LAT * Math.cos((car.lat * Math.PI) / 180);

  const camLat = car.lat - (distanceBehind * Math.cos(headingRad)) / METERS_PER_DEG_LAT;
  const camLng = car.lng - (distanceBehind * Math.sin(headingRad)) / metersPerDegLng;

  const camera = map.getFreeCameraOptions();
  camera.position = maplibregl.MercatorCoordinate.fromLngLat([camLng, camLat], heightAbove);
  camera.lookAtPoint([car.lng, car.lat], [0, 0, 3]);
  map.setFreeCameraOptions(camera);
}

function initJoystick() {
  const stick = els.joystick;
  const knob = els.joystickKnob;
  const radius = 50;
  let active = false;

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
    knob.style.transform = `translate(${dx - 22}px, ${dy - 22}px)`;
    joystickInput = { x: dx / radius, y: -dy / radius };
  }

  function reset() {
    knob.style.transform = "translate(-50%, -50%)";
    joystickInput = { x: 0, y: 0 };
  }

  stick.addEventListener("pointerdown", (e) => {
    active = true;
    stick.setPointerCapture(e.pointerId);
    update(e.clientX, e.clientY);
  });
  stick.addEventListener("pointermove", (e) => {
    if (active) update(e.clientX, e.clientY);
  });
  stick.addEventListener("pointerup", () => {
    active = false;
    reset();
  });
  stick.addEventListener("pointercancel", () => {
    active = false;
    reset();
  });
}

function main() {
  initMap();
  initUI();
  renderPalette();
  renderStats();
  startGameLoop();
}

main();
