import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/room_service.dart';

/// صفحة مستقلة تظهر بعد كل سؤال (بأي نظام تسجيل نقاط) تسرد كل لاعب باسمه
/// ونقاطه مرتبة تنازلياً. تُفتح فوق RoomQuizScreen وتُغلق نفسها تلقائياً
/// بمجرد ما رقم السؤال الحالي بالغرفة يتغيّر أو تنتهي المسابقة — لكن هذا
/// التغيير نفسه لم يعد يصير تلقائياً بعد مهلة: المضيف فقط هو من يبدأه
/// صراحة بضغط زر "السؤال التالي"/"إنهاء المسابقة" بالأسفل. بقية اللاعبين
/// يشوفون رسالة انتظار بدل الزر، وتنتقل شاشتهم تلقائياً بمجرد ما المضيف
/// يضغط (عبر نفس آلية الإغلاق التلقائي أعلاه).
class StandingsScreen extends StatefulWidget {
  final String code;
  final int questionIndex;
  final bool isHost;
  final bool isLastQuestion;

  const StandingsScreen({
    super.key,
    required this.code,
    required this.questionIndex,
    required this.isHost,
    required this.isLastQuestion,
  });

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  final _roomService = RoomService();
  bool _popped = false;
  bool _advancing = false;

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

  Future<void> _onAdvancePressed() async {
    if (_advancing) return;
    setState(() => _advancing = true);
    try {
      await _roomService.advanceQuestion(code: widget.code, questionIndex: widget.questionIndex);
    } catch (_) {
      if (mounted) {
        setState(() => _advancing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر الانتقال، حاول مرة ثانية')),
        );
      }
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
                    if (widget.isHost)
                      FilledButton(
                        onPressed: _advancing ? null : _onAdvancePressed,
                        child: Text(
                          _advancing
                              ? '...'
                              : widget.isLastQuestion
                                  ? 'إنهاء المسابقة'
                                  : 'السؤال التالي',
                        ),
                      )
                    else
                      const Text(
                        'بانتظار المضيف للانتقال للسؤال التالي...',
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
