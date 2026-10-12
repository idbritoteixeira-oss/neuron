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

  static const _primary = Color(0xFF5AB31E);

  final List<Map<String, dynamic>> _mockChats = [
    {'name': 'Alice', 'msg': 'Oi, tudo bem?', 'time': '10:32', 'unread': 2},
    {'name': 'Bob', 'msg': 'Viu o feed?', 'time': '09:15', 'unread': 0},
    {'name': 'Carol', 'msg': 'Pode falar agora?', 'time': 'Ontem', 'unread': 1},
    {'name': 'Dave', 'msg': 'Ok!', 'time': 'Ontem', 'unread': 0},
    {'name': 'Eve', 'msg': 'Enviou uma imagem', 'time': 'Seg', 'unread': 0},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() => _tabIndex = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = EnxosTheme.paletteOf(context);

    return EnxosShell(
      module: EnxModule.pigeon,
      onLauncherTap: widget.onLauncherTap,
      extraActionLabel: 'Bloquear módulo',
      extraActionIcon: Icons.lock_outline,
      onExtraAction: () => Navigator.of(context).pop(),
      child: Column(
        children: [
          // Abas
          _PigeonTabs(
            controller: _tabController,
            primary: _primary,
            palette: palette,
          ),
          const SizedBox(height: 8),

          // Barra de busca
          _SearchBar(primary: _primary),
          const SizedBox(height: 8),

          // Conteúdo da aba
          Expanded(
            child: Stack(
              children: [
                TabBarView(
                  controller: _tabController,
                  children: [
                    _MensagensTab(chats: _mockChats, primary: _primary, palette: palette),
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
  });

  final List<Map<String, dynamic>> chats;
  final Color primary;
  final EnxosPalette palette;

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
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: primary.withValues(alpha: 0.15),
            child: Text(
              (chat['name'] as String)[0],
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          title: Text(
            chat['name'] as String,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
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
          onTap: () {},
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
            child: Icon(Icons.mic_outlined, size: 40, color: primary),
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