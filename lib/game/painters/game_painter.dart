import 'dart:math';
import 'package:flutter/material.dart';
import '../models/direction.dart';
import '../models/snake_skin.dart';

class GamePainter extends CustomPainter {
  const GamePainter({
    required this.rows,
    required this.cols,
    required this.snake,
    required this.food,
    required this.skin,
    required this.direction,
    required this.isBulletTime,
  });

  final int rows;
  final int cols;
  final List<Point<int>> snake;
  final Point<int> food;
  final SnakeSkin skin;
  final Direction direction;
  final bool isBulletTime;

  @override
  void paint(Canvas canvas, Size size) {
    if (snake.isEmpty) return;

    final double cellWidth = size.width / cols;
    final double cellHeight = size.height / rows;

    _drawFood(canvas, cellWidth, cellHeight);

    if (skin.symmetry == SnakeSymmetry.laser) {
      _drawLaserSnake(canvas, cellWidth, cellHeight);
    } else {
      _draw3DSphereSnake(canvas, cellWidth, cellHeight);
    }
  }

  void _draw3DSphereSnake(Canvas canvas, double w, double h) {
    for (int i = snake.length - 1; i >= 0; i--) {
      final p = snake[i];
      final center = Offset(p.y * w + w / 2, p.x * h + h / 2);
      final radius = (i == 0 ? w * 0.45 : w * 0.38);

      final color = i == 0 ? skin.headColor : skin.bodyColor;
      
      // 3D Shading effect (Radial Gradient)
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.8),
            color,
            color.withOpacity(0.5),
          ],
          stops: const [0.0, 0.4, 1.0],
          center: const Alignment(-0.3, -0.3),
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      if (skin.glowColor != null) {
        canvas.drawCircle(center, radius * 1.2, Paint()
          ..color = skin.glowColor!.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      }

      canvas.drawCircle(center, radius, paint);
      
      if (i == 0) _drawEyes(canvas, center, w, h);
    }
  }

  void _drawLaserSnake(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..color = skin.headColor
      ..strokeWidth = w * 0.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final glowPaint = Paint()
      ..color = skin.glowColor ?? skin.headColor
      ..strokeWidth = w * 0.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final path = Path();
    path.moveTo(snake.last.y * w + w / 2, snake.last.x * h + h / 2);
    for (int i = snake.length - 2; i >= 0; i--) {
      path.lineTo(snake[i].y * w + w / 2, snake[i].x * h + h / 2);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
    
    // Draw Head
    final head = snake.first;
    final headCenter = Offset(head.y * w + w / 2, head.x * h + h / 2);
    canvas.drawCircle(headCenter, w * 0.4, Paint()..color = skin.headColor);
    _drawEyes(canvas, headCenter, w, h);
  }

  void _drawEyes(Canvas canvas, Offset center, double w, double h) {
    final eyePaint = Paint()..color = Colors.white;
    final pupilPaint = Paint()..color = Colors.black;
    
    final eyeOffset = w * 0.15;
    final eyeRadius = w * 0.08;
    
    Offset e1, e2;
    if (direction == Direction.up || direction == Direction.down) {
      e1 = center + Offset(-eyeOffset, -eyeOffset * 0.5);
      e2 = center + Offset(eyeOffset, -eyeOffset * 0.5);
    } else {
      e1 = center + Offset(eyeOffset * 0.5, -eyeOffset);
      e2 = center + Offset(eyeOffset * 0.5, eyeOffset);
    }
    
    canvas.drawCircle(e1, eyeRadius, eyePaint);
    canvas.drawCircle(e2, eyeRadius, eyePaint);
    canvas.drawCircle(e1, eyeRadius * 0.5, pupilPaint);
    canvas.drawCircle(e2, eyeRadius * 0.5, pupilPaint);
  }

  void _drawFood(Canvas canvas, double w, double h) {
    final center = Offset(food.y * w + w / 2, food.x * h + h / 2);
    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [Colors.white, Colors.amber, Colors.orange],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: w * 0.4));
    
    canvas.drawCircle(center, w * 0.35, paint);
    canvas.drawCircle(center, w * 0.5, Paint()
      ..color = Colors.amber.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) => true;
}
