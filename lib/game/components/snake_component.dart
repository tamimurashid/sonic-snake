import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../models/direction.dart';
import '../models/game_item.dart';
import '../models/snake_skin.dart';
import '../sonic_snake_game.dart';

class SnakeComponent extends PositionComponent {
  final List<math.Point<int>> body;
  Direction direction;
  final SnakeSkin skin;
  final double cellSize;

  SnakeComponent({
    required this.body,
    required this.direction,
    required this.skin,
    this.cellSize = 20.0,
  });

  math.Point<int> get head => body.first;

  void move(int gridWidth, int gridHeight) {
    final next = nextPosition(head, direction, gridWidth, gridHeight);
    body.insert(0, next);
    body.removeLast();
  }

  void grow(int gridWidth, int gridHeight) {
    final next = nextPosition(head, direction, gridWidth, gridHeight);
    body.insert(0, next);
  }

  math.Point<int> nextPosition(math.Point<int> current, Direction d, int gridWidth, int gridHeight) {
    switch (d) {
      case Direction.up: return math.Point(current.x, (current.y - 1 + gridHeight) % gridHeight);
      case Direction.down: return math.Point(current.x, (current.y + 1) % gridHeight);
      case Direction.left: return math.Point((current.x - 1 + gridWidth) % gridWidth, current.y);
      case Direction.right: return math.Point((current.x + 1) % gridWidth, current.y);
    }
  }

  bool checkCollision(int gridWidth, int gridHeight) {
    if (head.x < 0 || head.x >= gridWidth || head.y < 0 || head.y >= gridHeight) return true;
    for (int i = 1; i < body.length; i++) {
      if (body[i] == head) return true;
    }
    return false;
  }

  @override
  void render(Canvas canvas) {
    for (int i = 0; i < body.length; i++) {
      final p = body[i];
      final isHead = i == 0;
      final segmentSize = isHead ? cellSize : cellSize * 0.9;
      final offset = (cellSize - segmentSize) / 2;
      
      final paint = Paint()
        ..shader = (isHead ? skin.headGradient : skin.bodyGradient).createShader(
          Rect.fromLTWH(p.x * cellSize + offset, p.y * cellSize + offset, segmentSize, segmentSize),
        );

      // Add glow if skin has glowColor
      if (skin.glowColor != null) {
        final glowPaint = Paint()
          ..color = skin.glowColor!.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(p.x * cellSize + offset - 2, p.y * cellSize + offset - 2, segmentSize + 4, segmentSize + 4),
            const Radius.circular(8),
          ),
          glowPaint,
        );
      }

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(p.x * cellSize + offset + 1, p.y * cellSize + offset + 1, segmentSize - 2, segmentSize - 2),
          Radius.circular(isHead ? 8 : 4),
        ),
        paint,
      );
      
      if (isHead) {
        // Add "eyes"
        final eyePaint = Paint()..color = Colors.white;
        double eyeX1, eyeY1, eyeX2, eyeY2;
        
        switch (direction) {
          case Direction.up:
            eyeX1 = 0.3; eyeY1 = 0.2; eyeX2 = 0.7; eyeY2 = 0.2; break;
          case Direction.down:
            eyeX1 = 0.3; eyeY1 = 0.8; eyeX2 = 0.7; eyeY2 = 0.8; break;
          case Direction.left:
            eyeX1 = 0.2; eyeY1 = 0.3; eyeX2 = 0.2; eyeY2 = 0.7; break;
          case Direction.right:
            eyeX1 = 0.8; eyeY1 = 0.3; eyeX2 = 0.8; eyeY2 = 0.7; break;
        }

        canvas.drawCircle(
          Offset(p.x * cellSize + cellSize * eyeX1, p.y * cellSize + cellSize * eyeY1),
          2,
          eyePaint,
        );
        canvas.drawCircle(
          Offset(p.x * cellSize + cellSize * eyeX2, p.y * cellSize + cellSize * eyeY2),
          2,
          eyePaint,
        );
      }
    }
  }
}
