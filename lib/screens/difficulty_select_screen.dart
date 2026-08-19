import 'package:flutter/material.dart';
import '../models/question.dart';

const List<int> questionCountOptions = [10, 20, 30, 50];
const int defaultQuestionCount = 10;

class DifficultySelectScreen extends StatefulWidget {
  final void Function(Difficulty difficulty, int questionCount) onSelected;

  const DifficultySelectScreen({super.key, required this.onSelected});

  @override
  State<DifficultySelectScreen> createState() => _DifficultySelectScreenState();
}

class _DifficultySelectScreenState extends State<DifficultySelectScreen> {
  int _questionCount = defaultQuestionCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اختر مستوى الصعوبة')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('عدد الأسئلة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            SegmentedButton<int>(
              segments: [
                for (final c in questionCountOptions) ButtonSegment(value: c, label: Text('$c')),
              ],
              selected: {_questionCount},
              onSelectionChanged: (s) => setState(() => _questionCount = s.first),
            ),
            const SizedBox(height: 24),
            const Text('مستوى الصعوبة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            for (final d in Difficulty.values) ...[
              _DifficultyCard(
                difficulty: d,
                onTap: () {
                  if (ModalRoute.of(context)!.isCurrent) widget.onSelected(d, _questionCount);
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
