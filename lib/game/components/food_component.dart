import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class FoodComponent extends PositionComponent {
  math.Point<int> gridPosition;
  final double cellSize;
  final Color color;

  FoodComponent({
    required this.gridPosition,
    this.cellSize = 20.0,
    this.color = Colors.redAccent,
  });

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    canvas.drawCircle(
      Offset(gridPosition.x * cellSize + cellSize / 2, gridPosition.y * cellSize + cellSize / 2),
      cellSize / 2 - 2,
      paint,
    );

    // Inner glow
    final innerPaint = Paint()..color = Colors.white.withOpacity(0.8);
    canvas.drawCircle(
      Offset(gridPosition.x * cellSize + cellSize / 2, gridPosition.y * cellSize + cellSize / 2),
      cellSize / 4,
      innerPaint,
    );
  }
}
