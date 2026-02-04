import 'package:flutter/material.dart';

class BackgroundTheme {
  const BackgroundTheme({
    required this.label,
    required this.gradientColors,
    required this.boardColor,
    this.gridColor = Colors.white10,
  });

  final String label;
  final List<Color> gradientColors;
  final Color boardColor;
  final Color gridColor;
}

const List<BackgroundTheme> backgrounds = <BackgroundTheme>[
  BackgroundTheme(
    label: 'Neon Night',
    gradientColors: <Color>[
      Color(0xFF0F172A),
      Color(0xFF111827),
      Color(0xFF1E293B),
    ],
    boardColor: Color(0xFF0B1220),
    gridColor: Color(0xFF1E293B),
  ),
  BackgroundTheme(
    label: 'Cyberpunk',
    gradientColors: <Color>[
      Color(0xFF1A0B2E),
      Color(0xFF2E0B1A),
    ],
    boardColor: Color(0xFF12061A),
    gridColor: Color(0xFFE91E63),
  ),
  BackgroundTheme(
    label: 'Aurora',
    gradientColors: <Color>[
      Color(0xFF0F172A),
      Color(0xFF0B2F3A),
      Color(0xFF1B3B5A),
    ],
    boardColor: Color(0xFF0A1C2A),
    gridColor: Color(0xFF2DD4BF),
  ),
  BackgroundTheme(
    label: 'Deep Sea',
    gradientColors: <Color>[
      Color(0xFF061621),
      Color(0xFF0A2B4E),
    ],
    boardColor: Color(0xFF04101A),
    gridColor: Color(0xFF00D1FF),
  ),
];
