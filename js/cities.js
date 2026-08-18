// المدن المتاحة: مركز حقيقي + نصف قطر منطقة اللعب (متر) حول المركز
const CITY_METERS_PER_DEG_LAT = 111320;

const CITIES = {
  riyadh: {
    id: "riyadh",
    name: "الرياض",
    center: { lng: 46.6753, lat: 24.7136 },
    radiusMeters: 650,
  },
  buraydah: {
    id: "buraydah",
    name: "بريدة",
    center: { lng: 43.975, lat: 26.326 },
    radiusMeters: 650,
  },
};

function cityBBox(city) {
  const dLat = city.radiusMeters / CITY_METERS_PER_DEG_LAT;
  const dLng =
    city.radiusMeters / (CITY_METERS_PER_DEG_LAT * Math.cos((city.center.lat * Math.PI) / 180));
  return {
    south: city.center.lat - dLat,
    north: city.center.lat + dLat,
    west: city.center.lng - dLng,
    east: city.center.lng + dLng,
  };
}
