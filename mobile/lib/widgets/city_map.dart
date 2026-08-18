import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/building.dart';
import '../models/city.dart';

/// خريطة حقيقية (OpenStreetMap) قابلة للبناء عليها: تعرض المباني الموضوعة
/// وتستدعي [onTap] عند الضغط على أي موقع (لبناء المبنى المختار هناك).
/// تقبل [mapController] للتحكم البرمجي بالكاميرا (مثل متابعة سيارة أثناء القيادة)
/// و [extraMarkers] لعلامات إضافية غير المباني (مثل السيارة نفسها).
class CityMap extends StatelessWidget {
  final CityConfig city;
  final List<PlacedBuilding> buildings;
  final bool buildModeActive;
  final void Function(LatLng) onTap;
  final MapController? mapController;
  final List<Marker> extraMarkers;
  final double? initialZoomOverride;
  final bool interactive;

  const CityMap({
    super.key,
    required this.city,
    required this.buildings,
    required this.buildModeActive,
    required this.onTap,
    this.mapController,
    this.extraMarkers = const [],
    this.initialZoomOverride,
    this.interactive = true,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: city.center,
        initialZoom: initialZoomOverride ?? city.zoom,
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
        onTap: (_, latLng) {
          if (buildModeActive) onTap(latLng);
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.la.citybuilder',
        ),
        MarkerLayer(
          markers: [
            for (final b in buildings)
              Marker(
                point: LatLng(b.lat, b.lng),
                width: 32,
                height: 32,
                child: Text(
                  kBuildingTypes[b.type]?.icon ?? '❓',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ...extraMarkers,
          ],
        ),
      ],
    );
  }
}
