// أدوات جغرافية: توليد مضلع مربّع (بصمة مبنى) بالأمتار حول نقطة إحداثيات
function squareFootprint(lng, lat, sideMeters) {
  const half = sideMeters / 2;
  const metersPerDegLng = METERS_PER_DEG_LAT * Math.cos((lat * Math.PI) / 180);
  const dLat = half / METERS_PER_DEG_LAT;
  const dLng = half / metersPerDegLng;

  return [
    [lng - dLng, lat - dLat],
    [lng + dLng, lat - dLat],
    [lng + dLng, lat + dLat],
    [lng - dLng, lat + dLat],
    [lng - dLng, lat - dLat],
  ];
}

// يحوّل قائمة المباني المبنية إلى GeoJSON لطبقة fill-extrusion (مجسّمة)
function buildingsToGeoJSON(buildings) {
  return {
    type: "FeatureCollection",
    features: buildings.map((b) => {
      const def = BUILDING_TYPES[b.type];
      return {
        type: "Feature",
        properties: {
          buildingType: b.type,
          height: def.heightMeters,
          color: def.color,
        },
        geometry: {
          type: "Polygon",
          coordinates: [squareFootprint(b.lng, b.lat, def.footprintMeters)],
        },
      };
    }),
  };
}

// يحوّل نفس القائمة لنقاط (لعرض إيموجي كل مبنى فوقه)
function buildingsToPointsGeoJSON(buildings) {
  return {
    type: "FeatureCollection",
    features: buildings.map((b) => ({
      type: "Feature",
      properties: { icon: BUILDING_TYPES[b.type]?.icon ?? "❓" },
      geometry: { type: "Point", coordinates: [b.lng, b.lat] },
    })),
  };
}
