import 'dart:math';

enum Difficulty { beginner, intermediate, hard }

extension DifficultyLabel on Difficulty {
  String get label {
    switch (this) {
      case Difficulty.beginner:
        return 'مبتدئ';
      case Difficulty.intermediate:
        return 'متوسط';
      case Difficulty.hard:
        return 'صعب';
    }
  }
}

/// أقسام بنك أسئلة قياس الثلاثة (القسم اللفظي من اختبار القدرات العامة).
enum QuestionSection { classification, analogy, completion }

extension QuestionSectionLabel on QuestionSection {
  String get label {
    switch (this) {
      case QuestionSection.classification:
        return 'التصنيف اللفظي';
      case QuestionSection.analogy:
        return 'التناظر اللفظي';
      case QuestionSection.completion:
        return 'إكمال الجمل';
    }
  }
}

class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;
  final Difficulty difficulty;
  final QuestionSection section;
  final String? explanation;

  const Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.difficulty,
    required this.section,
    this.explanation,
  });

  /// نسخة من السؤال بترتيب خيارات معاد خلطه، بحيث لا تكون الإجابة الصحيحة
  /// دائماً في نفس الموضع. الخلط ثابت (مبني على [id]) حتى يتفق كل اللاعبين
  /// في نفس الغرفة على نفس ترتيب الخيارات — نستخدم دالة هاش يدوية بدل
  /// String.hashCode لأن الأخيرة غير مضمونة تعطي نفس القيمة بين منصات
  /// تشغيل Dart المختلفة (موبايل مقابل ويب مثلاً).
  Question shuffled() {
    final order = List<int>.generate(options.length, (i) => i)..shuffle(Random(_stableSeed(id)));
    return Question(
      id: id,
      text: text,
      options: [for (final i in order) options[i]],
      correctIndex: order.indexOf(correctIndex),
      difficulty: difficulty,
      section: section,
      explanation: explanation,
    );
  }
}

/// دالة هاش بسيطة وثابتة (FNV-1a) تعطي نفس الرقم لنفس النص على أي منصة
/// تشغيل Dart، على عكس String.hashCode المدمجة.
int _stableSeed(String input) {
  var hash = 0x811c9dc5;
  for (final codeUnit in input.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}
