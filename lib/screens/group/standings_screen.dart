import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/room_service.dart';

/// صفحة مستقلة تظهر بعد كل سؤال (بأي نظام تسجيل نقاط) تسرد كل لاعب باسمه
/// ونقاطه مرتبة تنازلياً. تُفتح فوق RoomQuizScreen وتُغلق نفسها تلقائياً
/// بمجرد ما رقم السؤال الحالي بالغرفة يتغيّر (المضيف انتقل للسؤال التالي)
/// أو تنتهي المسابقة — الشاشة اللي تحتها (RoomQuizScreen) أصلاً تتولى
/// عرض السؤال الجديد أو الانتقال لشاشة النتائج النهائية بمجرد ما تنكشف.
class StandingsScreen extends StatefulWidget {
  final String code;
  final int questionIndex;

  const StandingsScreen({super.key, required this.code, required this.questionIndex});

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  final _roomService = RoomService();
  bool _popped = false;

  void _maybeGoBack(Map<String, dynamic> roomData) {
    if (_popped) return;
    final status = roomData['status'] as String?;
    final currentIndex = roomData['currentIndex'] as int?;
    if (status == 'finished' || (currentIndex != null && currentIndex != widget.questionIndex)) {
      _popped = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الترتيب')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _roomService.watchRoom(widget.code),
        builder: (context, roomSnap) {
          if (roomSnap.hasData && roomSnap.data!.exists) {
            _maybeGoBack(roomSnap.data!.data()!);
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _roomService.watchPlayers(widget.code),
            builder: (context, playersSnap) {
              if (!playersSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final players = playersSnap.data!.docs
                  .where((d) => d.data()['left'] != true)
                  .map((d) => (
                        name: d.data()['name'] as String? ?? '',
                        score: (d.data()['score'] as num?)?.toInt() ?? 0,
                      ))
                  .toList()
                ..sort((a, b) => b.score.compareTo(a.score));

              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'الترتيب بعد هذا السؤال',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.separated(
                        itemCount: players.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final p = players[i];
                          final scheme = Theme.of(context).colorScheme;
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: i == 0 ? Colors.amber : scheme.primaryContainer,
                                foregroundColor: i == 0 ? Colors.white : scheme.onPrimaryContainer,
                                child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              title: Text(
                                p.name,
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              trailing: Text(
                                '${p.score}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'بانتظار انتقال الجميع للسؤال التالي...',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
