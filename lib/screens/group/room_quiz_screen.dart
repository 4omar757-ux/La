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
  final int questionSeconds;

  const RoomQuizScreen({
    super.key,
    required this.code,
    required this.playerId,
    required this.isHost,
    required this.scoringType,
    required this.questionSeconds,
  });

  @override
  State<RoomQuizScreen> createState() => _RoomQuizScreenState();
}

// مدة انتظار ثابتة بعد إجابة الجميع أو انتهاء الوقت، حتى يقدر كل لاعب
// يشوف الإجابة الصحيحة ويقرأ السبب قبل ما ننتقل للسؤال التالي — بدونها
// كان الانتقال يصير فوري (خصوصاً لو غرفة بلاعب وحيد يختبر لحاله)، فما
// يقدر أحد يشوف شي.
const int _revealPauseSeconds = 4;

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

  // نحصر القيمة بحدود معقولة دفاعياً — لو وصلت قيمة فاسدة أو غير موجبة
  // (بيانات معطوبة، أو تعديل يدوي على وثيقة الغرفة)، فـ (left).clamp(0,
  // _duration) يرمي استثناء لأي قيمة سالبة لـ _duration، وهذا يعطّل العداد
  // عند كل لاعب بالغرفة (حقل مشترك، مو مجرد خلل عند جهاز واحد).
  int get _duration => widget.questionSeconds.clamp(5, 120);

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
          builder: (_) => RoomResultsScreen(
            code: widget.code,
            isHost: widget.isHost,
            playerId: widget.playerId,
          ),
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
    // نصفّر العداد المعروض فوراً هنا (لا ننتظر أول تكة بعد 500ms) — قبل
    // هذا التصفير كان الرقم المعروض يفضل يحمل قيمة السؤال السابق (حتى لو
    // كان صفر أو أي رقم آخر) لحظياً لين أول تكة توصل، وهذا يعطي انطباع
    // مضلل عن الوقت الحقيقي المتبقي.
    _secondsLeft = _duration;
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_questionStarted == null) return;
      final elapsed = DateTime.now().difference(_questionStarted!).inSeconds;
      final left = (_duration - elapsed).clamp(0, _duration);
      if (mounted) setState(() => _secondsLeft = left);
      if (left <= 0) {
        // نوقف التكة تماماً هنا — بدون هذا كانت تستمر تشتغل كل 500ms طول
        // مهلة العرض الأربع ثواني (وتكرر صوت/اهتزاز "انتهى الوقت" حوالي ٨
        // مرات بدل مرة وحدة)، وأهم من هذا: لو _questionStarted انلمس لأي
        // سبب بعدها (حتى لو ما يفترض)، التكة كانت تقدر تعيد حساب رقم
        // مختلف تماماً عن ٠ بعد ما "انتهى الوقت" ظهر فعلاً للمستخدم —
        // بالضبط التناقض اللي المستخدم صوّره (عداد يبيّن ١٩ ولوحة "انتهى
        // الوقت" ظاهرة بنفس الوقت).
        _ticker?.cancel();
        if (!_revealed) {
          SoundService.instance.playTimeUp();
          HapticFeedback.mediumImpact();
          if (mounted) setState(() => _revealed = true);
        }
        if (widget.isHost && _closingIndex != _lastSeenIndex) {
          _scheduleClose(_lastSeenIndex);
        }
      } else {
        SoundService.instance.playTick();
        HapticFeedback.selectionClick();
      }
    });
  }

  /// يعلّم السؤال الحالي "بصدد الإغلاق" فوراً (حتى ما نكرر الاستدعاء من
  /// إعادة رسم الواجهة المتكررة)، بس يأخر الإغلاق الفعلي (الانتقال للسؤال
  /// التالي) بمقدار [_revealPauseSeconds] حتى يقدر الجميع يشوفون الإجابة
  /// الصحيحة والسبب أول.
  Future<void> _scheduleClose(int index) async {
    _closingIndex = index;
    await Future.delayed(const Duration(seconds: _revealPauseSeconds));
    if (!mounted || _closingIndex != index) return;
    await _roomService.closeQuestionAndScore(
      code: widget.code,
      questionIndex: index,
      scoringType: widget.scoringType,
    );
  }

  Future<void> _checkAllAnswered(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> answers,
    int playerCount,
  ) async {
    if (!widget.isHost) return;
    if (_closingIndex == _lastSeenIndex) return;
    if (playerCount > 0 && answers.length >= playerCount) {
      if (!_revealed && mounted) setState(() => _revealed = true);
      await _scheduleClose(_lastSeenIndex);
    }
  }

  Future<void> _onAnswer(int optionIndex, Question question) async {
    if (_revealed) return;
    final answeredIndex = _lastSeenIndex;
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
    try {
      await _roomService.submitAnswer(
        code: widget.code,
        questionIndex: answeredIndex,
        playerId: widget.playerId,
        optionIndex: optionIndex,
        correct: optionIndex == question.correctIndex,
      );
    } catch (_) {
      // فشل إرسال الإجابة (مشكلة شبكة مؤقتة مثلاً) — نرجّع الواجهة لحالتها
      // قبل الإجابة حتى يقدر يحاول مرة ثانية، بدل ما يفتكر إنه جاوب وهو ما
      // سجّل له شي فعلياً بقاعدة البيانات (خسارة نقاط بصمت). لكن فقط لو
      // لسه بنفس السؤال — لو الفشل وصل متأخر بعد ما الغرفة انتقلت لسؤال
      // ثاني (كل لاعبين جاوبوا وسكّر المضيف الجولة قبل ما يرجع لنا رد فعل
      // الشبكة)، ما نرجّع نلمس حالة سؤال مختلف تماماً عن اللي فشل فعلاً.
      if (mounted && _lastSeenIndex == answeredIndex) {
        setState(() {
          _answeredThisQuestion = false;
          _selected = null;
          _revealed = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر إرسال إجابتك، حاول مرة ثانية')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('كود الغرفة: ${widget.code}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app_rounded),
            tooltip: 'مغادرة الغرفة',
            onPressed: () async {
              try {
                await _roomService.leaveRoom(code: widget.code, playerId: widget.playerId);
              } catch (_) {}
              if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
            },
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
              final playerCount =
                  playersSnap.data?.docs.where((d) => d.data()['left'] != true).length ?? 0;

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _roomService.watchAnswers(widget.code, index),
                builder: (context, answersSnap) {
                  // فلترة صريحة على questionIndex بدل الاعتماد فقط على شرط
                  // where() بجانب Firestore: StreamBuilder ما يصفّر بياناته
                  // فوراً لما تتغيّر قيمة stream — يفضل يعرض آخر نتيجة من
                  // الاستعلام القديم (إجابات السؤال السابق) لحظات قبل ما
                  // يوصل أول رد فعلي للاستعلام الجديد. لو السؤال السابق
                  // كان "الجميع جاوبوا"، هذي اللحظة القصيرة كانت كافية
                  // تخلي _checkAllAnswered يفتكر السؤال الجديد "خلص" فوراً
                  // بإجابات السؤال القديم، ويسكّره قبل ما اللاعب يشوفه
                  // أصلاً (بالضبط اللي ظهر بفيديو المستخدم: سؤال جديد
                  // بعداد وقت كامل لكن معروض كأنه انتهى وقته من أول لحظة).
                  final answered = (answersSnap.data?.docs ?? [])
                      .where((d) => d.data()['questionIndex'] == index)
                      .toList();
                  if (widget.isHost) {
                    _checkAllAnswered(answered, playerCount);
                  }

                  // SingleChildScrollView ضروري هنا: أسئلة قياس نصها أطول
                  // بكثير من الأسئلة القديمة (جمل كاملة أحياناً)، فمع ٤
                  // خيارات + لوحة "السبب" بعد الإجابة، المحتوى يفيض عن
                  // الشاشة بسهولة على أغلب الجوالات — بدون تمرير، اللاعب
                  // ما يقدر يشوف السبب أو حتى كل الخيارات.
                  return SingleChildScrollView(
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
                        if (_revealed && !_answeredThisQuestion)
                          // نبيّن هذا النص قبل الخيارات لا بعدها — لو ظهر
                          // بعد الخيارات، اللاعب يشوف الخيار الصحيح متلوّن
                          // أخضر أول شي بدون أي توضيح، ويبان كأن التطبيق
                          // "جاوب من نفسه" بدل ما يفهم إنه هذا بس عرض
                          // للإجابة الصحيحة لأنه ما جاوب بالوقت.
                          const Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: Text(
                              'انتهى الوقت قبل ما تجاوب — هذي كانت الإجابة الصحيحة:',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ),
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
                          _Standings(playerDocs: playersSnap.data?.docs ?? []),
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

/// ترتيب اللاعبين الحالي (الاسم والنقاط)، يظهر بعد كل سؤال بأي وضع تسجيل
/// (الأسرع يفوز أو سباق الوقت) — النقاط تتحدّث لحظياً بمجرد ما المضيف
/// يحتسبها (closeQuestionAndScore)، فالترتيب هنا يتحدّث تلقائياً بدون أي
/// إجراء إضافي بفضل أنه مبني على watchPlayers مباشرة.
class _Standings extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> playerDocs;

  const _Standings({required this.playerDocs});

  @override
  Widget build(BuildContext context) {
    final players = playerDocs
        .where((d) => d.data()['left'] != true)
        .map((d) => (
              name: d.data()['name'] as String? ?? '',
              score: (d.data()['score'] as num?)?.toInt() ?? 0,
            ))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    if (players.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'الترتيب الحالي',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < players.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      players[i].name,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${players[i].score}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
