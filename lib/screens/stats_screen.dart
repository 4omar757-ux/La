import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/section_stats_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<QuestionSection, SectionStats>? _stats;

  @override
  void initState() {
    super.initState();
    SectionStatsService.instance.all().then((s) {
      if (mounted) setState(() => _stats = s);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إحصائياتي')),
      body: _stats == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'أداؤك بكل قسم من أقسام قياس (الوضع الفردي)',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                for (final section in QuestionSection.values) ...[
                  _SectionStatCard(section: section, stats: _stats![section]),
                  const SizedBox(height: 14),
                ],
              ],
            ),
    );
  }
}

class _SectionStatCard extends StatelessWidget {
  final QuestionSection section;
  final SectionStats? stats;

  const _SectionStatCard({required this.section, required this.stats});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = stats?.total ?? 0;
    final correct = stats?.correct ?? 0;
    final percent = stats?.percent ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    section.label,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  total == 0 ? 'لا يوجد بيانات بعد' : '$correct / $total',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            if (total > 0) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 10,
                  backgroundColor: scheme.surfaceContainerHighest,
                  color: percent >= 0.7
                      ? Colors.green
                      : percent >= 0.4
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
              const SizedBox(height: 6),
              Text('${(percent * 100).round()}٪', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}
