// ربط الخريطة (Leaflet) بواجهة اللعبة ومنطق الحالة
let map;
let currentCityId = localStorage.getItem("citygame_current_city") || "riyadh";
let state = loadCityState(currentCityId);
let selectedBuildingType = null;
let markersLayer;

const els = {
  gold: document.getElementById("stat-gold"),
  population: document.getElementById("stat-population"),
  capacity: document.getElementById("stat-capacity"),
  happiness: document.getElementById("stat-happiness"),
  palette: document.getElementById("building-palette"),
  cancelBtn: document.getElementById("cancel-build"),
  resetBtn: document.getElementById("reset-city"),
};

function initMap() {
  map = L.map("map");
  L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
    maxZoom: 19,
    attribution: "&copy; OpenStreetMap contributors",
  }).addTo(map);
  markersLayer = L.layerGroup().addTo(map);

  map.on("click", (e) => {
    if (!selectedBuildingType) return;
    const { lat, lng } = e.latlng;
    if (placeBuilding(state, selectedBuildingType, lat, lng)) {
      addBuildingMarker(state.buildings[state.buildings.length - 1]);
      saveCityState(currentCityId, state);
      renderPalette();
    }
  });
}

function addBuildingMarker(building) {
  const def = BUILDING_TYPES[building.type];
  const icon = L.divIcon({
    className: "city-marker-icon",
    html: `<span class="marker-emoji">${def.icon}</span>`,
    iconSize: [26, 26],
    iconAnchor: [13, 13],
  });
  L.marker([building.lat, building.lng], { icon, title: def.name }).addTo(markersLayer);
}

function renderBuildingsOnMap() {
  markersLayer.clearLayers();
  for (const b of state.buildings) addBuildingMarker(b);
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
  currentCityId = cityId;
  localStorage.setItem("citygame_current_city", cityId);
  state = loadCityState(cityId);
  selectedBuildingType = null;
  els.cancelBtn.classList.add("hidden");

  const city = CITIES[cityId];
  map.setView(city.center, city.zoom);
  renderBuildingsOnMap();
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
    renderBuildingsOnMap();
    renderPalette();
    renderStats();
  });
}

function startGameLoop() {
  setInterval(() => {
    tickState(state, 1);
    saveCityState(currentCityId, state);
    renderStats();
    renderPalette(); // لتحديث حالة "غير متاح" حسب الذهب
  }, 1000);
}

function main() {
  initMap();
  initUI();
  switchCity(currentCityId);
  startGameLoop();
}

main();
