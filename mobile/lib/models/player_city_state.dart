import 'building.dart';

/// إحصاءات مشتقة من قائمة المباني (سعة السكان، الدخل، السعادة)
class DerivedStats {
  final int capacity;
  final double incomePerSec;
  final double happiness;

  const DerivedStats({
    required this.capacity,
    required this.incomePerSec,
    required this.happiness,
  });
}

/// حالة مدينة لاعب واحد: الذهب، السكان، والمباني الموضوعة
class PlayerCityState {
  double gold;
  double population;
  final List<PlacedBuilding> buildings;

  PlayerCityState({
    this.gold = 1000,
    this.population = 0,
    List<PlacedBuilding>? buildings,
  }) : buildings = buildings ?? [];

  DerivedStats computeDerivedStats() {
    int capacity = 0;
    double incomePerSec = 0;
    double happiness = 50; // نقطة بداية محايدة

    for (final b in buildings) {
      final def = kBuildingTypes[b.type];
      if (def == null) continue;
      capacity += def.populationCapacity;
      incomePerSec += def.incomePerSec;
      happiness += def.happinessDelta;
    }

    happiness = happiness.clamp(0, 100);
    return DerivedStats(capacity: capacity, incomePerSec: incomePerSec, happiness: happiness);
  }

  /// خطوة زمن واحدة (تُستدعى كل ثانية تقريبًا)
  DerivedStats tick(double seconds) {
    final derived = computeDerivedStats();
    final incomeFactor = 0.5 + derived.happiness / 200; // من 0.5 إلى 1.0
    gold += derived.incomePerSec * incomeFactor * seconds;

    if (population < derived.capacity) {
      final growth =
          0.05 * (derived.happiness / 100) * (derived.capacity - population) * seconds;
      population = (population + growth).clamp(0, derived.capacity.toDouble());
    }

    return derived;
  }

  bool canAfford(String buildingType) {
    final def = kBuildingTypes[buildingType];
    return def != null && gold >= def.cost;
  }

  bool placeBuilding(String buildingType, double lat, double lng) {
    final def = kBuildingTypes[buildingType];
    if (def == null || gold < def.cost) return false;
    gold -= def.cost;
    buildings.add(PlacedBuilding(type: buildingType, lat: lat, lng: lng));
    return true;
  }

  /// نقاط تنافسية مركّبة تُستخدم في لوحة صدارة المتعدد لاعبين
  double get score => gold + population * 20;

  Map<String, dynamic> toJson() => {
        'gold': gold,
        'population': population,
        'buildings': buildings.map((b) => b.toJson()).toList(),
      };

  factory PlayerCityState.fromJson(Map<String, dynamic> json) => PlayerCityState(
        gold: (json['gold'] as num?)?.toDouble() ?? 1000,
        population: (json['population'] as num?)?.toDouble() ?? 0,
        buildings: (json['buildings'] as List<dynamic>? ?? [])
            .map((e) => PlacedBuilding.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
