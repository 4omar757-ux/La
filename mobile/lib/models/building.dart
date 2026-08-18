/// تعريف نوع مبنى وتأثيره على اقتصاد المدينة
class BuildingType {
  final String id;
  final String name;
  final String icon; // إيموجي يُعرض على الخريطة وفي القائمة
  final int cost;
  final int populationCapacity;
  final double incomePerSec;
  final double happinessDelta;

  const BuildingType({
    required this.id,
    required this.name,
    required this.icon,
    required this.cost,
    required this.populationCapacity,
    required this.incomePerSec,
    required this.happinessDelta,
  });
}

const Map<String, BuildingType> kBuildingTypes = {
  'house': BuildingType(
    id: 'house',
    name: 'منزل',
    icon: '🏠',
    cost: 50,
    populationCapacity: 4,
    incomePerSec: 0,
    happinessDelta: 0,
  ),
  'market': BuildingType(
    id: 'market',
    name: 'سوق',
    icon: '🏪',
    cost: 150,
    populationCapacity: 0,
    incomePerSec: 3,
    happinessDelta: 1,
  ),
  'mosque': BuildingType(
    id: 'mosque',
    name: 'مسجد',
    icon: '🕌',
    cost: 100,
    populationCapacity: 0,
    incomePerSec: 0,
    happinessDelta: 4,
  ),
  'factory': BuildingType(
    id: 'factory',
    name: 'مصنع',
    icon: '🏭',
    cost: 300,
    populationCapacity: 0,
    incomePerSec: 9,
    happinessDelta: -3,
  ),
  'park': BuildingType(
    id: 'park',
    name: 'حديقة',
    icon: '🌳',
    cost: 80,
    populationCapacity: 0,
    incomePerSec: 0,
    happinessDelta: 3,
  ),
};

/// مبنى تم وضعه فعليًا على الخريطة
class PlacedBuilding {
  final String type;
  final double lat;
  final double lng;

  const PlacedBuilding({required this.type, required this.lat, required this.lng});

  Map<String, dynamic> toJson() => {'type': type, 'lat': lat, 'lng': lng};

  factory PlacedBuilding.fromJson(Map<String, dynamic> json) => PlacedBuilding(
        type: json['type'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
      );
}
