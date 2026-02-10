import 'package:flutter/material.dart';

enum SnakeSymmetry { continuous, spheres, laser }

class SnakeSkin {
  const SnakeSkin({
    required this.id,
    required this.label,
    required this.headColor,
    required this.bodyColor,
    this.symmetry = SnakeSymmetry.spheres,
    this.price = 0,
    this.isLocked = true,
    this.glowColor,
    this.trailEffect = false,
  });

  final String id;
  final String label;
  final Color headColor;
  final Color bodyColor;
  final SnakeSymmetry symmetry;
  final int price;
  final bool isLocked;
  final Color? glowColor;
  final bool trailEffect;

  Gradient get headGradient => LinearGradient(
    colors: [headColor, headColor.withOpacity(0.8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  Gradient get bodyGradient => LinearGradient(
    colors: [bodyColor, bodyColor.withOpacity(0.7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

const List<SnakeSkin> snakeSkins = <SnakeSkin>[
  SnakeSkin(
    id: 'classic',
    label: 'Classic Blue',
    headColor: Color(0xFF3B82F6),
    bodyColor: Color(0xFF60A5FA),
    glowColor: Color(0xFF3B82F6),
    isLocked: false,
  ),
  SnakeSkin(
    id: 'gold',
    label: 'Sonic Gold',
    headColor: Color(0xFFFFD700),
    bodyColor: Color(0xFFDAA520),
    glowColor: Color(0xFFFFE135),
    price: 100,
  ),
  SnakeSkin(
    id: 'rainbow',
    label: 'Rainbow Trail',
    headColor: Color(0xFFE91E63),
    bodyColor: Color(0xFF2196F3),
    glowColor: Color(0xFFFF00FF),
    trailEffect: true,
    price: 250,
  ),
  SnakeSkin(
    id: 'ghost',
    label: 'Ghost Spec',
    headColor: Color(0xAAFFFFFF),
    bodyColor: Color(0x66FFFFFF),
    symmetry: SnakeSymmetry.laser,
    price: 500,
  ),
  SnakeSkin(
    id: 'laser',
    label: 'Laser Beam',
    headColor: Color(0xFF00FFF2),
    bodyColor: Color(0xFF00FF88),
    symmetry: SnakeSymmetry.laser,
    glowColor: Color(0xFF00FFF2),
    price: 1000,
  ),
];
