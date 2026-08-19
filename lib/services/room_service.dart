import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/sample_questions.dart';
import '../models/question.dart';

enum GroupScoringType { fastest, timed }

const int timedModeSeconds = 15;
const int fastestModeMaxSeconds = 20;

/// يدير غرف اللعب الجماعي عبر Firestore. جهاز المضيف هو المسؤول عن إغلاق
/// كل سؤال وحساب النقاط (لا توجد Cloud Functions في هذا الإصدار)، لذلك يجب
/// أن يبقى تطبيق المضيف مفتوحاً طوال المسابقة.
class RoomService {
  // late: تأجيل الوصول إلى FirebaseFirestore.instance حتى أول استخدام فعلي،
  // لأن الوصول إليه مبكراً (مثلاً بمجرد إنشاء RoomService) يرمي استثناء إذا
  // Firebase.initializeApp() ما استُدعي بعد — وهذا يصير دايماً قبل التحقق
  // من firebaseReady، فيسبب شاشة فارغة بدل رسالة "يحتاج إعداد Firebase".
  late final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _rand = Random();

  String _randomId(int length) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(length, (_) => chars[_rand.nextInt(chars.length)]).join();
  }

  /// معرّف اللاعب الحالي = uid تسجيل الدخول المجهول من Firebase Auth، حتى
  /// تقدر قواعد أمان Firestore تتحقق أن كل لاعب لا يكتب إلا على بياناته هو.
  /// لو تسجيل الدخول عند بدء التطبيق ما نجح (مثلاً مشكلة شبكة مؤقتة)، نعيد
  /// المحاولة هنا وقت الحاجة الفعلية بدل ما نمنع اللعب الجماعي بالكامل.
  Future<String> newPlayerId() async {
    var user = FirebaseAuth.instance.currentUser;
    user ??= (await FirebaseAuth.instance.signInAnonymously()).user;
    if (user == null) {
      throw StateError('تعذر تسجيل الدخول. تأكد من الاتصال بالإنترنت وحاول مرة أخرى.');
    }
    return user.uid;
  }

  Future<String> createRoom({
    required GroupScoringType scoringType,
    required Difficulty difficulty,
    required int questionCount,
    required String hostName,
    required String hostPlayerId,
    QuestionSection? section,
    required int questionSeconds,
  }) async {
    final pool = sampleQuestions
        .where((q) => q.difficulty == difficulty && (section == null || q.section == section))
        .toList()
      ..shuffle();
    final questionIds = pool.take(questionCount).map((q) => q.id).toList();

    String? code;
    for (var attempt = 0; attempt < 10 && code == null; attempt++) {
      final candidate = _randomId(5);
      final ref = _db.collection('rooms').doc(candidate);
      try {
        // معاملة (transaction) بدل قراءة ثم كتابة منفصلتين، حتى نمنع احتمال
        // -- ولو نادر -- يختار فيه جهازان نفس الكود بنفس اللحظة فيتكتب أحدهما
        // فوق الثاني.
        await _db.runTransaction((tx) async {
          final snap = await tx.get(ref);
          if (snap.exists) {
            throw _RoomCodeTakenException();
          }
          tx.set(ref, {
            'scoringType': scoringType.name,
            'difficulty': difficulty.name,
            'section': section?.name,
            'questionSeconds': questionSeconds,
            'status': 'lobby',
            'questionIds': questionIds,
            'currentIndex': -1,
            'currentQuestionStartedAt': null,
            'hostPlayerId': hostPlayerId,
            'createdAt': FieldValue.serverTimestamp(),
          });
        });
        code = candidate;
      } on _RoomCodeTakenException {
        continue;
      }
    }
    if (code == null) {
      throw Exception('تعذر إنشاء غرفة، حاول مرة أخرى.');
    }

    await joinRoom(code: code, playerId: hostPlayerId, name: hostName);
    return code;
  }

  Future<bool> roomExists(String code) async {
    final snap = await _db.collection('rooms').doc(code).get();
    return snap.exists;
  }

  Future<void> joinRoom({
    required String code,
    required String playerId,
    required String name,
  }) async {
    await _db.collection('rooms').doc(code).collection('players').doc(playerId).set({
      'name': name,
      'score': 0,
      'joinedAt': FieldValue.serverTimestamp(),
    });
  }

  /// يعلّم اللاعب أنه غادر الغرفة (بدون حذف وثيقته — Firestore ما يسمح
  /// بالحذف أصلاً). المستخدَم في watchPlayers لاستبعاده من قائمة اللاعبين
  /// النشطين وعدّاد "أجاب X من Y".
  Future<void> leaveRoom({required String code, required String playerId}) async {
    await _db.collection('rooms').doc(code).collection('players').doc(playerId).update({
      'left': true,
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchRoom(String code) {
    return _db.collection('rooms').doc(code).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPlayers(String code) {
    return _db.collection('rooms').doc(code).collection('players').orderBy('joinedAt').snapshots();
  }

  Future<void> startGame(String code) async {
    await _goToQuestion(code, 0);
  }

  Future<void> _goToQuestion(String code, int index) async {
    await _db.collection('rooms').doc(code).update({
      'status': 'playing',
      'currentIndex': index,
      'currentQuestionStartedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> submitAnswer({
    required String code,
    required int questionIndex,
    required String playerId,
    required int optionIndex,
    required bool correct,
  }) async {
    final ansRef =
        _db.collection('rooms').doc(code).collection('answers').doc('${questionIndex}_$playerId');
    final existing = await ansRef.get();
    if (existing.exists) return; // منع الإجابة المكررة على نفس السؤال
    await ansRef.set({
      'questionIndex': questionIndex,
      'playerId': playerId,
      'optionIndex': optionIndex,
      'correct': correct,
      'answeredAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAnswers(String code, int questionIndex) {
    return _db
        .collection('rooms')
        .doc(code)
        .collection('answers')
        .where('questionIndex', isEqualTo: questionIndex)
        .snapshots();
  }

  /// يُستدعى من جهاز المضيف فقط بعد انتهاء وقت السؤال الحالي: يحسب نقاط كل
  /// لاعب حسب نوع التسجيل، ثم ينتقل للسؤال التالي أو ينهي المسابقة.
  Future<void> closeQuestionAndScore({
    required String code,
    required int questionIndex,
    required GroupScoringType scoringType,
  }) async {
    final answersSnap = await _db
        .collection('rooms')
        .doc(code)
        .collection('answers')
        .where('questionIndex', isEqualTo: questionIndex)
        .get();

    final correctDocs = answersSnap.docs.where((d) => d.data()['correct'] == true).toList()
      ..sort((a, b) {
        final ta = a.data()['answeredAt'] as Timestamp?;
        final tb = b.data()['answeredAt'] as Timestamp?;
        if (ta == null || tb == null) return 0;
        return ta.compareTo(tb);
      });

    if (correctDocs.isNotEmpty) {
      final batch = _db.batch();
      if (scoringType == GroupScoringType.fastest) {
        for (int i = 0; i < correctDocs.length; i++) {
          final points = max(10 - i * 2, 2);
          final playerId = correctDocs[i].data()['playerId'] as String;
          final playerRef = _db.collection('rooms').doc(code).collection('players').doc(playerId);
          batch.update(playerRef, {'score': FieldValue.increment(points)});
        }
      } else {
        for (final doc in correctDocs) {
          final playerId = doc.data()['playerId'] as String;
          final playerRef = _db.collection('rooms').doc(code).collection('players').doc(playerId);
          batch.update(playerRef, {'score': FieldValue.increment(10)});
        }
      }
      await batch.commit();
    }

    final roomSnap = await _db.collection('rooms').doc(code).get();
    final questionIds = List<String>.from(roomSnap.data()!['questionIds'] as List);
    if (questionIndex >= questionIds.length - 1) {
      await _db.collection('rooms').doc(code).update({'status': 'finished'});
    } else {
      await _goToQuestion(code, questionIndex + 1);
    }
  }
}

class _RoomCodeTakenException implements Exception {}
