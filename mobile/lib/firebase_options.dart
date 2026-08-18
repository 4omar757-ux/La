// ملف تجريبي placeholder — استبدله بالملف الحقيقي الذي تولّده أداة FlutterFire.
//
// هذا المشروع يحتاج مشروع Firebase خاص بك لتفعيل اللعب الجماعي (Firestore).
// خطوات الإعداد (مرة واحدة فقط):
//   1) أنشئ مشروع على https://console.firebase.google.com
//   2) فعّل خدمة Cloud Firestore داخل المشروع (وضع الإنتاج أو التجريبي)
//   3) نفّذ من داخل مجلد mobile/:
//        dart pub global activate flutterfire_cli
//        flutterfire configure
//      اختر مشروع Firebase الذي أنشأته، وحدد منصة Android فقط.
//   4) الأمر أعلاه يستبدل هذا الملف تلقائيًا بالقيم الحقيقية لمشروعك.
//
// بدون هذه الخطوة، شاشة "لعب فردي" تعمل بشكل طبيعي، لكن "لعب جماعي" لن يتصل
// بأي خادم فعلي.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'هذا المشروع مُعدّ لأندرويد فقط حاليًا. شغّل flutterfire configure لإضافة الويب.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions لم تُعدّ لهذه المنصة بعد. شغّل flutterfire configure.',
        );
    }
  }

  // قيم مؤقتة placeholder — استبدلها flutterfire configure تلقائيًا بقيم مشروعك الحقيقي.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
    appId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
    messagingSenderId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
    projectId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
    storageBucket: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
  );
}
