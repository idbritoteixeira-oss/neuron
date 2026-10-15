import 'package:flutter/material.dart';

import '../models/pigeon_models.dart';

/// Cores iguais às usadas por renderizarSelo() na versão web.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({required this.verification, this.size = 15, super.key});

  final PigeonVerification verification;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = switch (verification) {
      PigeonVerification.blue => const Color(0xFF1D9BF0),
      PigeonVerification.system => const Color(0xFF8C9BAB),
      PigeonVerification.none => null,
    };
    if (color == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Icon(Icons.check_circle, color: color, size: size),
    );
  }
}
