import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_options.dart';

/// يصير true إذا نجح الاتصال بمشروع Firebase حقيقي (بعد استبدال القيم في
/// firebase_options.dart). أوضاع اللعب الجماعي تعتمد على هذه القيمة لمعرفة
/// إذا كان بإمكانها الاتصال بالإنترنت للمزامنة الحية.
bool firebaseReady = false;

Future<void> initFirebase() async {
  try {
    if (DefaultFirebaseOptions.currentPlatform.apiKey == 'REPLACE_ME') {
      firebaseReady = false;
      return;
    }
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
        .timeout(const Duration(seconds: 15));
    firebaseReady = true;
  } catch (_) {
    firebaseReady = false;
    return;
  }

  // تسجيل الدخول المجهول (Anonymous) منفصل عمداً عن firebaseReady: لو فشل
  // هذا التسجيل (مثلاً مشكلة شبكة مؤقتة)، ما نبي هذا يخفي وضع اللعب
  // الجماعي بالكامل. لو ما نجح هنا، RoomService.newPlayerId() يعيد
  // المحاولة وقت الحاجة الفعلية (إنشاء/الانضمام لغرفة).
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously().timeout(const Duration(seconds: 15));
    }
  } catch (_) {
    // تجاهل هنا؛ newPlayerId() يعيد المحاولة لاحقاً.
  }
}
