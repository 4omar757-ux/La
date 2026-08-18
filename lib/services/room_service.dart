import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/sample_questions.dart';
import '../models/question.dart';

enum GroupScoringType { fastest, timed }

const int roomQuestionCount = 10;
const int timedModeSeconds = 15;
const int fastestModeMaxSeconds = 20;

/// يدير غرف اللعب الجماعي عبر Firestore. جهاز المضيف هو المسؤول عن إغلاق
/// كل سؤال وحساب النقاط (لا توجد Cloud Functions في هذا الإصدار)، لذلك يجب
/// أن يبقى تطبيق المضيف مفتوحاً طوال المسابقة.
class RoomService {
  final _db = FirebaseFirestore.instance;
  final _rand = Random();

  String _randomId(int length) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(length, (_) => chars[_rand.nextInt(chars.length)]).join();
  }

  String newPlayerId() => _randomId(12);

  Future<String> createRoom({
    required GroupScoringType scoringType,
    required Difficulty difficulty,
    required String hostName,
    required String hostPlayerId,
  }) async {
    final pool = sampleQuestions.where((q) => q.difficulty == difficulty).toList()..shuffle();
    final questionIds = pool.take(roomQuestionCount).map((q) => q.id).toList();

    String code = '';
    DocumentReference<Map<String, dynamic>>? ref;
    for (var attempt = 0; attempt < 10; attempt++) {
      code = _randomId(5);
      final candidate = _db.collection('rooms').doc(code);
      final snap = await candidate.get();
      if (!snap.exists) {
        ref = candidate;
        break;
      }
    }
    if (ref == null) {
      throw Exception('تعذر إنشاء غرفة، حاول مرة أخرى.');
    }

    await ref.set({
      'scoringType': scoringType.name,
      'difficulty': difficulty.name,
      'status': 'lobby',
      'questionIds': questionIds,
      'currentIndex': -1,
      'currentQuestionStartedAt': null,
      'hostPlayerId': hostPlayerId,
      'createdAt': FieldValue.serverTimestamp(),
    });

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
