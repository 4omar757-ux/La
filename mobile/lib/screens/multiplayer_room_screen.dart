import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/city.dart';
import '../models/player_city_state.dart';
import '../services/multiplayer_service.dart';
import '../widgets/building_palette.dart';
import '../widgets/city_map.dart';
import '../widgets/stats_bar.dart';

class MultiplayerRoomScreen extends StatefulWidget {
  final String roomCode;
  final String playerId;

  const MultiplayerRoomScreen({super.key, required this.roomCode, required this.playerId});

  @override
  State<MultiplayerRoomScreen> createState() => _MultiplayerRoomScreenState();
}

class _MultiplayerRoomScreenState extends State<MultiplayerRoomScreen> {
  final _service = MultiplayerService();
  final PlayerCityState _state = PlayerCityState();
  String? _selectedType;
  Timer? _tickTimer;
  int _tickCount = 0;
  bool _finishRequested = false;
  bool _leaderboardExpanded = false;

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  void _ensureGameLoopRunning() {
    _tickTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _state.tick(1));
      _tickCount++;
      if (_tickCount % 2 == 0) {
        _service.pushMyStats(roomCode: widget.roomCode, playerId: widget.playerId, state: _state);
      }
    });
  }

  void _onMapTap(LatLng point) {
    if (_selectedType == null) return;
    if (_state.placeBuilding(_selectedType!, point.latitude, point.longitude)) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: StreamBuilder<RoomInfo>(
          stream: _service.watchRoom(widget.roomCode),
          builder: (context, roomSnap) {
            if (!roomSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final room = roomSnap.data!;
            final city = kCities[room.cityId]!;

            if (room.status == 'waiting') {
              return _buildWaitingRoom(room);
            }
            if (room.status == 'playing') {
              _ensureGameLoopRunning();
              return _buildPlayingRoom(room, city);
            }
            _tickTimer?.cancel();
            return _buildFinishedRoom(room);
          },
        ),
      ),
    );
  }

  Widget _buildWaitingRoom(RoomInfo room) {
    final isHost = room.hostPlayerId == widget.playerId;
    return StreamBuilder<List<PlayerScore>>(
      stream: _service.watchLeaderboard(widget.roomCode),
      builder: (context, snap) {
        final players = snap.data ?? [];
        final canStart = players.length >= kMinPlayers;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('رمز الغرفة', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Text(
                widget.roomCode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text('مدينة ${kCities[room.cityId]!.name} · ${room.durationMinutes} دقائق',
                  style: const TextStyle(color: Colors.white54)),
              const SizedBox(height: 24),
              Text('اللاعبون (${players.length}/$kMaxPlayers)',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, i) => ListTile(
                    leading: const Icon(Icons.person, color: Colors.white70),
                    title: Text(players[i].name, style: const TextStyle(color: Colors.white)),
                    trailing: players[i].playerId == room.hostPlayerId
                        ? const Text('المضيف 👑', style: TextStyle(color: Colors.amber))
                        : null,
                  ),
                ),
              ),
              if (isHost)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: canStart ? () => _service.startMatch(widget.roomCode) : null,
                    child: Text(canStart ? 'ابدأ الجولة' : 'بانتظار لاعب آخر على الأقل'),
                  ),
                )
              else
                const Text('بانتظار المضيف يبدأ الجولة...', style: TextStyle(color: Colors.white54)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayingRoom(RoomInfo room, CityConfig city) {
    final derived = _state.computeDerivedStats();
    final endsAt = room.endsAt;
    final remaining = endsAt?.difference(DateTime.now());

    if (remaining != null && remaining.isNegative && !_finishRequested) {
      _finishRequested = true;
      _service.pushMyStats(roomCode: widget.roomCode, playerId: widget.playerId, state: _state);
      _service.finishMatch(widget.roomCode);
    }

    return Column(
      children: [
        Container(
          color: const Color(0xFF1E293B),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(city.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              if (remaining != null && !remaining.isNegative)
                Text(
                  '⏱ ${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
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
              ),
              Positioned(
                top: 8,
                left: 8,
                child: _buildLeaderboardOverlay(),
              ),
            ],
          ),
        ),
        BuildingPalette(
          selectedType: _selectedType,
          gold: _state.gold,
          onSelect: (type) => setState(() => _selectedType = _selectedType == type ? null : type),
        ),
      ],
    );
  }

  Widget _buildLeaderboardOverlay() {
    return StreamBuilder<List<PlayerScore>>(
      stream: _service.watchLeaderboard(widget.roomCode),
      builder: (context, snap) {
        final players = snap.data ?? [];
        return GestureDetector(
          onTap: () => setState(() => _leaderboardExpanded = !_leaderboardExpanded),
          child: Container(
            width: _leaderboardExpanded ? 200 : 140,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🏆 لوحة الصدارة',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                for (var i = 0; i < players.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Text('${i + 1}.', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            players[i].name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: players[i].playerId == widget.playerId
                                  ? Colors.amber
                                  : Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Text(players[i].score.floor().toString(),
                            style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFinishedRoom(RoomInfo room) {
    return StreamBuilder<List<PlayerScore>>(
      stream: _service.watchLeaderboard(widget.roomCode),
      builder: (context, snap) {
        final players = snap.data ?? [];
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('🏁 انتهت الجولة!',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, i) {
                    final p = players[i];
                    final isMe = p.playerId == widget.playerId;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: i == 0 ? const Color(0xFF422006) : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                        border: isMe ? Border.all(color: Colors.amber, width: 2) : null,
                      ),
                      child: Row(
                        children: [
                          Text(i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : '${i + 1}.',
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(p.name, style: const TextStyle(color: Colors.white)),
                          ),
                          Text('نقاط: ${p.score.floor()}',
                              style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF334155)),
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  child: const Text('رجوع للرئيسية'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
