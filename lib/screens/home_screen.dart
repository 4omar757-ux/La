import 'package:flutter/material.dart';
import 'solo_screen.dart';
import 'group/group_setup_screen.dart';
import 'difficulty_select_screen.dart';
import 'settings_screen.dart';
import '../models/question.dart';
import '../services/room_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openSolo(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DifficultySelectScreen(
        onSelected: (difficulty) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => SoloScreen(difficulty: difficulty),
          ));
        },
      ),
    ));
  }

  void _openGroup(BuildContext context, GroupScoringType? scoringType) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DifficultySelectScreen(
        onSelected: (difficulty) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => GroupSetupScreen(initialType: scoringType, difficulty: difficulty),
          ));
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/branding/qaf_logo.png', height: 34),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'الإعدادات',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const SettingsScreen(),
            )),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text(
                'اختر طريقة اللعب',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 28),
              _ModeCard(
                icon: Icons.bolt_rounded,
                title: 'مجموعة - الأسرع يفوز',
                subtitle: 'أول من يجاوب صح ياخذ أعلى نقاط',
                onTap: () => _openGroup(context, GroupScoringType.fastest),
              ),
              const SizedBox(height: 14),
              _ModeCard(
                icon: Icons.timer_rounded,
                title: 'مجموعة - سباق الوقت',
                subtitle: 'كل من يجاوب صح قبل انتهاء الوقت ياخذ النقاط كاملة',
                onTap: () => _openGroup(context, GroupScoringType.timed),
              ),
              const SizedBox(height: 14),
              _ModeCard(
                icon: Icons.person_rounded,
                title: 'اللعب الفردي',
                subtitle: 'العب لحالك مع عداد وقت',
                onTap: () => _openSolo(context),
              ),
              const SizedBox(height: 14),
              _ModeCard(
                icon: Icons.public_rounded,
                title: 'مجموعة عبر الإنترنت',
                subtitle: 'العب مع أصدقاء بأي مكان عن طريق كود الغرفة',
                onTap: () => _openGroup(context, null),
              ),
              const SizedBox(height: 8),
              Center(
                child: Opacity(
                  opacity: 0.28,
                  child: Image.asset('assets/branding/qaf_logo.png', height: 44),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: scheme.primaryContainer,
                child: Icon(icon, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
