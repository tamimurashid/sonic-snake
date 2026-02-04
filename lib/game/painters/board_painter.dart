import 'package:flutter/material.dart';

class BoardPainter extends CustomPainter {
  const BoardPainter({
    required this.rows,
    required this.cols,
    required this.gridColor,
    required this.accentColor,
  });

  final int rows;
  final int cols;
  final Color gridColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor.withOpacity(0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = accentColor.withOpacity(0.1)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final double cellWidth = size.width / cols;
    final double cellHeight = size.height / rows;

    // Draw perspective-like grid lines or just glowing grid
    for (int i = 0; i <= rows; i++) {
      final y = i * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      if (i % 5 == 0) canvas.drawLine(Offset(0, y), Offset(size.width, y), glowPaint);
    }

    for (int i = 0; i <= cols; i++) {
      final x = i * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      if (i % 5 == 0) canvas.drawLine(Offset(x, 0), Offset(x, size.height), glowPaint);
    }
    
    // Vignette / Border glow
    final borderPaint = Paint()
      ..color = accentColor.withOpacity(0.3)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10);
      
    canvas.drawRect(Offset.zero & size, borderPaint);
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) => 
    oldDelegate.gridColor != gridColor || oldDelegate.accentColor != accentColor;
}
