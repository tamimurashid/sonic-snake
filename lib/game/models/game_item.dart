import 'dart:math';
import 'package:flutter/material.dart';

enum ItemType {
  food,
  coin,
  booster,
  lifeSaver,
}

class GameItem {
  const GameItem({
    required this.position,
    required this.type,
    this.value = 1,
    this.duration,
  });

  final Point<int> position;
  final ItemType type;
  final int value; // For coins or extra lives
  final Duration? duration; // For boosters
}
