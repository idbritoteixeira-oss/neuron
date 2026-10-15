import 'package:flutter/material.dart';

class PigeonFab extends StatelessWidget {
  const PigeonFab({required this.primary, required this.onPressed, super.key});

  final Color primary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary,
      shape: const CircleBorder(),
      elevation: 5,
      shadowColor: primary.withValues(alpha: 0.4),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const SizedBox(
          width: 56,
          height: 56,
          child: Icon(Icons.person_add_outlined, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}
