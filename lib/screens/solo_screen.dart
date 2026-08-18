import 'dart:async';
import 'package:flutter/material.dart';
import '../data/sample_questions.dart';
import '../models/question.dart';
import '../widgets/option_button.dart';
import '../widgets/countdown_bar.dart';

const int _secondsPerQuestion = 15;

class SoloScreen extends StatefulWidget {
  const SoloScreen({super.key});

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
    _questions = List.of(sampleQuestions)..shuffle();
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
        if (!_answered) _onAnswer(null);
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
    Future.delayed(const Duration(milliseconds: 1200), _nextQuestion);
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CountdownBar(
              remainingFraction: _secondsLeft / _secondsPerQuestion,
              secondsLeft: _secondsLeft.clamp(0, _secondsPerQuestion),
            ),
            const SizedBox(height: 24),
            Text(
              'النقاط: $_score',
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
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
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
