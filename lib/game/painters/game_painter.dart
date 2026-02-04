import 'dart:math';
import 'package:flutter/material.dart';
import '../models/direction.dart';
import '../models/snake_skin.dart';
import '../models/obstacle.dart';
import '../models/game_item.dart';

class GamePainter extends CustomPainter {
  const GamePainter({
    required this.rows,
    required this.cols,
    required this.snake,
    required this.items,
    required this.skin,
    required this.direction,
    required this.isBulletTime,
    required this.isInvisible,
    required this.obstacles,
  });

  final int rows;
  final int cols;
  final List<Point<int>> snake;
  final List<GameItem> items;
  final SnakeSkin skin;
  final Direction direction;
  final bool isBulletTime;
  final bool isInvisible;
  final List<Obstacle> obstacles;

  @override
  void paint(Canvas canvas, Size size) {
    if (snake.isEmpty) return;

    final double cellWidth = size.width / cols;
    final double cellHeight = size.height / rows;

    _drawObstacles(canvas, cellWidth, cellHeight);
    _drawItems(canvas, cellWidth, cellHeight);

    // Apply transparency if invisible
    if (isInvisible) {
      canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.white.withOpacity(0.4));
    }

    if (skin.symmetry == SnakeSymmetry.laser) {
      _drawLaserSnake(canvas, cellWidth, cellHeight);
    } else {
      _draw3DSphereSnake(canvas, cellWidth, cellHeight);
    }

    if (isInvisible) {
      canvas.restore();
    }
  }

  void _drawObstacles(Canvas canvas, double w, double h) {
    for (final obstacle in obstacles) {
      final center = Offset(obstacle.position.y * w + w / 2, obstacle.position.x * h + h / 2);
      
      if (obstacle.type == ObstacleType.bomb) {
        // Draw bomb
        final bombPaint = Paint()
          ..shader = RadialGradient(
            colors: [Colors.red.shade300, Colors.red.shade900],
            stops: const [0.3, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: w * 0.4));
        
        canvas.drawCircle(center, w * 0.35, bombPaint);
        
        // Fuse
        final fusePaint = Paint()
          ..color = Colors.orange
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          center + Offset(-w * 0.15, -w * 0.3),
          center + Offset(-w * 0.15, -w * 0.5),
          fusePaint,
        );
      } else {
        // Draw wall
        final wallPaint = Paint()
          ..shader = LinearGradient(
            colors: [Colors.grey.shade700, Colors.grey.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Rect.fromLTWH(
            obstacle.position.y * w,
            obstacle.position.x * h,
            w,
            h,
          ));
        
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            obstacle.position.y * w + w * 0.05,
            obstacle.position.x * h + h * 0.05,
            w * 0.9,
            h * 0.9,
          ),
          Radius.circular(w * 0.1),
        );
        
        canvas.drawRRect(rect, wallPaint);
        
        // Border highlight
        canvas.drawRRect(
          rect,
          Paint()
            ..color = Colors.white.withOpacity(0.2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
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

  void _drawItems(Canvas canvas, double w, double h) {
    for (final item in items) {
      final center = Offset(item.position.y * w + w / 2, item.position.x * h + h / 2);
      
      switch (item.type) {
        case ItemType.food:
           _drawFood(canvas, center, w, h);
           break;
        case ItemType.coin:
           _drawCoin(canvas, center, w, h);
           break;
        case ItemType.booster:
           _drawBooster(canvas, center, w, h);
           break;
        case ItemType.lifeSaver:
           _drawLifeSaver(canvas, center, w, h);
           break;
      }
    }
  }

  void _drawFood(Canvas canvas, Offset center, double w, double h) {
    // Stem
    final stemPaint = Paint()
      ..color = Colors.brown
      ..strokeWidth = 2;
    canvas.drawLine(center + Offset(0, -w * 0.2), center + Offset(w * 0.1, -w * 0.45), stemPaint);
    
    // Leaf
    final leafPaint = Paint()..color = Colors.green;
    final leafPath = Path();
    leafPath.moveTo(center.dx + w * 0.05, center.dy - w * 0.35);
    leafPath.quadraticBezierTo(center.dx + w * 0.25, center.dy - w * 0.5, center.dx + w * 0.05, center.dy - w * 0.45);
    leafPath.close();
    canvas.drawPath(leafPath, leafPaint);

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.redAccent, Colors.red, Colors.red.shade900],
        stops: [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: w * 0.4));
    
    canvas.drawCircle(center, w * 0.35, paint);
    
    // Highlight
    canvas.drawCircle(center + Offset(-w * 0.1, -w * 0.1), w * 0.08, Paint()..color = Colors.white.withOpacity(0.4));
  }

  void _drawCoin(Canvas canvas, Offset center, double w, double h) {
    // Outer rim
    canvas.drawCircle(center, w * 0.42, Paint()
      ..shader = LinearGradient(
        colors: [Colors.yellow.shade200, Colors.yellow.shade800],
      ).createShader(Rect.fromCircle(center: center, radius: w * 0.42)));

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.yellow.shade100, Colors.yellow.shade600, Colors.orange.shade900],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: w * 0.35));

    canvas.drawCircle(center, w * 0.35, paint);
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: r'$',
        style: TextStyle(
          color: Colors.white,
          fontSize: w * 0.5,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(blurRadius: 4, color: Colors.orange.shade900)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  void _drawBooster(Canvas canvas, Offset center, double w, double h) {
    // Hexagonal background for "Tech" feel
    final hexPath = Path();
    for (int i = 0; i < 6; i++) {
        double angle = i * pi / 3;
        double radius = w * 0.45;
        Offset p = center + Offset(radius * cos(angle), radius * sin(angle));
        if (i == 0) hexPath.moveTo(p.dx, p.dy); else hexPath.lineTo(p.dx, p.dy);
    }
    hexPath.close();
    
    canvas.drawPath(hexPath, Paint()
      ..shader = LinearGradient(colors: [Colors.blue, Colors.deepPurple]).createShader(Rect.fromCircle(center: center, radius: w * 0.5))
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4));

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.cyanAccent, Colors.blue.shade600, Colors.blue.shade900],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: w * 0.4));

    canvas.drawPath(hexPath, paint);
    
    // Glow
    canvas.drawCircle(center, w * 0.55, Paint()
      ..color = Colors.cyan.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15));
    
    // Bolt icon
    final bolt = Path();
    bolt.moveTo(center.dx + w * 0.1, center.dy - w * 0.25);
    bolt.lineTo(center.dx - w * 0.15, center.dy + w * 0.05);
    bolt.lineTo(center.dx + w * 0.05, center.dy + w * 0.05);
    bolt.lineTo(center.dx - w * 0.1, center.dy + w * 0.35);
    bolt.lineTo(center.dx + w * 0.15, center.dy - w * 0.05);
    bolt.lineTo(center.dx - w * 0.05, center.dy - w * 0.05);
    bolt.close();
    canvas.drawPath(bolt, Paint()..color = Colors.white);
  }

  void _drawLifeSaver(Canvas canvas, Offset center, double w, double h) {
    // Double pulse ring
    canvas.drawCircle(center, w * 0.48, Paint()
      ..color = Colors.pinkAccent.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white, Colors.pink.shade300, Colors.red.shade900],
        stops: const [0.0, 0.3, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: w * 0.4));

    canvas.drawCircle(center, w * 0.38, paint);
    
    // Heart icon (more polished)
    final heartPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center + Offset(-w * 0.11, -w * 0.08), w * 0.13, heartPaint);
    canvas.drawCircle(center + Offset(w * 0.11, -w * 0.08), w * 0.13, heartPaint);
    final tri = Path();
    tri.moveTo(center.dx - w * 0.23, center.dy + w * 0.02);
    tri.lineTo(center.dx + w * 0.23, center.dy + w * 0.02);
    tri.lineTo(center.dx, center.dy + w * 0.32);
    tri.close();
    canvas.drawPath(tri, heartPaint);
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) => true;
}
