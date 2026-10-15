import 'package:flutter/material.dart';

import '../../../core/enxos/enxos_theme.dart';
import '../models/pigeon_models.dart';
import '../widgets/pigeon_avatar.dart';
import '../widgets/verified_badge.dart';

class ContactsTab extends StatelessWidget {
  const ContactsTab({
    required this.contacts,
    required this.primary,
    required this.palette,
    required this.onContactTap,
    super.key,
  });

  final List<PigeonProfile> contacts;
  final Color primary;
  final EnxosPalette palette;
  final ValueChanged<PigeonProfile> onContactTap;

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) {
      return Center(
        child: Text(
          'Nenhum contato encontrado.',
          style: TextStyle(color: palette.textSecondary, fontSize: 13),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: contacts.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: palette.border, indent: 64),
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          leading: PigeonAvatar(
            profile: contact,
            primary: primary,
            palette: palette,
            radius: 23,
            showOnline: true,
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  contact.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              VerifiedBadge(verification: contact.verification),
              if (contact.isBlocked) ...[
                const SizedBox(width: 6),
                Text(
                  'Bloqueado',
                  style: TextStyle(
                    color: palette.badgeMessage,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(
            contact.bio.isEmpty ? 'ID: ${contact.id}' : contact.bio,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: palette.textSecondary, fontSize: 13),
          ),
          trailing: Icon(
            Icons.chat_bubble_outline,
            color: palette.textMuted,
            size: 20,
          ),
          onTap: () => onContactTap(contact),
        );
      },
    );
  }
}
