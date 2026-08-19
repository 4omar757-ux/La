import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';

const String _historyKey = 'solo_score_history';
const int _maxEntries = 50;

class ScoreHistoryEntry {
  final Difficulty difficulty;
  final int score;
  final int total;
  final DateTime playedAt;

  const ScoreHistoryEntry({
    required this.difficulty,
    required this.score,
    required this.total,
    required this.playedAt,
  });

  double get percent => total == 0 ? 0 : score / (total * 10);

  Map<String, dynamic> toJson() => {
        'difficulty': difficulty.name,
        'score': score,
        'total': total,
        'playedAt': playedAt.toIso8601String(),
      };

  static ScoreHistoryEntry fromJson(Map<String, dynamic> j) => ScoreHistoryEntry(
        difficulty: Difficulty.values.byName(j['difficulty'] as String),
        score: j['score'] as int,
        total: j['total'] as int,
        playedAt: DateTime.parse(j['playedAt'] as String),
      );
}

/// سجل محلي بسيط لنتائج الوضع الفردي (بدون حساب أو سيرفر)، حتى يقدر
/// اللاعب يشوف أفضل نتيجة له بكل مستوى صعوبة.
class ScoreHistoryService {
  ScoreHistoryService._();
  static final ScoreHistoryService instance = ScoreHistoryService._();

  Future<void> addResult({required Difficulty difficulty, required int score, required int total}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await _readAll(prefs);
      list.add(ScoreHistoryEntry(difficulty: difficulty, score: score, total: total, playedAt: DateTime.now()));
      final trimmed = list.length > _maxEntries ? list.sublist(list.length - _maxEntries) : list;
      await prefs.setString(_historyKey, jsonEncode(trimmed.map((e) => e.toJson()).toList()));
    } catch (_) {
      // تجاهل فشل الحفظ؛ ما يعطل عرض النتيجة الحالية.
    }
  }

  /// أفضل نسبة نجاح مسجّلة لهذا المستوى، أو null لو ما فيه سجل بعد.
  Future<ScoreHistoryEntry?> bestFor(Difficulty difficulty) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await _readAll(prefs);
      final matching = list.where((e) => e.difficulty == difficulty);
      if (matching.isEmpty) return null;
      return matching.reduce((a, b) => b.percent > a.percent ? b : a);
    } catch (_) {
      return null;
    }
  }

  Future<List<ScoreHistoryEntry>> _readAll(SharedPreferences prefs) async {
    final raw = prefs.getString(_historyKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => ScoreHistoryEntry.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
