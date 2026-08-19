import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/firebase_status.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // لا ننتظر (await) تهيئة Firebase هنا عمداً: هذا يتطلب اتصال شبكة وبدون
  // مهلة زمنية محددة (timeout)، فلو كانت الشبكة بطيئة أو غير مستقرة يبقى
  // التطبيق عالقاً على شاشة البداية للأبد لأن أول إطار (frame) ما يُرسم
  // إلا بعد ما يخلص هذا الاستدعاء. الآن runApp() يشتغل فوراً بغض النظر عن
  // حالة الشبكة، وتهيئة Firebase تصير بالخلفية (الوضع الجماعي أصلاً يتحمّل
  // تأخرها لأن RoomService.newPlayerId() يعيد محاولة تسجيل الدخول بنفسه).
  initFirebase().catchError((e, st) {
    debugPrint('Firebase init failed: $e\n$st');
  });
  runApp(const MasabaqaApp());
}

class MasabaqaApp extends StatelessWidget {
  const MasabaqaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ق',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const HomeScreen(),
    );
  }
}
