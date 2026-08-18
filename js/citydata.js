// جلب شوارع ومباني حقيقية من OpenStreetMap (عبر Overpass API) وتحويلها
// لهندسة قابلة للعرض ثلاثي الأبعاد فوق نظام إحداثيات محلي بالأمتار.
const METERS_PER_DEG_LAT = 111320;

const DRIVABLE_HIGHWAYS = new Set([
  "motorway", "trunk", "primary", "secondary", "tertiary", "unclassified",
  "residential", "living_street", "service",
  "motorway_link", "trunk_link", "primary_link", "secondary_link", "tertiary_link",
]);

const ROAD_WIDTH_BY_HIGHWAY = {
  motorway: 15, trunk: 13, primary: 11, secondary: 9, tertiary: 7.5,
  unclassified: 6, residential: 6, living_street: 5, service: 4,
  motorway_link: 8, trunk_link: 8, primary_link: 7, secondary_link: 6, tertiary_link: 6,
};

function projectToLocal(lng, lat, originLng, originLat) {
  const metersPerDegLng = METERS_PER_DEG_LAT * Math.cos((originLat * Math.PI) / 180);
  return {
    x: (lng - originLng) * metersPerDegLng,
    z: -(lat - originLat) * METERS_PER_DEG_LAT,
  };
}

function buildOverpassQuery(south, west, north, east) {
  return `[out:json][timeout:25];(way["highway"](${south},${west},${north},${east});way["building"](${south},${west},${north},${east}););out geom;`;
}

function buildingHeightFromTags(tags) {
  if (!tags) return 9;
  if (tags.height) {
    const h = parseFloat(tags.height);
    if (!isNaN(h) && h > 0) return h;
  }
  if (tags["building:levels"]) {
    const levels = parseFloat(tags["building:levels"]);
    if (!isNaN(levels) && levels > 0) return levels * 3;
  }
  return 9;
}

// يحوّل استجابة Overpass الخام (elements[]) لقوائم شوارع ومبانٍ بإحداثيات محلية
function parseOverpassElements(elements, originLng, originLat) {
  const roads = [];
  const buildings = [];

  for (const el of elements) {
    if (el.type !== "way" || !el.geometry || el.geometry.length < 2) continue;
    const points = el.geometry.map((g) => projectToLocal(g.lon, g.lat, originLng, originLat));

    if (el.tags && el.tags.highway && DRIVABLE_HIGHWAYS.has(el.tags.highway)) {
      roads.push({
        points,
        width: ROAD_WIDTH_BY_HIGHWAY[el.tags.highway] || 5,
      });
    } else if (el.tags && el.tags.building) {
      // تجاهل المباني غير المغلقة (بولي لاين مفتوح) لتفادي هندسة غير صالحة
      const first = points[0];
      const last = points[points.length - 1];
      const closed =
        Math.abs(first.x - last.x) < 0.5 && Math.abs(first.z - last.z) < 0.5 && points.length >= 4;
      if (closed) {
        buildings.push({ points, height: buildingHeightFromTags(el.tags) });
      }
    }
  }

  return { roads, buildings };
}

async function fetchCityData(bbox, originLng, originLat) {
  const query = buildOverpassQuery(bbox.south, bbox.west, bbox.north, bbox.east);
  const url = "https://overpass-api.de/api/interpreter";
  const res = await fetch(url, { method: "POST", body: "data=" + encodeURIComponent(query) });
  if (!res.ok) throw new Error("تعذر جلب بيانات الخريطة من Overpass: " + res.status);
  const json = await res.json();
  return parseOverpassElements(json.elements, originLng, originLat);
}
