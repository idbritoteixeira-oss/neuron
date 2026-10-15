import 'package:flutter/material.dart';

import '../../core/enxos/enxos_theme.dart';
import 'models/pigeon_models.dart';
import 'widgets/pigeon_avatar.dart';
import 'widgets/verified_badge.dart';

class ChatDetailView extends StatefulWidget {
  const ChatDetailView({
    required this.conversation,
    required this.primary,
    required this.palette,
    required this.onBack,
    required this.onProfileTap,
    required this.onMessageSent,
    super.key,
  });

  final PigeonConversation conversation;
  final Color primary;
  final EnxosPalette palette;
  final VoidCallback onBack;
  final ValueChanged<PigeonProfile> onProfileTap;
  final ValueChanged<PigeonChatMessage> onMessageSent;

  @override
  State<ChatDetailView> createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends State<ChatDetailView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Color get _chatBackground => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF0B141A)
      : const Color(0xFFEFEAE2);

  Color get _sentBubble => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF005C4B)
      : const Color(0xFFD9FDD3);

  Color get _receivedBubble => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF202C33)
      : Colors.white;

  void _sendMessage() {
    final body = _messageController.text.trim();
    if (body.isEmpty) return;
    final now = DateTime.now();
    final message = PigeonChatMessage(
      body: body,
      isMine: true,
      timeLabel:
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
    );
    setState(() {
      widget.conversation.messages.add(message);
      _messageController.clear();
    });
    widget.onMessageSent(message);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.conversation.profile;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          decoration: BoxDecoration(
            color: widget.palette.card,
            border: Border(
              bottom: BorderSide(color: widget.palette.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Voltar',
                onPressed: widget.onBack,
                icon: Icon(Icons.arrow_back, color: widget.primary),
              ),
              IconButton(
                tooltip: 'Ver perfil',
                onPressed: () => widget.onProfileTap(profile),
                padding: EdgeInsets.zero,
                icon: PigeonAvatar(
                  profile: profile,
                  primary: widget.primary,
                  palette: widget.palette,
                  radius: 19,
                ),
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
                            profile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: widget.palette.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        VerifiedBadge(verification: profile.verification),
                      ],
                    ),
                    Text(
                      profile.isOnline ? 'Online' : profile.id,
                      style: TextStyle(
                        color: widget.palette.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Chamada de voz',
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chamadas ainda não conectadas ao serviço.'),
                  ),
                ),
                icon: Icon(Icons.call_outlined, color: widget.primary),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: widget.palette.textSecondary,
                ),
                onSelected: (value) {
                  if (value == 'delete') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'A exclusão da conversa requer o serviço Pigeon.',
                        ),
                      ),
                    );
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'rename',
                    child: Text('Renomear contato'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Apagar conversa'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: _chatBackground,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(14),
              itemCount: widget.conversation.messages.length,
              itemBuilder: (context, index) {
                final message = widget.conversation.messages[index];
                return _MessageBubble(
                  message: message,
                  sentColor: _sentBubble,
                  receivedColor: _receivedBubble,
                  palette: widget.palette,
                );
              },
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: widget.palette.input,
            border: Border(
              top: BorderSide(color: widget.palette.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  style: TextStyle(
                    color: widget.palette.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Mensagem...',
                    hintStyle: TextStyle(color: widget.palette.textMuted),
                    filled: true,
                    fillColor: widget.palette.card,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 11,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(
                        color: widget.primary.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: widget.primary,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Enviar mensagem',
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.sentColor,
    required this.receivedColor,
    required this.palette,
  });

  final PigeonChatMessage message;
  final Color sentColor;
  final Color receivedColor;
  final EnxosPalette palette;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.74,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(11, 8, 9, 6),
        decoration: BoxDecoration(
          color: isMine ? sentColor : receivedColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isMine ? 9 : 0),
            topRight: Radius.circular(isMine ? 0 : 9),
            bottomLeft: const Radius.circular(9),
            bottomRight: const Radius.circular(9),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x16000000),
              blurRadius: 1,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                message.body,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              message.timeLabel,
              style: TextStyle(color: palette.textSecondary, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}
