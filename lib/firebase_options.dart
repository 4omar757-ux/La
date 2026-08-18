import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// ملف إعدادات Firebase.
///
/// القيم الحالية أدناه هي قيم وهمية (placeholder) فقط، لذلك أوضاع الفرق
/// (١، ٢، ٤) لن تعمل حتى يتم استبدالها بقيم مشروع Firebase حقيقي.
/// شاهد FIREBASE_SETUP.md لخطوات إنشاء مشروع Firebase من الجوال.
///
/// بعد إنشاء المشروع، استبدل القيم أدناه بالقيم الفعلية من إعدادات تطبيقك
/// في Firebase Console (Project settings > Your apps).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    if (Platform.isAndroid) {
      return android;
    }
    if (Platform.isIOS) {
      return ios;
    }
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
    authDomain: 'REPLACE_ME',
    storageBucket: 'REPLACE_ME',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
    storageBucket: 'REPLACE_ME',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
    storageBucket: 'REPLACE_ME',
    iosBundleId: 'com.hijola.masabaqa',
  );
}
