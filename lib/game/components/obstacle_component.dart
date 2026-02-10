import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ObstacleComponent extends PositionComponent {
  final math.Point<int> gridPosition;
  final double cellSize;

  ObstacleComponent({
    required this.gridPosition,
    this.cellSize = 20.0,
  });

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(
      gridPosition.x * cellSize + 2,
      gridPosition.y * cellSize + 2,
      cellSize - 4,
      cellSize - 4,
    );

    // Draw a block-like obstacle
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      paint,
    );

    // Detail lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    canvas.drawRect(rect, linePaint);
  }
}
