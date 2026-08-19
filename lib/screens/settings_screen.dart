import 'package:flutter/material.dart';
import '../services/sound_service.dart';
import 'stats_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _volume = SoundService.instance.volume;

  @override
  void initState() {
    super.initState();
    SoundService.instance.init().then((_) {
      if (mounted) setState(() => _volume = SoundService.instance.volume);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SectionTitle('الصوت'),
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(_volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('مستوى صوت المؤقت', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Text('${(_volume * 100).round()}٪', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  Slider(
                    value: _volume,
                    onChanged: (v) {
                      setState(() => _volume = v);
                      SoundService.instance.setVolume(v);
                    },
                    onChangeEnd: (v) => SoundService.instance.playTick(),
                  ),
                ],
              ),
            ),
          ),
          const _SectionTitle('أدائي'),
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            child: ListTile(
              leading: const Icon(Icons.bar_chart_rounded),
              title: const Text('إحصائياتي بأقسام قياس', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('نسبة إجاباتك الصحيحة بكل قسم (تصنيف، تناظر، إكمال جمل)'),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () {
                if (!ModalRoute.of(context)!.isCurrent) return;
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StatsScreen()));
              },
            ),
          ),
          const _SectionTitle('عن التطبيق'),
          const _InfoTile(
            icon: Icons.info_outline_rounded,
            title: 'تطبيق "ق"',
            subtitle: 'تطبيق مسابقات أسئلة، فيه أوضاع فردية وجماعية بمستويات صعوبة مختلفة (مبتدئ، متوسط، صعب).',
          ),
          const _InfoTile(
            icon: Icons.numbers_rounded,
            title: 'الإصدار',
            subtitle: '1.0.0',
          ),
          const SizedBox(height: 24),
          const _SectionTitle('عن المطوّر'),
          const _InfoTile(
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
