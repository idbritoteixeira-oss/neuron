import 'package:flutter/material.dart';

import '../../../core/enxos/enxos_theme.dart';
import '../models/pigeon_models.dart';

class PigeonAvatar extends StatelessWidget {
  const PigeonAvatar({
    required this.profile,
    required this.primary,
    required this.palette,
    this.radius = 21,
    this.showOnline = false,
    this.useVerificationFallback = false,
    super.key,
  });

  final PigeonProfile profile;
  final Color primary;
  final EnxosPalette palette;
  final double radius;
  final bool showOnline;
  final bool useVerificationFallback;

  @override
  Widget build(BuildContext context) {
    final fallbackColor = useVerificationFallback
        ? _verificationColor(profile.verification)
        : palette.borderAvatar;
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: fallbackColor,
      backgroundImage: profile.avatarUrl == null
          ? null
          : NetworkImage(profile.avatarUrl!),
      child: profile.avatarUrl == null
          ? Text(
              profile.initial,
              style: TextStyle(
                color: useVerificationFallback
                    ? Colors.white
                    : palette.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.68,
              ),
            )
          : null,
    );
    if (!showOnline || !profile.isOnline) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: primary,
              shape: BoxShape.circle,
              border: Border.all(color: palette.card, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Color _verificationColor(PigeonVerification verification) =>
      switch (verification) {
        PigeonVerification.blue => const Color(0xFF1D9BF0),
        PigeonVerification.system => const Color(0xFF8C9BAB),
        PigeonVerification.none => primary,
      };
}
