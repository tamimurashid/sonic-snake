import 'package:flutter/material.dart';

class BoardPainter extends CustomPainter {
  const BoardPainter({
    required this.rows,
    required this.cols,
    required this.gridColor,
    required this.accentColor,
    this.style = 'cyber',
  });

  final int rows;
  final int cols;
  final Color gridColor;
  final Color accentColor;
  final String style;

  @override
  void paint(Canvas canvas, Size size) {
    if (style == 'matrix') {
      _drawMatrixGrid(canvas, size);
      return;
    }

    final paint = Paint()
      ..color = gridColor.withOpacity(style == 'neon' ? 0.3 : 0.2)
      ..strokeWidth = style == 'neon' ? 1.5 : 1.0
      ..style = PaintingStyle.stroke;

    final double cellWidth = size.width / cols;
    final double cellHeight = size.height / rows;

    if (style != 'classic') {
      final glowPaint = Paint()
        ..color = accentColor.withOpacity(0.1)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

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
    } else {
      // Classic simple grid
      for (int i = 0; i <= rows; i++) {
        final y = i * cellHeight;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
      for (int i = 0; i <= cols; i++) {
        final x = i * cellWidth;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
    }
    
    // Vignette / Border glow
    final borderPaint = Paint()
      ..color = accentColor.withOpacity(0.3)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10);
      
    canvas.drawRect(Offset.zero & size, borderPaint);
  }

  void _drawMatrixGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.15)
      ..strokeWidth = 1.0;

    final double cellWidth = size.width / cols;
    final double cellHeight = size.height / rows;

    for (int i = 0; i <= rows; i++) {
      final y = i * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (int i = 0; i <= cols; i++) {
      final x = i * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Add some "bit" highlights
    final bitPaint = Paint()..color = Colors.green.withOpacity(0.3);
    for (int i = 0; i < 20; i++) {
      final r = (i * 7) % rows;
      final c = (i * 3) % cols;
      canvas.drawRect(
        Rect.fromLTWH(c * cellWidth + 2, r * cellHeight + 2, cellWidth - 4, cellHeight - 4),
        bitPaint,
      );
    }
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) => 
    oldDelegate.gridColor != gridColor || 
    oldDelegate.accentColor != accentColor || 
    oldDelegate.style != style;
}
