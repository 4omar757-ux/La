import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _SectionTitle('عن التطبيق'),
          _InfoTile(
            icon: Icons.info_outline_rounded,
            title: 'تطبيق "ق"',
            subtitle: 'تطبيق مسابقات أسئلة، فيه أوضاع فردية وجماعية بمستويات صعوبة مختلفة (مبتدئ، متوسط، صعب).',
          ),
          _InfoTile(
            icon: Icons.numbers_rounded,
            title: 'الإصدار',
            subtitle: '1.0.0',
          ),
          SizedBox(height: 24),
          _SectionTitle('عن المطوّر'),
          _InfoTile(
            icon: Icons.person_outline_rounded,
            title: 'البرمجة والتصميم',
            subtitle: 'عمر العايد',
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              child: Icon(icon, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
