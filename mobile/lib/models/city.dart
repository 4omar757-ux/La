import 'package:latlong2/latlong.dart';

/// إحداثيات المدن الحقيقية المتاحة باللعبة
class CityConfig {
  final String id;
  final String name;
  final LatLng center;
  final double zoom;

  const CityConfig({
    required this.id,
    required this.name,
    required this.center,
    required this.zoom,
  });
}

const Map<String, CityConfig> kCities = {
  'riyadh': CityConfig(
    id: 'riyadh',
    name: 'الرياض',
    center: LatLng(24.7136, 46.6753),
    zoom: 12,
  ),
  'buraydah': CityConfig(
    id: 'buraydah',
    name: 'بريدة',
    center: LatLng(26.3260, 43.9750),
    zoom: 13,
  ),
};
