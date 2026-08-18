import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/car_state.dart';
import '../models/city.dart';
import '../models/player_city_state.dart';
import '../services/driving_engine.dart';
import '../services/local_save_service.dart';
import '../widgets/building_palette.dart';
import '../widgets/city_map.dart';
import '../widgets/joystick.dart';
import '../widgets/stats_bar.dart';

enum _GameMode { build, drive }

class SinglePlayerGameScreen extends StatefulWidget {
  final String cityId;

  const SinglePlayerGameScreen({super.key, required this.cityId});

  @override
  State<SinglePlayerGameScreen> createState() => _SinglePlayerGameScreenState();
}

class _SinglePlayerGameScreenState extends State<SinglePlayerGameScreen> {
  PlayerCityState _state = PlayerCityState();
  String? _selectedType;
  Timer? _economyTimer;
  bool _loaded = false;

  _GameMode _mode = _GameMode.build;
  final MapController _mapController = MapController();
  CarState? _car;
  Timer? _driveTimer;
  Offset _joystickInput = Offset.zero;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = await LocalSaveService.load(widget.cityId);
    setState(() {
      _state = loaded;
      _loaded = true;
    });
    _economyTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tickEconomy());
  }

  void _tickEconomy() {
    setState(() => _state.tick(1));
    LocalSaveService.save(widget.cityId, _state);
  }

  void _onMapTap(LatLng point) {
    if (_selectedType == null) return;
    final placed = _state.placeBuilding(_selectedType!, point.latitude, point.longitude);
    if (placed) {
      setState(() {});
      LocalSaveService.save(widget.cityId, _state);
    }
  }

  void _enterDriveMode(CityConfig city) {
    _car ??= CarState(lat: city.center.latitude, lng: city.center.longitude);
    setState(() {
      _mode = _GameMode.drive;
      _selectedType = null;
    });
    _driveTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      DrivingEngine.step(_car!, steer: _joystickInput.dx, throttle: _joystickInput.dy, dt: 0.05);
      _mapController.move(LatLng(_car!.lat, _car!.lng), 17);
      setState(() {});
    });
  }

  void _exitDriveMode(CityConfig city) {
    _driveTimer?.cancel();
    _driveTimer = null;
    setState(() {
      _mode = _GameMode.build;
      _joystickInput = Offset.zero;
    });
    _mapController.move(city.center, city.zoom);
  }

  Future<void> _resetCity() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('إعادة ضبط المدينة', style: TextStyle(color: Colors.white)),
        content: Text(
          'تصفير كل مباني مدينة ${kCities[widget.cityId]!.name}؟',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('تصفير')),
        ],
      ),
    );
    if (confirm == true) {
      await LocalSaveService.reset(widget.cityId);
      setState(() => _state = PlayerCityState());
    }
  }

  @override
  void dispose() {
    _economyTimer?.cancel();
    _driveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final city = kCities[widget.cityId]!;
    final derived = _state.computeDerivedStats();

    if (!_loaded) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final driving = _mode == _GameMode.drive;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(city.name),
        actions: [
          if (!driving) IconButton(onPressed: _resetCity, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: driving ? const Color(0xFFB91C1C) : const Color(0xFF16A34A),
        onPressed: () => driving ? _exitDriveMode(city) : _enterDriveMode(city),
        child: Icon(driving ? Icons.construction : Icons.directions_car),
      ),
      body: Column(
        children: [
          StatsBar(
            gold: _state.gold,
            population: _state.population,
            capacity: derived.capacity,
            happiness: derived.happiness,
          ),
          Expanded(
            child: Stack(
              children: [
                CityMap(
                  city: city,
                  buildings: _state.buildings,
                  buildModeActive: _selectedType != null,
                  onTap: _onMapTap,
                  mapController: _mapController,
                  interactive: !driving,
                  extraMarkers: driving && _car != null
                      ? [
                          Marker(
                            point: LatLng(_car!.lat, _car!.lng),
                            width: 40,
                            height: 40,
                            child: Transform.rotate(
                              angle: _car!.headingDeg * math.pi / 180,
                              child: const Text('🚗', style: TextStyle(fontSize: 28)),
                            ),
                          ),
                        ]
                      : const [],
                ),
                if (driving) ...[
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_car!.speedKmh.round()} كم/س',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Joystick(onChanged: (v) => _joystickInput = v),
                  ),
                ],
              ],
            ),
          ),
          if (!driving) ...[
            if (_selectedType != null)
              Container(
                width: double.infinity,
                color: const Color(0xFF1E293B),
                padding: const EdgeInsets.all(8),
                child: const Text(
                  'اضغط على الخريطة لبناء هذا المبنى',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            BuildingPalette(
              selectedType: _selectedType,
              gold: _state.gold,
              onSelect: (type) {
                setState(() => _selectedType = _selectedType == type ? null : type);
              },
            ),
          ],
        ],
      ),
    );
  }
}
