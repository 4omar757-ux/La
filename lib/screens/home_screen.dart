import 'package:flutter/material.dart';
import 'solo_screen.dart';
import 'group/group_setup_screen.dart';
import '../services/room_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.quiz_rounded, size: 64, color: Color(0xFF6C5CE7)),
              const SizedBox(height: 12),
              const Text(
                'ق',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const Text(
                'اختر طريقة اللعب',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              _ModeCard(
                icon: Icons.bolt_rounded,
                title: 'مجموعة - الأسرع يفوز',
                subtitle: 'أول من يجاوب صح ياخذ أعلى نقاط',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const GroupSetupScreen(initialType: GroupScoringType.fastest),
                )),
              ),
              const SizedBox(height: 14),
              _ModeCard(
                icon: Icons.timer_rounded,
                title: 'مجموعة - سباق الوقت',
                subtitle: 'كل من يجاوب صح قبل انتهاء الوقت ياخذ النقاط كاملة',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const GroupSetupScreen(initialType: GroupScoringType.timed),
                )),
              ),
              const SizedBox(height: 14),
              _ModeCard(
                icon: Icons.person_rounded,
                title: 'اللعب الفردي',
                subtitle: 'العب لحالك مع عداد وقت',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const SoloScreen(),
                )),
              ),
              const SizedBox(height: 14),
              _ModeCard(
                icon: Icons.public_rounded,
                title: 'مجموعة عبر الإنترنت',
                subtitle: 'العب مع أصدقاء بأي مكان عن طريق كود الغرفة',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const GroupSetupScreen(initialType: null),
                )),
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
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF6C5CE7),
                child: Icon(icon, color: Colors.white),
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
