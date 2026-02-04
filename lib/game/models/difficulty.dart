enum Difficulty {
  easy,
  medium,
  hard,
  extreme,
  insane,
  sonic,
}

extension DifficultyExtension on Difficulty {
  String get name {
    switch (this) {
      case Difficulty.easy: return 'Easy';
      case Difficulty.medium: return 'Medium';
      case Difficulty.hard: return 'Hard';
      case Difficulty.extreme: return 'Extreme';
      case Difficulty.insane: return 'Insane';
      case Difficulty.sonic: return 'Sonic';
    }
  }

  double get speedMultiplier {
    switch (this) {
      case Difficulty.easy: return 0.8;
      case Difficulty.medium: return 1.0;
      case Difficulty.hard: return 1.25;
      case Difficulty.extreme: return 1.6;
      case Difficulty.insane: return 2.0;
      case Difficulty.sonic: return 2.5;
    }
  }
}
