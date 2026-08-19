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
}
