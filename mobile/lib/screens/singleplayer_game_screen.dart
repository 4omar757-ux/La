import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/city.dart';
import '../models/player_city_state.dart';
import '../services/local_save_service.dart';
import '../widgets/building_palette.dart';
import '../widgets/city_map.dart';
import '../widgets/stats_bar.dart';

class SinglePlayerGameScreen extends StatefulWidget {
  final String cityId;

  const SinglePlayerGameScreen({super.key, required this.cityId});

  @override
  State<SinglePlayerGameScreen> createState() => _SinglePlayerGameScreenState();
}

class _SinglePlayerGameScreenState extends State<SinglePlayerGameScreen> {
  PlayerCityState _state = PlayerCityState();
  String? _selectedType;
  Timer? _timer;
  bool _loaded = false;

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
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
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
    _timer?.cancel();
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

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(city.name),
        actions: [
          IconButton(onPressed: _resetCity, icon: const Icon(Icons.refresh)),
        ],
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
            child: CityMap(
              city: city,
              buildings: _state.buildings,
              buildModeActive: _selectedType != null,
              onTap: _onMapTap,
            ),
          ),
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
      ),
    );
  }
}
