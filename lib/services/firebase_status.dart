import 'package:firebase_core/firebase_core.dart';
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
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    firebaseReady = true;
  } catch (_) {
    firebaseReady = false;
  }
}
