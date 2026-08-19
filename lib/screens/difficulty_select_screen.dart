import 'package:flutter/material.dart';
import '../models/question.dart';

const List<int> questionCountOptions = [10, 20, 30, 50];
const int defaultQuestionCount = 10;

const List<int> questionSecondsOptions = [15, 20, 30, 45];
const int defaultQuestionSeconds = 20;

class DifficultySelectScreen extends StatefulWidget {
  final void Function(
    Difficulty difficulty,
    int questionCount,
    QuestionSection? section,
    int questionSeconds,
  ) onSelected;

  const DifficultySelectScreen({super.key, required this.onSelected});

  @override
  State<DifficultySelectScreen> createState() => _DifficultySelectScreenState();
}

class _DifficultySelectScreenState extends State<DifficultySelectScreen> {
  int _questionCount = defaultQuestionCount;
  int _questionSeconds = defaultQuestionSeconds;
  QuestionSection? _section;

  List<int> get _availableCounts =>
      _section == null ? questionCountOptions : questionCountOptions.where((c) => c <= 30).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اختر مستوى الصعوبة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('القسم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('عشوائي (كل الأقسام)'),
                  selected: _section == null,
                  onSelected: (_) => setState(() {
                    _section = null;
                    if (!_availableCounts.contains(_questionCount)) {
                      _questionCount = _availableCounts.first;
                    }
                  }),
                ),
                for (final s in QuestionSection.values)
                  ChoiceChip(
                    label: Text(s.label),
                    selected: _section == s,
                    onSelected: (_) => setState(() {
                      _section = s;
                      if (!_availableCounts.contains(_questionCount)) {
                        _questionCount = _availableCounts.last;
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('عدد الأسئلة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            SegmentedButton<int>(
              segments: [
                for (final c in _availableCounts) ButtonSegment(value: c, label: Text('$c')),
              ],
              selected: {_questionCount},
              onSelectionChanged: (s) => setState(() => _questionCount = s.first),
            ),
            const SizedBox(height: 24),
            const Text('الوقت لكل سؤال', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            SegmentedButton<int>(
              segments: [
                for (final s in questionSecondsOptions) ButtonSegment(value: s, label: Text('$s ث')),
              ],
              selected: {_questionSeconds},
              onSelectionChanged: (s) => setState(() => _questionSeconds = s.first),
            ),
            const SizedBox(height: 24),
            const Text('مستوى الصعوبة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            for (final d in Difficulty.values) ...[
              _DifficultyCard(
                difficulty: d,
                onTap: () {
                  if (ModalRoute.of(context)!.isCurrent) {
                    widget.onSelected(d, _questionCount, _section, _questionSeconds);
                  }
                },
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  final Difficulty difficulty;
  final VoidCallback onTap;

  const _DifficultyCard({required this.difficulty, required this.onTap});

  IconData get _icon {
    switch (difficulty) {
      case Difficulty.beginner:
        return Icons.emoji_emotions_outlined;
      case Difficulty.intermediate:
        return Icons.trending_up_rounded;
      case Difficulty.hard:
        return Icons.local_fire_department_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: scheme.primaryContainer,
                child: Icon(_icon, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  difficulty.label,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Icon(Icons.chevron_left_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
