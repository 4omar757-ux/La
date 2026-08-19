import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/sample_questions.dart';
import '../models/question.dart';
import '../services/sound_service.dart';
import '../widgets/option_button.dart';
import '../widgets/clock_countdown.dart';

const int _secondsPerQuestion = 15;

class SoloScreen extends StatefulWidget {
  final Difficulty difficulty;
  const SoloScreen({super.key, required this.difficulty});

  @override
  State<SoloScreen> createState() => _SoloScreenState();
}

class _SoloScreenState extends State<SoloScreen> {
  late final List<Question> _questions;
  int _index = 0;
  int _score = 0;
  int? _selected;
  bool _answered = false;
  Timer? _timer;
  int _secondsLeft = _secondsPerQuestion;
  final Stopwatch _totalTime = Stopwatch();

  @override
  void initState() {
    super.initState();
    _questions = sampleQuestions
        .where((q) => q.difficulty == widget.difficulty)
        .map((q) => q.shuffled())
        .toList()
      ..shuffle();
    _totalTime.start();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _secondsLeft = _secondsPerQuestion;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsLeft--;
      });
      if (_secondsLeft <= 0) {
        timer.cancel();
        SoundService.instance.playTimeUp();
        HapticFeedback.mediumImpact();
        if (!_answered) _onAnswer(null);
      } else {
        SoundService.instance.playTick();
        HapticFeedback.selectionClick();
      }
    });
  }

  void _onAnswer(int? optionIndex) {
    if (_answered) return;
    _timer?.cancel();
    final question = _questions[_index];
    final correct = optionIndex == question.correctIndex;
    setState(() {
      _answered = true;
      _selected = optionIndex;
      if (correct) _score += 10;
    });
    // إذا السؤال فيه توضيح/سبب، ننتظر ضغطة "التالي" حتى يقدر يقرأه بدل ما
    // ننتقل تلقائياً بسرعة.
    if (question.explanation == null) {
      Future.delayed(const Duration(milliseconds: 1200), _nextQuestion);
    }
  }

  void _nextQuestion() {
    if (!mounted) return;
    if (_index >= _questions.length - 1) {
      _totalTime.stop();
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => _SoloResultsScreen(
          score: _score,
          total: _questions.length,
          elapsed: _totalTime.elapsed,
        ),
      ));
      return;
    }
    setState(() {
      _index++;
      _answered = false;
      _selected = null;
    });
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_index];
    return Scaffold(
      appBar: AppBar(
        title: Text('سؤال ${_index + 1} / ${_questions.length}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ClockCountdown(
                secondsLeft: _secondsLeft.clamp(0, _secondsPerQuestion),
                totalSeconds: _secondsPerQuestion,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'النقاط: $_score',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              question.text,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 28),
            for (int i = 0; i < question.options.length; i++) ...[
              OptionButton(
                label: question.options[i],
                state: !_answered
                    ? OptionState.idle
                    : i == question.correctIndex
                        ? OptionState.correct
                        : i == _selected
                            ? OptionState.wrong
                            : OptionState.idle,
                onTap: _answered ? null : () => _onAnswer(i),
              ),
              const SizedBox(height: 12),
            ],
            if (_answered && question.explanation != null) ...[
              const SizedBox(height: 8),
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
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _nextQuestion,
                child: Text(_index >= _questions.length - 1 ? 'عرض النتيجة' : 'التالي'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SoloResultsScreen extends StatelessWidget {
  final int score;
  final int total;
  final Duration elapsed;

  const _SoloResultsScreen({
    required this.score,
    required this.total,
    required this.elapsed,
  });

  @override
  Widget build(BuildContext context) {
    final maxScore = total * 10;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events_rounded, size: 72, color: Colors.amber),
                const SizedBox(height: 16),
                const Text('انتهت المسابقة!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text('نتيجتك: $score / $maxScore', style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 6),
                Text(
                  'الوقت الكلي: ${elapsed.inMinutes} د ${elapsed.inSeconds % 60} ث',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    child: const Text('رجوع للرئيسية'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
