import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MusicVisualizer extends StatefulWidget {
  final bool isPlaying;
  final Color color;

  const MusicVisualizer({
    super.key,
    required this.isPlaying,
    required this.color,
  });

  @override
  State<MusicVisualizer> createState() => _MusicVisualizerState();
}

class _MusicVisualizerState extends State<MusicVisualizer> with SingleTickerProviderStateMixin {
  final Random _random = Random();
  final List<_Particle> _particles = [];
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Loop duration
    )..repeat();
    
    _controller.addListener(_updateParticles);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateParticles() {
    if (!widget.isPlaying) {
      if (_particles.isNotEmpty) {
        setState(() {
          _particles.clear();
        });
      }
      return;
    }

    // Spawn new particles occasionally
    if (_random.nextDouble() < 0.15) { // Spawn rate
      // Determine side (0=top, 1=bottom, 2=left, 3=right)
      // We want to avoid the center area roughly.
      // So we spawn at edges and move inward but fade out before center.
      
      final side = _random.nextInt(4);
      double x, y, dx, dy;
      
      switch (side) {
        case 0: // Top
          x = _random.nextDouble();
          y = 0.0;
          dx = (_random.nextDouble() - 0.5) * 0.01;
          dy = _random.nextDouble() * 0.02; // Move down
          break;
        case 1: // Bottom
          x = _random.nextDouble();
          y = 1.0;
          dx = (_random.nextDouble() - 0.5) * 0.01;
          dy = -_random.nextDouble() * 0.02; // Move up
          break;
        case 2: // Left
          x = 0.0;
          y = _random.nextDouble();
          dx = _random.nextDouble() * 0.02; // Move right
          dy = (_random.nextDouble() - 0.5) * 0.01;
          break;
        case 3: // Right
        default:
          x = 1.0;
          y = _random.nextDouble();
          dx = -_random.nextDouble() * 0.02; // Move left
          dy = (_random.nextDouble() - 0.5) * 0.01;
          break;
      }

      _particles.add(_Particle(
        x: x,
        y: y,
        dx: dx,
        dy: dy,
        life: 1.0,
        size: _random.nextDouble() * 8 + 2,
        color: widget.color.withOpacity(_random.nextDouble() * 0.5 + 0.2),
      ));
    }

    // Update existing particles
    setState(() {
      for (var p in _particles) {
        p.x += p.dx;
        p.y += p.dy;
        p.life -= 0.02; // Decay
      }
      _particles.removeWhere((p) => p.life <= 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPlaying) return const SizedBox.shrink();

    return IgnorePointer(
      child: CustomPaint(
        painter: _ParticlePainter(_particles),
        size: Size.infinite,
      ),
    );
  }
}

class _Particle {
  double x, y;
  double dx, dy;
  double life;
  double size;
  Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.life,
    required this.size,
    required this.color,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;

  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()
        ..color = p.color.withOpacity(p.color.opacity * p.life)
        ..style = PaintingStyle.fill;

      // Draw particle relative to screen size
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size * p.life, // Shrink as it dies
        paint,
      );
      
      // Draw glow
      final glowPaint = Paint()
        ..color = p.color.withOpacity(p.color.opacity * p.life * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
        
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size * 2 * p.life,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
