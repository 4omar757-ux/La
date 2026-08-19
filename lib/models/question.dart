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

class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctIndex;
  final Difficulty difficulty;
  final String? explanation;

  const Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.difficulty,
    this.explanation,
  });

  /// نسخة من السؤال بترتيب خيارات معاد خلطه، بحيث لا تكون الإجابة الصحيحة
  /// دائماً في نفس الموضع. الخلط ثابت (مبني على [id]) حتى يتفق كل اللاعبين
  /// في نفس الغرفة على نفس ترتيب الخيارات.
  Question shuffled() {
    final order = List<int>.generate(options.length, (i) => i)..shuffle(Random(id.hashCode));
    return Question(
      id: id,
      text: text,
      options: [for (final i in order) options[i]],
      correctIndex: order.indexOf(correctIndex),
      difficulty: difficulty,
      explanation: explanation,
    );
  }
}
