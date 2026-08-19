import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/question.dart';
import '../../services/room_service.dart';
import 'room_quiz_screen.dart';

class LobbyScreen extends StatefulWidget {
  final String code;
  final String playerId;
  final bool isHost;

  const LobbyScreen({
    super.key,
    required this.code,
    required this.playerId,
    required this.isHost,
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _roomService = RoomService();
  bool _navigated = false;

  Future<void> _leave() async {
    try {
      await _roomService.leaveRoom(code: widget.code, playerId: widget.playerId);
    } catch (_) {
      // تجاهل؛ المهم إنه يقدر يطلع من الشاشة حتى لو فشل تسجيل المغادرة.
    }
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('غرفة الانتظار'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app_rounded),
            tooltip: 'مغادرة الغرفة',
            onPressed: _leave,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _roomService.watchRoom(widget.code),
        builder: (context, roomSnap) {
          if (!roomSnap.hasData || !roomSnap.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }
          final roomData = roomSnap.data!.data()!;
          final status = roomData['status'] as String;
          final scoringType = GroupScoringType.values.byName(roomData['scoringType'] as String);

          if (status == 'playing' && !_navigated) {
            _navigated = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (_) => RoomQuizScreen(
                  code: widget.code,
                  playerId: widget.playerId,
                  isHost: widget.isHost,
                  scoringType: scoringType,
                ),
              ));
            });
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text('كود الغرفة', style: TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 4),
                SelectableText(
                  widget.code,
                  style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, letterSpacing: 4),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(
                      text: 'انضم لمسابقتي على تطبيق ق! افتح التطبيق واستخدم كود الغرفة: ${widget.code}',
                    ),
                  ),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('شارك الكود'),
                ),
                const SizedBox(height: 4),
                Text(
                  scoringType == GroupScoringType.fastest ? 'الوضع: الأسرع يفوز' : 'الوضع: سباق الوقت',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  'الصعوبة: ${Difficulty.values.byName(roomData['difficulty'] as String).label}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('اللاعبون:', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _roomService.watchPlayers(widget.code),
                    builder: (context, playersSnap) {
                      final docs = (playersSnap.data?.docs ?? [])
                          .where((d) => d.data()['left'] != true)
                          .toList();
                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, i) {
                          final name = docs[i].data()['name'] as String;
                          return ListTile(
                            leading: const Icon(Icons.person_rounded),
                            title: Text(name, textAlign: TextAlign.right),
                          );
                        },
                      );
                    },
                  ),
                ),
                if (widget.isHost)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _roomService.startGame(widget.code),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('ابدأ المسابقة'),
                    ),
                  )
                else
                  const Text('بانتظار المضيف يبدأ المسابقة...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        },
      ),
    );
  }
}
