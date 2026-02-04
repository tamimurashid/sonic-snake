import 'dart:math' as math;

enum ObstacleType { wall, bomb }

class Obstacle {
  const Obstacle({
    required this.position,
    this.type = ObstacleType.wall,
  });

  final math.Point<int> position;
  final ObstacleType type;
}
