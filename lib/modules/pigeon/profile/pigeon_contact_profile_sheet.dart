import 'package:flutter/material.dart';

import '../../../core/enxos/enxos_theme.dart';
import '../models/pigeon_models.dart';
import '../widgets/pigeon_avatar.dart';
import '../widgets/verified_badge.dart';

class PigeonContactProfileSheet extends StatelessWidget {
  const PigeonContactProfileSheet({
    required this.profile,
    required this.primary,
    required this.palette,
    super.key,
  });

  final PigeonProfile profile;
  final Color primary;
  final EnxosPalette palette;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PigeonAvatar(
              profile: profile,
              primary: primary,
              palette: palette,
              radius: 42,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    profile.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                VerifiedBadge(verification: profile.verification, size: 18),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Pigeon ID: ${profile.id}',
              style: TextStyle(color: palette.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            _InfoCard(
              label: 'Visto por último',
              value: profile.isOnline
                  ? 'Online'
                  : (profile.lastSeen ?? 'Status indisponível'),
              palette: palette,
            ),
            const SizedBox(height: 8),
            _InfoCard(
              label: 'Biografia',
              value: profile.bio.isEmpty
                  ? 'Sem biografia disponível.'
                  : profile.bio,
              palette: palette,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.label,
    required this.value,
    required this.palette,
  });

  final String label;
  final String value;
  final EnxosPalette palette;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: palette.input,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: palette.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: palette.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: palette.textPrimary, fontSize: 14)),
      ],
    ),
  );
}
