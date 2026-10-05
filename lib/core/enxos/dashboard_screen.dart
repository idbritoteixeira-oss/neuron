import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_state.dart';
import 'enx_module.dart';
import 'foreground_service.dart';
import 'enxos_shell.dart';
import 'enxos_theme.dart';
import 'module_state.dart';
import 'module_unlock_dialog.dart';
import '../../modules/freemarket/freemarket_screen.dart';
import '../../modules/inasx/inasx_screen.dart';
import '../../modules/pigeon/pigeon_screen.dart';

// Models
class NewsPost {
  final String id;
  final String imageUrl;
  final String author;
  final String quote;
  final DateTime timestamp;

  NewsPost({
    required this.id,
    required this.imageUrl,
    required this.author,
    required this.quote,
    required this.timestamp,
  });
}

class BlockEntry {
  final String blockId;
  final Color color;
  final int ageSeconds;

  BlockEntry({
    required this.blockId,
    required this.color,
    required this.ageSeconds,
  });

  String get ageLabel {
    if (ageSeconds < 60) return '${ageSeconds}s';
    if (ageSeconds < 3600) return '${(ageSeconds / 60).floor()}m';
    if (ageSeconds < 86400) return '${(ageSeconds / 3600).floor()}h';
    return '${(ageSeconds / 86400).floor()}d';
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late PageController _newsPageController;
  int _newsCurrentPage = 0;
  late List<NewsPost> _mockNewsPosts;
  late List<BlockEntry> _mockBlocks;

  @override
  void initState() {
    super.initState();
    _newsPageController = PageController();
    _initMockData();
  }

  void _initMockData() {
    _mockNewsPosts = [
      NewsPost(
        id: 'news_1',
        imageUrl: 'https://via.placeholder.com/400x250?text=News+1',
        author: 'Steve',
        quote: 'Arquitetura clara: shell compartilhado com módulos isolados',
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      NewsPost(
        id: 'news_2',
        imageUrl: 'https://via.placeholder.com/400x250?text=News+2',
        author: 'Alice',
        quote: 'Persistência local de tema + sincronização remota de cor',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NewsPost(
        id: 'news_3',
        imageUrl: 'https://via.placeholder.com/400x250?text=News+3',
        author: 'Bob',
        quote: 'Serviço Android com notificação persistente',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ];

    _mockBlocks = [
      BlockEntry(
        blockId: '7243166401486250',
        color: const Color(0xFF5D3A8A),
        ageSeconds: 25,
      ),
      BlockEntry(
        blockId: '4455667788990011',
        color: const Color(0xFF5AB31E),
        ageSeconds: 60,
      ),
      BlockEntry(
        blockId: '2233445566778899',
        color: const Color(0xFFB3611E),
        ageSeconds: 60,
      ),
      BlockEntry(
        blockId: '9900887766554433',
        color: const Color(0xFF4A90E2),
        ageSeconds: 60,
      ),
      BlockEntry(
        blockId: '3344556677788900',
        color: const Color(0xFF1ABC9C),
        ageSeconds: 60,
      ),
    ];
  }

  @override
  void dispose() {
    _newsPageController.dispose();
    super.dispose();
  }

  Future<void> _openModule(EnxModule module) async {
    final unlocked = context.read<ModuleState>().isUnlocked(module);
    if (!unlocked) {
      final result = await showDialog<bool>(
        context: context,
        builder: (_) => ModuleUnlockDialog(module: module),
      );
      if (result != true || !mounted) return;
    }
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => switch (module) {
          EnxModule.inasx => InasxScreen(onLauncherTap: _handleLauncherTap),
          EnxModule.pigeon => PigeonScreen(onLauncherTap: _handleLauncherTap),
          EnxModule.freemarket => FreeMarketScreen(onLauncherTap: _handleLauncherTap),
        },
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _signOut() async {
    await ForegroundServiceController.stop();
    if (!mounted) return;
    context.read<ModuleState>().clear();
    context.read<AuthState>().signOut();
  }

  Future<void> _handleLauncherTap(EnxModule? module) async {
    if (module == null) {
      // Home (enxOS) — já na dashboard
      return;
    }
    await _openModule(module);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final palette = EnxosTheme.paletteOf(context);

    return EnxosShell(
      onSignOut: _signOut,
      onLauncherTap: _handleLauncherTap,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(2, 4, 2, 20),
        children: [
          // Saudação
          Text(
            'Olá, ${auth.publicId ?? 'usuário'}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: palette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sua sessão enxOS está ativa.',
            style: TextStyle(color: palette.textSecondary, height: 1.45),
          ),
          const SizedBox(height: 22),

          // #news Carousel
          Text(
            '#news',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: palette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: PageView.builder(
              controller: _newsPageController,
              onPageChanged: (index) {
                setState(() => _newsCurrentPage = index);
              },
              itemCount: _mockNewsPosts.length,
              itemBuilder: (context, index) {
                final post = _mockNewsPosts[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _NewsCard(post: post, palette: palette),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Indicadores
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _mockNewsPosts.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _newsCurrentPage
                      ? palette.module
                      : palette.textMuted.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),

          // Últimos blocos
          Text(
            'Últimos blocos',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: palette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ..._mockBlocks.map(
            (block) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BlockBar(block: block, palette: palette),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.post, required this.palette});

  final NewsPost post;
  final EnxosPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              width: double.infinity,
              color: palette.textMuted.withValues(alpha: 0.1),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    post.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.image_not_supported_outlined,
                      color: palette.textMuted,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5AB31E),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '#news',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: palette.module.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.person_outline,
                            color: palette.module,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          post.author,
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Text(
                        post.quote,
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockBar extends StatelessWidget {
  const _BlockBar({required this.block, required this.palette});

  final BlockEntry block;
  final EnxosPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 48,
          decoration: BoxDecoration(
            color: block.color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            block.blockId,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ),
        ),
        Text(
          block.ageLabel,
          style: TextStyle(
            color: palette.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class ModuleHomeScreen extends StatelessWidget {
  const ModuleHomeScreen({
    required this.module,
    this.onLauncherTap,
    super.key
  });

  final EnxModule module;
  final EnxosLauncherCallback? onLauncherTap;

  @override
  Widget build(BuildContext context) {
    final palette = EnxosTheme.paletteOf(context);
    return EnxosShell(
      module: module,
      onLauncherTap: onLauncherTap,  // ← passa aqui
      extraActionLabel: 'Bloquear módulo',
      extraActionIcon: Icons.lock_outline,
      onExtraAction: () {
        context.read<ModuleState>().lock(module);
        Navigator.of(context).pop();
      },
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 50,
                color: palette.module,
              ),
              const SizedBox(height: 18),
              Text(
                '${module.title} desbloqueado',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Sessão isolada • ${module.id}',
                style: TextStyle(color: palette.textSecondary),
              ),
              const SizedBox(height: 18),
              Text(
                'Tela-base do módulo. Conecte aqui os recursos específicos do produto.',
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.textMuted, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}