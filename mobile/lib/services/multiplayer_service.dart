import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/player_city_state.dart';

const int kMinPlayers = 2;
const int kMaxPlayers = 5;

class RoomInfo {
  final String code;
  final String cityId;
  final String status; // waiting | playing | finished
  final int durationMinutes;
  final DateTime? startedAt;
  final String hostPlayerId;

  RoomInfo({
    required this.code,
    required this.cityId,
    required this.status,
    required this.durationMinutes,
    required this.startedAt,
    required this.hostPlayerId,
  });

  DateTime? get endsAt =>
      startedAt?.add(Duration(minutes: durationMinutes));

  factory RoomInfo.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return RoomInfo(
      code: doc.id,
      cityId: data['cityId'] as String,
      status: data['status'] as String,
      durationMinutes: data['durationMinutes'] as int,
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      hostPlayerId: data['hostPlayerId'] as String,
    );
  }
}

class PlayerScore {
  final String playerId;
  final String name;
  final double gold;
  final double population;
  final double happiness;
  final double score;

  PlayerScore({
    required this.playerId,
    required this.name,
    required this.gold,
    required this.population,
    required this.happiness,
    required this.score,
  });

  factory PlayerScore.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PlayerScore(
      playerId: doc.id,
      name: data['name'] as String? ?? '?',
      gold: (data['gold'] as num?)?.toDouble() ?? 0,
      population: (data['population'] as num?)?.toDouble() ?? 0,
      happiness: (data['happiness'] as num?)?.toDouble() ?? 0,
      score: (data['score'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// إدارة غرف المتعدد لاعبين التنافسي عبر Firestore.
/// كل لاعب يبني في نسخته الخاصة من المدينة؛ فقط الإحصاءات (الذهب/السكان/النقاط)
/// تُزامن لحظيًا لعرض لوحة صدارة حية بين 2 إلى 5 لاعبين.
class MultiplayerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const _uuid = Uuid();

  CollectionReference<Map<String, dynamic>> get _rooms => _db.collection('rooms');

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // بدون أحرف/أرقام ملتبسة
    final rnd = Random();
    return List.generate(5, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  /// ينشئ غرفة جديدة ويضيف المضيف كأول لاعب. يرجع (roomCode, playerId).
  Future<(String, String)> createRoom({
    required String hostName,
    required String cityId,
    required int durationMinutes,
  }) async {
    String code = _generateRoomCode();
    // تفادي تصادم نادر لرمز الغرفة
    while ((await _rooms.doc(code).get()).exists) {
      code = _generateRoomCode();
    }
    final playerId = _uuid.v4();

    await _rooms.doc(code).set({
      'cityId': cityId,
      'status': 'waiting',
      'durationMinutes': durationMinutes,
      'startedAt': null,
      'hostPlayerId': playerId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _rooms.doc(code).collection('players').doc(playerId).set({
      'name': hostName,
      'gold': 1000,
      'population': 0,
      'happiness': 50,
      'score': 1000,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    return (code, playerId);
  }

  /// ينضم لاعب لغرفة موجودة برمزها. يرجع playerId، أو يرمي استثناء برسالة عربية.
  Future<String> joinRoom({required String roomCode, required String playerName}) async {
    final roomRef = _rooms.doc(roomCode.toUpperCase());
    final roomSnap = await roomRef.get();
    if (!roomSnap.exists) {
      throw Exception('ما في غرفة بهذا الرمز');
    }
    final data = roomSnap.data()!;
    if (data['status'] != 'waiting') {
      throw Exception('الجولة بدأت بالفعل، ما تقدر تنضم الحين');
    }

    final playersSnap = await roomRef.collection('players').get();
    if (playersSnap.size >= kMaxPlayers) {
      throw Exception('الغرفة مكتملة (أقصى $kMaxPlayers لاعبين)');
    }

    final playerId = _uuid.v4();
    await roomRef.collection('players').doc(playerId).set({
      'name': playerName,
      'gold': 1000,
      'population': 0,
      'happiness': 50,
      'score': 1000,
      'joinedAt': FieldValue.serverTimestamp(),
    });
    return playerId;
  }

  Future<void> startMatch(String roomCode) async {
    await _rooms.doc(roomCode).update({
      'status': 'playing',
      'startedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> finishMatch(String roomCode) async {
    await _rooms.doc(roomCode).update({'status': 'finished'});
  }

  Future<void> pushMyStats({
    required String roomCode,
    required String playerId,
    required PlayerCityState state,
  }) async {
    final derived = state.computeDerivedStats();
    await _rooms.doc(roomCode).collection('players').doc(playerId).update({
      'gold': state.gold,
      'population': state.population,
      'happiness': derived.happiness,
      'score': state.score,
    });
  }

  Stream<RoomInfo> watchRoom(String roomCode) {
    return _rooms.doc(roomCode).snapshots().map(RoomInfo.fromDoc);
  }

  Stream<List<PlayerScore>> watchLeaderboard(String roomCode) {
    return _rooms
        .doc(roomCode)
        .collection('players')
        .orderBy('score', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PlayerScore.fromDoc).toList());
  }

  Future<void> leaveRoom(String roomCode, String playerId) async {
    await _rooms.doc(roomCode).collection('players').doc(playerId).delete();
  }
}
