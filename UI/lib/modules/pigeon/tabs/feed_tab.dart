import 'package:flutter/material.dart';

import '../../../core/enxos/enxos_theme.dart';
import '../models/pigeon_models.dart';
import '../widgets/pigeon_avatar.dart';
import '../widgets/verified_badge.dart';

class FeedTab extends StatefulWidget {
  const FeedTab({
    required this.posts,
    required this.currentUser,
    required this.primary,
    required this.palette,
    required this.onCreatePost,
    super.key,
  });

  final List<PigeonFeedPost> posts;
  final PigeonProfile currentUser;
  final Color primary;
  final EnxosPalette palette;
  final ValueChanged<String> onCreatePost;

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  Future<void> _composePost() async {
    final controller = TextEditingController();
    final content = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: widget.palette.modal,
        title: Text(
          'Criar publicação',
          style: TextStyle(color: widget.palette.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 5,
          maxLength: 1000,
          style: TextStyle(color: widget.palette.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Em que estás a pensar?',
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Publicar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (content != null && content.isNotEmpty) widget.onCreatePost(content);
  }

  void _toggleLike(PigeonFeedPost post) {
    setState(() {
      post.isLiked = !post.isLiked;
      post.likes += post.isLiked ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 72),
      children: [
        _Composer(
          currentUser: widget.currentUser,
          primary: widget.primary,
          palette: widget.palette,
          onTap: _composePost,
        ),
        const SizedBox(height: 8),
        for (final post in widget.posts)
          _PostCard(
            post: post,
            primary: widget.primary,
            palette: widget.palette,
            onLike: () => _toggleLike(post),
          ),
        if (widget.posts.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Ainda não há publicações.',
                style: TextStyle(color: widget.palette.textSecondary),
              ),
            ),
          ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.currentUser,
    required this.primary,
    required this.palette,
    required this.onTap,
  });

  final PigeonProfile currentUser;
  final Color primary;
  final EnxosPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Publicações',
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              PigeonAvatar(
                profile: currentUser,
                primary: primary,
                palette: palette,
                radius: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Material(
                  color: palette.input,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 11,
                      ),
                      child: Text(
                        'Em que estás a pensar?',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: onTap,
                tooltip: 'Criar publicação',
                icon: Icon(Icons.image_outlined, color: primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.primary,
    required this.palette,
    required this.onLike,
  });

  final PigeonFeedPost post;
  final Color primary;
  final EnxosPalette palette;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.card,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PigeonAvatar(
                profile: post.author,
                primary: primary,
                palette: palette,
                radius: 18,
                useVerificationFallback: true,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            post.author.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        VerifiedBadge(verification: post.author.verification),
                      ],
                    ),
                    Text(
                      post.timeLabel,
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.more_horiz, color: palette.textMuted),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.content,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (post.imageUrl != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                post.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Divider(height: 1, color: palette.border),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onLike,
                  icon: Icon(
                    post.isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 17,
                    color: post.isLiked
                        ? const Color(0xFFF5B041)
                        : palette.textSecondary,
                  ),
                  label: Text(
                    '${post.likes}',
                    style: TextStyle(
                      color: post.isLiked
                          ? const Color(0xFFF5B041)
                          : palette.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Comentários do feed ainda não conectados.',
                      ),
                    ),
                  ),
                  icon: Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: palette.textSecondary,
                  ),
                  label: Text(
                    '${post.comments}',
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
