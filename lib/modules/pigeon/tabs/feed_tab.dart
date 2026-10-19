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
    required this.onLikePost,
    required this.onContactAuthor,
    required this.onEditPost,
    required this.onDeletePost,
    required this.onReportPost,
    super.key,
  });

  final List<PigeonFeedPost> posts;
  final PigeonProfile currentUser;
  final Color primary;
  final EnxosPalette palette;
  final Future<void> Function(String content) onCreatePost;
  final Future<void> Function(PigeonFeedPost post) onLikePost;
  final ValueChanged<PigeonProfile> onContactAuthor;
  final Future<void> Function(PigeonFeedPost post, String content) onEditPost;
  final Future<void> Function(PigeonFeedPost post) onDeletePost;
  final Future<void> Function(PigeonFeedPost post, String reason) onReportPost;

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
    if (content != null && content.isNotEmpty) {
      try {
        await widget.onCreatePost(content);
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Não foi possível publicar: $error')),
          );
        }
      }
    }
  }

  Future<void> _toggleLike(PigeonFeedPost post) async {
    if (post.postId == null) return;
    try {
      await widget.onLikePost(post);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível curtir: $error')),
        );
      }
    }
  }

  Future<void> _editPost(PigeonFeedPost post) async {
    final controller = TextEditingController(text: post.content);
    final content = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: widget.palette.modal,
        title: Text(
          'Editar publicação',
          style: TextStyle(color: widget.palette.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          maxLength: 1000,
          decoration: const InputDecoration(alignLabelWithHint: true),
          style: TextStyle(color: widget.palette.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (content == null || content.trim().isEmpty) return;
    await _runPostAction(
      'Não foi possível editar a publicação',
      () => widget.onEditPost(post, content.trim()),
    );
  }

  Future<void> _deletePost(PigeonFeedPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: widget.palette.modal,
        title: Text(
          'Apagar publicação?',
          style: TextStyle(color: widget.palette.textPrimary),
        ),
        content: Text(
          'A publicação será removida do feed.',
          style: TextStyle(color: widget.palette.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _runPostAction(
      'Não foi possível apagar a publicação',
      () => widget.onDeletePost(post),
    );
  }

  Future<void> _reportPost(PigeonFeedPost post) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: widget.palette.modal,
        title: Text(
          'Denunciar publicação',
          style: TextStyle(color: widget.palette.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          maxLength: 300,
          decoration: const InputDecoration(labelText: 'Motivo'),
          style: TextStyle(color: widget.palette.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Enviar denúncia'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || reason.trim().isEmpty) return;
    await _runPostAction(
      'Não foi possível denunciar a publicação',
      () => widget.onReportPost(post, reason.trim()),
    );
  }

  Future<void> _runPostAction(
    String errorPrefix,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$errorPrefix:$error')));
      }
    }
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
            onContactAuthor: () => widget.onContactAuthor(post.author),
            isMine: post.author.id == widget.currentUser.id,
            onEdit: () => _editPost(post),
            onDelete: () => _deletePost(post),
            onReport: () => _reportPost(post),
          ),
        if (widget.posts.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Ainda não há publicações.',
                style: TextStyle(
                  color: widget.palette.textSecondary,
                  fontSize: 13,
                ),
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
    // Removida a referência inválida a `post.imageUrl` que causava erro no _Composer
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
    required this.onContactAuthor,
    required this.isMine,
    required this.onEdit,
    required this.onDelete,
    required this.onReport,
  });

  final PigeonFeedPost post;
  final Color primary;
  final EnxosPalette palette;
  final VoidCallback onLike;
  final VoidCallback onContactAuthor;
  final bool isMine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final imageUrl = post.imageUrl; // Corrigido para acessar a propriedade a partir do objeto `post`
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
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_horiz,
                  color: palette.textMuted,
                  size: 18,
                ),
                onSelected: (action) {
                  switch (action) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                    case 'report':
                      onReport();
                      break;
                  }
                },
                itemBuilder: (_) => isMine
                    ? const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(value: 'delete', child: Text('Apagar')),
                      ]
                    : const [
                        PopupMenuItem(
                          value: 'report',
                          child: Text('Denunciar'),
                        ),
                      ],
              ),
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
          if (imageUrl != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                imageUrl,
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
                  onTap: onContactAuthor,
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
                          'Conversar',
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