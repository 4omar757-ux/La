import 'package:flutter/material.dart';
import 'solo_screen.dart';
import 'group/group_setup_screen.dart';
import 'difficulty_select_screen.dart';
import 'settings_screen.dart';
import 'mode_explanation_screen.dart';
import '../services/room_service.dart';

const _darkBg = Color(0xFF1D1B18);
const _surface2 = Color(0xFF33302C);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openSolo(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DifficultySelectScreen(
        onSelected: (difficulty, questionCount) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => SoloScreen(difficulty: difficulty, questionCount: questionCount),
          ));
        },
      ),
    ));
  }

  void _openGroup(BuildContext context, GroupScoringType? scoringType) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DifficultySelectScreen(
        onSelected: (difficulty, questionCount) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => GroupSetupScreen(
              initialType: scoringType,
              difficulty: difficulty,
              questionCount: questionCount,
            ),
          ));
        },
      ),
    ));
  }

  void _openExplanation(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required List<String> steps,
    required VoidCallback onStart,
  }) {
    if (!ModalRoute.of(context)!.isCurrent) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ModeExplanationScreen(
        icon: icon,
        color: color,
        title: title,
        steps: steps,
        onStart: onStart,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: _darkBg,
        elevation: 0,
        title: Image.asset(
          'assets/branding/qaf_logo.png',
          height: 30,
          color: Colors.white,
          colorBlendMode: BlendMode.srcIn,
        ),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              backgroundColor: _surface2,
              child: Icon(Icons.settings_rounded, size: 18, color: Color(0xFFE7B24B)),
            ),
            tooltip: 'الإعدادات',
            onPressed: () {
              if (!ModalRoute.of(context)!.isCurrent) return;
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              ));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _KeyTile(
                    color: const Color(0xFF2E5339),
                    icon: Icons.bolt_rounded,
                    label: 'الأسرع',
                    onTap: () => _openExplanation(
                      context,
                      icon: Icons.bolt_rounded,
                      color: const Color(0xFF2E5339),
                      title: 'الأسرع يفوز',
                      steps: const [
                        'يدخل جميع اللاعبين نفس الغرفة، ويشوفون نفس السؤال بنفس اللحظة.',
                        'أول لاعب يجاوب صح ياخذ ١٠ نقاط كاملة، والي بعده أقل، وهكذا.',
                        'من يجاوب غلط أو ما يجاوب ما ياخذ نقاط على ذاك السؤال.',
                      ],
                      onStart: () => _openGroup(context, GroupScoringType.fastest),
                    ),
                  ),
                ),
                Container(width: 2, color: _darkBg),
                Expanded(
                  child: _KeyTile(
                    color: const Color(0xFF8A3B2B),
                    icon: Icons.timer_rounded,
                    label: 'الوقت',
                    onTap: () => _openExplanation(
                      context,
                      icon: Icons.timer_rounded,
                      color: const Color(0xFF8A3B2B),
                      title: 'سباق الوقت',
                      steps: const [
                        'يدخل جميع اللاعبين نفس الغرفة ويشوفون نفس السؤال بنفس اللحظة.',
                        'كل من يجاوب صح قبل انتهاء وقت السؤال (١٥ ثانية) ياخذ ١٠ نقاط كاملة.',
                        'ما فيه فرق بين الأول والأخير طالما جاوبوا ضمن الوقت.',
                      ],
                      onStart: () => _openGroup(context, GroupScoringType.timed),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 2, color: _darkBg),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _KeyTile(
                    color: const Color(0xFF5B3E7A),
                    icon: Icons.person_rounded,
                    label: 'فردي',
                    onTap: () => _openExplanation(
                      context,
                      icon: Icons.person_rounded,
                      color: const Color(0xFF5B3E7A),
                      title: 'اللعب الفردي',
                      steps: const [
                        'تلعب لحالك بدون منافسين.',
                        'كل سؤال له عداد وقت خاص فيه.',
                        'تشوف نتيجتك الكلية ووقتك في نهاية الجولة.',
                      ],
                      onStart: () => _openSolo(context),
                    ),
                  ),
                ),
                Container(width: 2, color: _darkBg),
                Expanded(
                  child: _KeyTile(
                    color: const Color(0xFFB98424),
                    icon: Icons.public_rounded,
                    label: 'أونلاين',
                    onTap: () => _openExplanation(
                      context,
                      icon: Icons.public_rounded,
                      color: const Color(0xFFB98424),
                      title: 'مجموعة عبر الإنترنت',
                      steps: const [
                        'أنشئ غرفة أو انضم لغرفة بكود مشترك من أي مكان.',
                        'اختر نظام النقاط (الأسرع يفوز أو سباق الوقت).',
                        'العب مع أصدقاءك حتى لو كل واحد بمكان مختلف.',
                      ],
                      onStart: () => _openGroup(context, null),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyTile extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _KeyTile({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Ink(
        color: color,
        child: SizedBox.expand(
          child: Stack(
            children: [
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), shape: BoxShape.circle),
                  child: const Icon(Icons.info_outline_rounded, size: 13, color: Colors.white),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 34),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
