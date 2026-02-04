import 'package:flutter/material.dart';

class GameTheme {
  const GameTheme({
    required this.name,
    required this.gradientColors,
    required this.boardColor,
    required this.gridColor,
    required this.accentColor,
  });

  final String name;
  final List<Color> gradientColors;
  final Color boardColor;
  final Color gridColor;
  final Color accentColor;
}

const Map<int, GameTheme> levelThemes = {
  1: GameTheme(
    name: 'Rainforest',
    gradientColors: [Color(0xFF0D324D), Color(0xFF7F5A83)],
    boardColor: Color(0xFF0D324D),
    gridColor: Color(0xFF4CAF50),
    accentColor: Color(0xFF81C784),
  ),
  5: GameTheme(
    name: 'Cyber-City',
    gradientColors: [Color(0xFF141E30), Color(0xFF243B55)],
    boardColor: Color(0xFF000000),
    gridColor: Color(0xFFE91E63),
    accentColor: Color(0xFF00FFF2),
  ),
  10: GameTheme(
    name: 'Deep Space',
    gradientColors: [Color(0xFF000428), Color(0xFF004E92)],
    boardColor: Color(0xFF000428),
    gridColor: Color(0xFF3F51B5),
    accentColor: Color(0xFF7986CB),
  ),
};

class GameLevel {
  const GameLevel({
    required this.levelNumber,
    required this.threshold,
    required this.tickRate,
    required this.numObstacles,
  });

  final int levelNumber;
  final int threshold; // Points to reach next level
  final Duration tickRate;
  final int numObstacles; // Number of obstacles for this level
}

List<GameLevel> generateLevels() {
  return List.generate(20, (i) {
    final level = i + 1;
    // Progressive obstacle count: 0 for level 1, then increases
    final obstacles = level == 1 ? 0 : (level - 1) * 2;
    return GameLevel(
      levelNumber: level,
      threshold: level * 100,
      tickRate: Duration(milliseconds: max(60, 200 - (level * 10))),
      numObstacles: obstacles,
    );
  });
}

int max(int a, int b) => a > b ? a : b;
