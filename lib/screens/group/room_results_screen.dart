import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/question.dart';
import '../../services/room_service.dart';
import '../../widgets/leaderboard.dart';
import 'lobby_screen.dart';

class RoomResultsScreen extends StatefulWidget {
  final String code;
  final bool isHost;
  final String playerId;

  const RoomResultsScreen({
    super.key,
    required this.code,
    required this.isHost,
    required this.playerId,
  });

  @override
  State<RoomResultsScreen> createState() => _RoomResultsScreenState();
}

class _RoomResultsScreenState extends State<RoomResultsScreen> {
  final _roomService = RoomService();
  bool _creatingNewRoom = false;
  String? _error;

  Future<void> _playAgain() async {
    setState(() {
      _creatingNewRoom = true;
      _error = null;
    });
    try {
      final roomSnap = await _roomService.watchRoom(widget.code).first;
      final roomData = roomSnap.data()!;
      final scoringType = GroupScoringType.values.byName(roomData['scoringType'] as String);
      final difficulty = Difficulty.values.byName(roomData['difficulty'] as String);
      final questionCount = (roomData['questionIds'] as List).length;

      final playerSnap = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.code)
          .collection('players')
          .doc(widget.playerId)
          .get();
      final hostName = (playerSnap.data()?['name'] as String?) ?? 'المضيف';

      final newCode = await _roomService.createRoom(
        scoringType: scoringType,
        difficulty: difficulty,
        questionCount: questionCount,
        hostName: hostName,
        hostPlayerId: widget.playerId,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => LobbyScreen(code: newCode, playerId: widget.playerId, isHost: true),
      ));
    } catch (e) {
      if (mounted) {
        setState(() {
          _creatingNewRoom = false;
          _error = 'تعذر إنشاء غرفة جديدة، حاول مرة أخرى';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('النتيجة النهائية')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _roomService.watchPlayers(widget.code),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snap.data!.docs.map((d) {
            final data = d.data();
            return LeaderboardEntry(
              name: data['name'] as String,
              score: (data['score'] as num?)?.toInt() ?? 0,
            );
          }).toList();
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.emoji_events_rounded, size: 64, color: Colors.amber),
                const SizedBox(height: 8),
                const Text(
                  'انتهت المسابقة!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Leaderboard(entries: entries),
                const SizedBox(height: 24),
                if (widget.isHost) ...[
                  ElevatedButton(
                    onPressed: _creatingNewRoom ? null : _playAgain,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: _creatingNewRoom
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('غرفة جديدة بنفس الإعدادات'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 12),
                ] else
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'اطلب من المضيف كود غرفة جديدة لو تبون تلعبون مرة ثانية',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('رجوع للرئيسية'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
