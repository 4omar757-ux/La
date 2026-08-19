import 'package:flutter/material.dart';
import '../models/question.dart';

class MissedAnswer {
  final Question question;
  final int? selectedIndex;

  const MissedAnswer({required this.question, required this.selectedIndex});
}

class AnswerReviewScreen extends StatelessWidget {
  final List<MissedAnswer> missed;

  const AnswerReviewScreen({super.key, required this.missed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('راجع أخطاءك (${missed.length})')),
      body: missed.isEmpty
          ? const Center(child: Text('ما فيه أخطاء لمراجعتها 🎉'))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: missed.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, i) => _MissedCard(missed: missed[i]),
            ),
    );
  }
}

class _MissedCard extends StatelessWidget {
  final MissedAnswer missed;
  const _MissedCard({required this.missed});

  @override
  Widget build(BuildContext context) {
    final q = missed.question;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(q.section.label, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 6),
            Text(q.text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
            const SizedBox(height: 12),
            for (int i = 0; i < q.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      i == q.correctIndex
                          ? Icons.check_circle_rounded
                          : i == missed.selectedIndex
                              ? Icons.cancel_rounded
                              : Icons.circle_outlined,
                      size: 18,
                      color: i == q.correctIndex
                          ? Colors.green
                          : i == missed.selectedIndex
                              ? Colors.red
                              : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        q.options[i],
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: i == q.correctIndex ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (missed.selectedIndex == null)
              const Padding(
                padding: EdgeInsets.only(top: 4, bottom: 4),
                child: Text('لم تجب قبل انتهاء الوقت', style: TextStyle(color: Colors.red)),
              ),
            if (q.explanation != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(q.explanation!, style: const TextStyle(fontSize: 13, height: 1.5)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
