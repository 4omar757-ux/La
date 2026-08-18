// إدارة حالة اللعبة (الموارد + المباني) مع الحفظ في localStorage
const STORAGE_PREFIX = "citygame3d_state_";

function defaultCityState() {
  return {
    gold: 1000,
    population: 0,
    buildings: [], // { type, lng, lat }
  };
}

function loadCityState(cityId) {
  try {
    const raw = localStorage.getItem(STORAGE_PREFIX + cityId);
    if (!raw) return defaultCityState();
    const parsed = JSON.parse(raw);
    return { ...defaultCityState(), ...parsed };
  } catch (e) {
    console.warn("تعذر تحميل حفظ المدينة، بدء حالة جديدة", e);
    return defaultCityState();
  }
}

function saveCityState(cityId, state) {
  localStorage.setItem(STORAGE_PREFIX + cityId, JSON.stringify(state));
}

function computeDerivedStats(state) {
  let capacity = 0;
  let incomePerSec = 0;
  let happiness = 50;

  for (const b of state.buildings) {
    const def = BUILDING_TYPES[b.type];
    if (!def) continue;
    capacity += def.populationCapacity;
    incomePerSec += def.incomePerSec;
    happiness += def.happinessDelta;
  }

  happiness = Math.max(0, Math.min(100, happiness));
  return { capacity, incomePerSec, happiness };
}

function tickState(state, seconds = 1) {
  const derived = computeDerivedStats(state);
  const incomeFactor = 0.5 + derived.happiness / 200;
  state.gold += derived.incomePerSec * incomeFactor * seconds;

  if (state.population < derived.capacity) {
    const growth =
      0.05 * (derived.happiness / 100) * (derived.capacity - state.population) * seconds;
    state.population = Math.min(derived.capacity, state.population + growth);
  }

  return derived;
}

function placeBuilding(state, buildingType, lng, lat) {
  const def = BUILDING_TYPES[buildingType];
  if (!def || state.gold < def.cost) return false;
  state.gold -= def.cost;
  state.buildings.push({ type: buildingType, lng, lat });
  return true;
}
