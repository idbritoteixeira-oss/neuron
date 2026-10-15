import 'package:flutter/material.dart';

import '../../../core/enxos/enxos_theme.dart';
import '../models/pigeon_models.dart';
import '../widgets/pigeon_avatar.dart';
import '../widgets/verified_badge.dart';

class MessagesTab extends StatelessWidget {
  const MessagesTab({
    required this.conversations,
    required this.primary,
    required this.palette,
    required this.onConversationTap,
    required this.onProfileTap,
    super.key,
  });

  final List<PigeonConversation> conversations;
  final Color primary;
  final EnxosPalette palette;
  final ValueChanged<PigeonConversation> onConversationTap;
  final ValueChanged<PigeonProfile> onProfileTap;

  @override
  Widget build(BuildContext context) {
    if (conversations.isEmpty) {
      return _EmptyState(
        palette: palette,
        message: 'Sua caixa de entrada está vazia.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: conversations.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: palette.border, indent: 64),
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        final profile = conversation.profile;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          leading: GestureDetector(
            onTap: () => onProfileTap(profile),
            child: PigeonAvatar(
              profile: profile,
              primary: primary,
              palette: palette,
              radius: 23,
            ),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  profile.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              VerifiedBadge(verification: profile.verification),
            ],
          ),
          subtitle: Text(
            conversation.lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: palette.textSecondary, fontSize: 13),
          ),
          trailing: SizedBox(
            width: 54,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  conversation.timeLabel,
                  style: TextStyle(
                    color: conversation.unreadCount > 0
                        ? primary
                        : palette.textMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                if (conversation.unreadCount > 0)
                  Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: palette.badgeMessage,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '${conversation.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          onTap: () => onConversationTap(conversation),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.palette, required this.message});

  final EnxosPalette palette;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      message,
      style: TextStyle(color: palette.textSecondary, fontSize: 13),
    ),
  );
}
