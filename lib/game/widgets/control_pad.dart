import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/direction.dart';

class ControlPad extends StatelessWidget {
  const ControlPad({super.key, required this.onDirection});

  final ValueChanged<Direction> onDirection;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _ControlButton(
          icon: Icons.keyboard_arrow_up,
          onPressed: () => onDirection(Direction.up),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _ControlButton(
              icon: Icons.keyboard_arrow_left,
              onPressed: () => onDirection(Direction.left),
            ),
            const SizedBox(width: 24),
            _ControlButton(
              icon: Icons.keyboard_arrow_right,
              onPressed: () => onDirection(Direction.right),
            ),
          ],
        ),
        _ControlButton(
          icon: Icons.keyboard_arrow_down,
          onPressed: () => onDirection(Direction.down),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: IconButton(
            onPressed: onPressed,
            iconSize: 36,
            style: IconButton.styleFrom(
              foregroundColor: Colors.white70,
              padding: const EdgeInsets.all(12),
            ),
            icon: Icon(icon),
          ),
        ),
      ),
    );
  }
}
