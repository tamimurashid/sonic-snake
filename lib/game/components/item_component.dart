import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../models/game_item.dart';
import '../sonic_snake_game.dart';

class ItemComponent extends PositionComponent with HasGameRef<SonicSnakeGame> {
  math.Point<int> gridPosition;
  final double cellSize;
  final ItemType type;
  double _pulseTimer = 0;

  ItemComponent({
    required this.gridPosition,
    required this.type,
    this.cellSize = 20.0,
  });

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTimer += dt * 5;
  }

  @override
  void render(Canvas canvas) {
    final Color color;
    switch (type) {
      case ItemType.food:
        color = Colors.redAccent;
        break;
      case ItemType.coin:
        color = Colors.amberAccent;
        break;
      case ItemType.booster:
        color = Colors.cyanAccent;
        break;
      case ItemType.lifeSaver:
        color = Colors.pinkAccent;
        break;
    }

    final pulse = math.sin(_pulseTimer) * 2;
    final center = Offset(
      gridPosition.x * cellSize + cellSize / 2,
      gridPosition.y * cellSize + cellSize / 2,
    );

    // Glow Effect
    final glowPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    canvas.drawCircle(center, (cellSize / 2) + pulse, glowPaint);

    final mainPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, (cellSize / 2 - 4) + pulse * 0.5, mainPaint);

    // Inner detail
    final detailPaint = Paint()..color = Colors.white.withOpacity(0.6);
    canvas.drawCircle(center, cellSize / 6, detailPaint);
  }
}
