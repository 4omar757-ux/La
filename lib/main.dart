import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'services/firebase_status.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initFirebase();
  } catch (e, st) {
    debugPrint('Firebase init failed: $e\n$st');
  }
  runApp(const MasabaqaApp());
}

class MasabaqaApp extends StatelessWidget {
  const MasabaqaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ق',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6C5CE7),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
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
