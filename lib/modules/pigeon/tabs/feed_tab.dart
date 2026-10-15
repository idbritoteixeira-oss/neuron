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
          maxLines: 4,
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
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 72),
      children: [
        _Composer(
          currentUser: widget.currentUser,
          primary: widget.primary,
          palette: widget.palette,
          onTap: _composePost,
        ),
        const SizedBox(height: 6),
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
                style: TextStyle(color: widget.palette.textSecondary, fontSize: 13),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.card,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          PigeonAvatar(
            profile: currentUser,
            primary: primary,
            palette: palette,
            radius: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Material(
              color: palette.input,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    'Pensando em?',
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
            onPressed: onTap,
            tooltip: 'Criar publicação',
            icon: Icon(Icons.image_outlined, color: primary, size: 20),
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
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.card,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(10),
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
                radius: 15,
                useVerificationFallback: true,
              ),
              const SizedBox(width: 8),
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
                              fontSize: 12.5,
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
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.more_horiz, color: palette.textMuted, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            post.content,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          if (post.imageUrl != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                post.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Divider(height: 1, color: palette.border),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onLike,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          post.isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 15,
                          color: post.isLiked
                              ? const Color(0xFFF5B041)
                              : palette.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.likes}',
                          style: TextStyle(
                            color: post.isLiked
                                ? const Color(0xFFF5B041)
                                : palette.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 16, color: palette.border),
              Expanded(
                child: InkWell(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Comentários do feed ainda não conectados.',
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 14.5,
                          color: palette.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.comments}',
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
