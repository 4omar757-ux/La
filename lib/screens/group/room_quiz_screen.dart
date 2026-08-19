import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/sample_questions.dart';
import '../../models/question.dart';
import '../../services/room_service.dart';
import '../../services/sound_service.dart';
import '../../widgets/option_button.dart';
import '../../widgets/clock_countdown.dart';
import 'room_results_screen.dart';

class RoomQuizScreen extends StatefulWidget {
  final String code;
  final String playerId;
  final bool isHost;
  final GroupScoringType scoringType;

  const RoomQuizScreen({
    super.key,
    required this.code,
    required this.playerId,
    required this.isHost,
    required this.scoringType,
  });

  @override
  State<RoomQuizScreen> createState() => _RoomQuizScreenState();
}

class _RoomQuizScreenState extends State<RoomQuizScreen> {
  final _roomService = RoomService();
  Timer? _ticker;
  int _lastSeenIndex = -1;
  int? _selected;
  bool _answeredThisQuestion = false;
  // true بمجرد ما اللاعب يجاوب أو ينتهي الوقت — نبيّن له وقتها الإجابة
  // الصحيحة والسبب مباشرة (زي الفردي بالضبط)، بدل ما ينتظر لين تنتهي
  // المسابقة كلها ليشوف كان صح ولا غلط.
  bool _revealed = false;
  int _closingIndex = -1; // آخر سؤال طلب المضيف إغلاقه (يمنع التكرار)
  DateTime? _questionStarted;
  int _secondsLeft = 0;
  bool _navigatedToResults = false;

  int get _duration =>
      widget.scoringType == GroupScoringType.timed ? timedModeSeconds : fastestModeMaxSeconds;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _onRoomUpdate(Map<String, dynamic> roomData) {
    final index = roomData['currentIndex'] as int;
    final status = roomData['status'] as String;
    final startedAtTs = roomData['currentQuestionStartedAt'] as Timestamp?;

    if (status == 'finished' && !_navigatedToResults) {
      _navigatedToResults = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => RoomResultsScreen(code: widget.code),
        ));
      });
      return;
    }

    if (index != _lastSeenIndex) {
      _lastSeenIndex = index;
      _answeredThisQuestion = false;
      _selected = null;
      _revealed = false;
      _questionStarted = startedAtTs?.toDate();
      _restartTicker();
    } else if (_questionStarted == null && startedAtTs != null) {
      // نفس السؤال، بس أول snapshot كان يحمل قيمة null مؤقتة لأن
      // FieldValue.serverTimestamp() يوصل الجهاز أول مرة كـ "صدى محلي"
      // (local echo) قبل ما يتأكد السيرفر ويرجع الوقت الحقيقي في تحديث
      // ثانٍ لنفس currentIndex. بدون هذا الشرط يبقى العداد واقف عند صفر
      // للأبد لأن الشرط أعلاه ما يعيد تشغيله مرة ثانية لنفس السؤال.
      _questionStarted = startedAtTs.toDate();
      _restartTicker();
    }
  }

  void _restartTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_questionStarted == null) return;
      final elapsed = DateTime.now().difference(_questionStarted!).inSeconds;
      final left = (_duration - elapsed).clamp(0, _duration);
      if (mounted) setState(() => _secondsLeft = left);
      if (left <= 0) {
        SoundService.instance.playTimeUp();
        HapticFeedback.mediumImpact();
        if (!_revealed && mounted) setState(() => _revealed = true);
        if (widget.isHost && _closingIndex != _lastSeenIndex) {
          _closingIndex = _lastSeenIndex;
          _roomService.closeQuestionAndScore(
            code: widget.code,
            questionIndex: _lastSeenIndex,
            scoringType: widget.scoringType,
          );
        }
      } else {
        SoundService.instance.playTick();
        HapticFeedback.selectionClick();
      }
    });
  }

  Future<void> _checkAllAnswered(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> answers,
    int playerCount,
  ) async {
    if (!widget.isHost) return;
    if (_closingIndex == _lastSeenIndex) return;
    if (playerCount > 0 && answers.length >= playerCount) {
      _closingIndex = _lastSeenIndex;
      await _roomService.closeQuestionAndScore(
        code: widget.code,
        questionIndex: _lastSeenIndex,
        scoringType: widget.scoringType,
      );
    }
  }

  Future<void> _onAnswer(int optionIndex, Question question) async {
    if (_revealed) return;
    final correct = optionIndex == question.correctIndex;
    setState(() {
      _answeredThisQuestion = true;
      _selected = optionIndex;
      _revealed = true;
    });
    if (correct) {
      SoundService.instance.playCorrect();
    } else {
      SoundService.instance.playWrong();
    }
    await _roomService.submitAnswer(
      code: widget.code,
      questionIndex: _lastSeenIndex,
      playerId: widget.playerId,
      optionIndex: optionIndex,
      correct: optionIndex == question.correctIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('كود الغرفة: ${widget.code}')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _roomService.watchRoom(widget.code),
        builder: (context, roomSnap) {
          if (!roomSnap.hasData || !roomSnap.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }
          final roomData = roomSnap.data!.data()!;
          _onRoomUpdate(roomData);

          if (roomData['status'] == 'finished') {
            return const Center(child: CircularProgressIndicator());
          }

          final questionIds = List<String>.from(roomData['questionIds'] as List);
          final index = roomData['currentIndex'] as int;
          if (index < 0 || index >= questionIds.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final question = sampleQuestions.firstWhere((q) => q.id == questionIds[index]).shuffled();

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _roomService.watchPlayers(widget.code),
            builder: (context, playersSnap) {
              final playerCount = playersSnap.data?.docs.length ?? 0;

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _roomService.watchAnswers(widget.code, index),
                builder: (context, answersSnap) {
                  final answered = answersSnap.data?.docs ?? [];
                  if (widget.isHost) {
                    _checkAllAnswered(answered, playerCount);
                  }

                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: ClockCountdown(
                            secondsLeft: _secondsLeft,
                            totalSeconds: _duration,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'سؤال ${index + 1} / ${questionIds.length}   •   أجاب ${answered.length}/$playerCount',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          question.text,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 24),
                        for (int i = 0; i < question.options.length; i++) ...[
                          OptionButton(
                            label: question.options[i],
                            state: !_revealed
                                ? (_selected == i ? OptionState.selected : OptionState.idle)
                                : i == question.correctIndex
                                    ? OptionState.correct
                                    : i == _selected
                                        ? OptionState.wrong
                                        : OptionState.idle,
                            onTap: _revealed ? null : () => _onAnswer(i, question),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (_revealed) ...[
                          if (!_answeredThisQuestion)
                            const Padding(
                              padding: EdgeInsets.only(top: 4, bottom: 8),
                              child: Text(
                                'انتهى الوقت قبل ما تجاوب',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            ),
                          if (question.explanation != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'السبب',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    question.explanation!,
                                    style: const TextStyle(fontSize: 14, height: 1.5),
                                  ),
                                ],
                              ),
                            ),
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'بانتظار انتقال الجميع للسؤال التالي...',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
