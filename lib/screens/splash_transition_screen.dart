import 'package:flutter/material.dart';
import 'home_screen.dart';

// نفس لون خلفية الأيقونة التكيّفية (adaptive_icon_background في
// pubspec.yaml) حتى تنسجم شاشة الانتقال هذي بصرياً مع شاشة النظام
// (splash) اللي تظهر أول ما يفتح المستخدم التطبيق (أندرويد ١٢+ يعرضها
// تلقائياً من أيقونة التطبيق قبل ما نقدر نتحكم فيها من Flutter)، فيصير
// الانتقال بينهم سلس بدل قطعة مفاجئة.
const _splashBg = Color(0xFFFFF7EA);

/// تُعرض فوق الشاشة الرئيسية مباشرة وتختفي بتلاشٍ هادئ بعد لحظة قصيرة،
/// فتعطي إحساس انتقال فاخر بدل قطع مفاجئ من شاشة بداية النظام للتطبيق.
class SplashTransitionScreen extends StatefulWidget {
  const SplashTransitionScreen({super.key});

  @override
  State<SplashTransitionScreen> createState() => _SplashTransitionScreenState();
}

class _SplashTransitionScreenState extends State<SplashTransitionScreen> {
  bool _fadeOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) setState(() => _fadeOut = true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const HomeScreen(),
        IgnorePointer(
          ignoring: _fadeOut,
          child: AnimatedOpacity(
            opacity: _fadeOut ? 0 : 1,
            duration: const Duration(milliseconds: 750),
            curve: Curves.easeOut,
            child: Container(
              color: _splashBg,
              child: Center(
                child: AnimatedScale(
                  scale: _fadeOut ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 750),
                  curve: Curves.easeOut,
                  child: Image.asset('assets/branding/qaf_logo.png', width: 140),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
