import 'package:flutter/material.dart';

import '../../core/enxos/enx_module.dart';
import '../../core/enxos/enxos_shell.dart';
import '../../core/enxos/enxos_theme.dart';

class PigeonScreen extends StatefulWidget {
  const PigeonScreen({required this.onLauncherTap, super.key});

  final EnxosLauncherCallback onLauncherTap;

  @override
  State<PigeonScreen> createState() => _PigeonScreenState();
}

class _PigeonScreenState extends State<PigeonScreen>
    with SingleTickerProviderStateMixin {
  int _tabIndex = 0;
  late TabController _tabController;

  // Estado para controlar se estamos dentro de um chat ativo
  Map<String, dynamic>? _activeChat;

  static const _primary = Color(0xFF5AB31E);

  final List<Map<String, dynamic>> _mockChats = [
    {
      'name': 'Alice',
      'id': 'pru_882910',
      'msg': 'Oi, tudo bem?',
      'time': '10:32',
      'unread': 2,
      'verified': true, // Selo azul (verificado)
      'verifiedColor': Colors.blue,
    },
    {
      'name': 'Bob',
      'id': 'pru_441029',
      'msg': 'Viu o feed?',
      'time': '09:15',
      'unread': 0,
      'verified': true, // Selo cinza (reservado pelo sistema)
      'verifiedColor': Colors.grey,
    },
    {
      'name': 'Carol',
      'id': 'pru_992104',
      'msg': 'Pode falar agora?',
      'time': 'Ontem',
      'unread': 1,
      'verified': false,
      'verifiedColor': null,
    },
    {
      'name': 'Dave',
      'id': 'pru_112344',
      'msg': 'Ok!',
      'time': 'Ontem',
      'unread': 0,
      'verified': false,
      'verifiedColor': null,
    },
    {
      'name': 'Eve',
      'id': 'pru_556789',
      'msg': 'Enviou uma imagem',
      'time': 'Seg',
      'unread': 0,
      'verified': true,
      'verifiedColor': Colors.blue,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      setState(() => _tabIndex = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openChat(Map<String, dynamic> chat) {
    setState(() {
      _activeChat = chat;
    });
  }

  void _closeChat() {
    setState(() {
      _activeChat = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = EnxosTheme.paletteOf(context);

    return EnxosShell(
      module: EnxModule.pigeon,
      onLauncherTap: widget.onLauncherTap,
      extraActionLabel: _activeChat != null ? 'Voltar às mensagens' : 'Bloquear módulo',
      extraActionIcon: _activeChat != null ? Icons.arrow_back : Icons.lock_outline,
      onExtraAction: () {
        if (_activeChat != null) {
          _closeChat();
        } else {
          Navigator.of(context).pop();
        }
      },
      child: _activeChat != null
          ? _ChatDetailView(
              chat: _activeChat!,
              primary: _primary,
              palette: palette,
              onBack: _closeChat,
            )
          : Column(
              children: [
                // Abas
                _PigeonTabs(
                  controller: _tabController,
                  primary: _primary,
                  palette: palette,
                ),
                const SizedBox(height: 8),

                // Barra de busca
                const _SearchBar(primary: _primary),
                const SizedBox(height: 8),

                // Conteúdo da aba
                Expanded(
                  child: Stack(
                    children: [
                      TabBarView(
                        controller: _tabController,
                        children: [
                          _MensagensTab(
                            chats: _mockChats,
                            primary: _primary,
                            palette: palette,
                            onChatTap: _openChat,
                          ),
                          _ContatosTab(primary: _primary, palette: palette),
                          _FeedTab(primary: _primary, palette: palette),
                          _PTTTab(primary: _primary, palette: palette),
                        ],
                      ),

                      // FAB
                      if (_tabIndex == 0 || _tabIndex == 1)
                        Positioned(
                          bottom: 12,
                          right: 4,
                          child: _FAB(primary: _primary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Widget de Exibição do Selo de Identificação ────────────────
class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge({required this.verified, required this.color});

  final bool verified;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (!verified || color == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(left: 4),
      child: Icon(
        Icons.check_circle,
        size: 14,
        color: color,
      ),
    );
  }
}

// ── Tela Interna de Chat Individual ───────────────────────────
class _ChatDetailView extends StatefulWidget {
  const _ChatDetailView({
    required this.chat,
    required this.primary,
    required this.palette,
    required this.onBack,
  });

  final Map<String, dynamic> chat;
  final Color primary;
  final EnxosPalette palette;
  final VoidCallback onBack;

  @override
  State<_ChatDetailView> createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends State<_ChatDetailView> {
  final TextEditingController _msgController = TextEditingController();
  final List<String> _messages = [
    'Olá! Como vão as coisas por aí?',
    'Tudo ótimo por aqui, estruturando o ecossistema.',
  ];

  void _sendMessage() {
    if (_msgController.text.trim().isEmpty) return;
    setState(() {
      _messages.add(_msgController.text.trim());
      _msgController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.chat['name'] as String;
    final isVerified = widget.chat['verified'] as bool;
    final verifiedColor = widget.chat['verifiedColor'] as Color?;

    return Column(
      children: [
        // Topbar do Chat Interno
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: widget.palette.border)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                color: widget.palette.textPrimary,
                onPressed: widget.onBack,
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: widget.primary.withValues(alpha: 0.15),
                child: Text(
                  name[0],
                  style: TextStyle(
                    color: widget.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: widget.palette.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    _VerifiedBadge(verified: isVerified, color: verifiedColor),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.call_outlined),
                color: widget.primary,
                onPressed: () {},
              ),
            ],
          ),
        ),

        // Lista de Mensagens do Chat
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final isMe = index % 2 != 0;
              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isMe ? widget.primary.withValues(alpha: 0.2) : widget.palette.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.palette.border),
                  ),
                  child: Text(
                    _messages[index],
                    style: TextStyle(
                      color: widget.palette.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Barra de Envio de Mensagem
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.palette.card,
            border: Border(top: BorderSide(color: widget.palette.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgController,
                  style: TextStyle(color: widget.palette.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Digite sua mensagem...',
                    hintStyle: TextStyle(color: widget.palette.textMuted),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: widget.primary),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Abas ─────────────────────────────────────────────────────
class _PigeonTabs extends StatelessWidget {
  const _PigeonTabs({
    required this.controller,
    required this.primary,
    required this.palette,
  });

  final TabController controller;
  final Color primary;
  final EnxosPalette palette;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      labelColor: primary,
      unselectedLabelColor: palette.textSecondary,
      indicatorColor: primary,
      indicatorWeight: 2.5,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      tabs: const [
        Tab(text: 'Mensagens'),
        Tab(text: 'Contatos'),
        Tab(text: 'Feed'),
        Tab(text: 'PTT'),
      ],
    );
  }
}

// ── Barra de busca ───────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.primary});
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.search, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text(
            'Pesquisar...',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ── FAB ──────────────────────────────────────────────────────
class _FAB extends StatelessWidget {
  const _FAB({required this.primary});
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.person_add_outlined, color: Colors.white, size: 24),
      ),
    );
  }
}

// ── Aba Mensagens ─────────────────────────────────────────────
class _MensagensTab extends StatelessWidget {
  const _MensagensTab({
    required this.chats,
    required this.primary,
    required this.palette,
    required this.onChatTap,
  });

  final List<Map<String, dynamic>> chats;
  final Color primary;
  final EnxosPalette palette;
  final ValueChanged<Map<String, dynamic>> onChatTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: chats.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: palette.border,
        indent: 64,
      ),
      itemBuilder: (context, i) {
        final chat = chats[i];
        final unread = chat['unread'] as int;
        final name = chat['name'] as String;
        final isVerified = chat['verified'] as bool;
        final verifiedColor = chat['verifiedColor'] as Color?;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: primary.withValues(alpha: 0.15),
            child: Text(
              name[0],
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  name,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _VerifiedBadge(verified: isVerified, color: verifiedColor),
            ],
          ),
          subtitle: Text(
            chat['msg'] as String,
            style: TextStyle(color: palette.textSecondary, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                chat['time'] as String,
                style: TextStyle(
                  color: unread > 0 ? primary : palette.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              if (unread > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                const SizedBox(height: 16),
            ],
          ),
          onTap: () => onChatTap(chat),
        );
      },
    );
  }
}

// ── Aba Contatos ──────────────────────────────────────────────
class _ContatosTab extends StatelessWidget {
  const _ContatosTab({required this.primary, required this.palette});
  final Color primary;
  final EnxosPalette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 48, color: palette.textMuted),
          const SizedBox(height: 12),
          Text(
            'Nenhum contato ainda.',
            style: TextStyle(color: palette.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ── Aba Feed ──────────────────────────────────────────────────
class _FeedTab extends StatelessWidget {
  const _FeedTab({required this.primary, required this.palette});
  final Color primary;
  final EnxosPalette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.dynamic_feed_outlined, size: 48, color: palette.textMuted),
          const SizedBox(height: 12),
          Text(
            'Feed em breve.',
            style: TextStyle(color: palette.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ── Aba PTT ───────────────────────────────────────────────────
class _PTTTab extends StatelessWidget {
  const _PTTTab({required this.primary, required this.palette});
  final Color primary;
  final EnxosPalette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.close_fullscreen, size: 40, color: primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Segure para falar',
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
