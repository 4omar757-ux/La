import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';

const String _statsKey = 'section_stats';

class SectionStats {
  final int correct;
  final int total;
  const SectionStats({this.correct = 0, this.total = 0});

  double get percent => total == 0 ? 0 : correct / total;
}

/// إحصائيات محلية بسيطة (بدون سيرفر) لأداء اللاعب بكل قسم من أقسام قياس
/// الثلاثة في الوضع الفردي، حتى يعرف وين نقطة ضعفه.
class SectionStatsService {
  SectionStatsService._();
  static final SectionStatsService instance = SectionStatsService._();

  Future<void> recordAnswer({required QuestionSection section, required bool correct}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = await _readAll(prefs);
      final current = map[section] ?? const SectionStats();
      map[section] = SectionStats(
        correct: current.correct + (correct ? 1 : 0),
        total: current.total + 1,
      );
      await _writeAll(prefs, map);
    } catch (_) {
      // تجاهل فشل الحفظ؛ ما يعطل اللعب.
    }
  }

  Future<Map<QuestionSection, SectionStats>> all() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await _readAll(prefs);
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeAll(SharedPreferences prefs, Map<QuestionSection, SectionStats> map) async {
    final encoded = <String, dynamic>{
      for (final entry in map.entries)
        entry.key.name: {'correct': entry.value.correct, 'total': entry.value.total},
    };
    await prefs.setString(_statsKey, jsonEncode(encoded));
  }

  Future<Map<QuestionSection, SectionStats>> _readAll(SharedPreferences prefs) async {
    final raw = prefs.getString(_statsKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final result = <QuestionSection, SectionStats>{};
      for (final entry in decoded.entries) {
        final section = QuestionSection.values.byName(entry.key);
        final v = entry.value as Map<String, dynamic>;
        result[section] = SectionStats(correct: v['correct'] as int, total: v['total'] as int);
      }
      return result;
    } catch (_) {
      return {};
    }
  }
}
