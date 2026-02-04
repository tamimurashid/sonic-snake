import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/direction.dart';

class ControlPad extends StatelessWidget {
  const ControlPad({super.key, required this.onDirection});

  final ValueChanged<Direction> onDirection;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.02),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 2),
      ),
      child: Stack(
        children: [
          // Up
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: _ControlButton(
                icon: Icons.keyboard_arrow_up_rounded,
                onPressed: () => onDirection(Direction.up),
              ),
            ),
          ),
          // Left
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: _ControlButton(
                icon: Icons.keyboard_arrow_left_rounded,
                onPressed: () => onDirection(Direction.left),
              ),
            ),
          ),
          // Right
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: _ControlButton(
                icon: Icons.keyboard_arrow_right_rounded,
                onPressed: () => onDirection(Direction.right),
              ),
            ),
          ),
          // Down
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: _ControlButton(
                icon: Icons.keyboard_arrow_down_rounded,
                onPressed: () => onDirection(Direction.down),
              ),
            ),
          ),
          // Center indicator
          Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withOpacity(0.3),
                border: Border.all(color: Colors.blueAccent, width: 2),
              ),
            ),
          ),
        ],
      ),
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
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(20),
              splashColor: Colors.blueAccent.withOpacity(0.3),
              child: Center(
                child: Icon(
                  icon,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
