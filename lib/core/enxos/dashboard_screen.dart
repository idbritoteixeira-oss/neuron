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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _serviceRunning = false;
  bool _serviceBusy = false;

  @override
  void initState() {
    super.initState();
    _refreshServiceState();
  }

  Future<void> _refreshServiceState() async {
    final running = await ForegroundServiceController.isRunning;
    if (mounted) setState(() => _serviceRunning = running);
  }

  Future<void> _toggleService(bool enabled) async {
    setState(() => _serviceBusy = true);
    try {
      if (enabled) {
        final started = await ForegroundServiceController.start();
        if (!started && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permita notificações para iniciar o serviço.'),
            ),
          );
        }
      } else {
        await ForegroundServiceController.stop();
      }
      await _refreshServiceState();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível alterar o serviço.')),
        );
      }
    } finally {
      if (mounted) setState(() => _serviceBusy = false);
    }
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
          EnxModule.inasx => const InasxScreen(),
          EnxModule.pigeon => const PigeonScreen(),
          EnxModule.freemarket => const FreeMarketScreen(),
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final modules = context.watch<ModuleState>();
    final palette = EnxosTheme.paletteOf(context);
    return EnxosShell(
      onSignOut: _signOut,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(2, 4, 2, 20),
        children: [
          Text(
            'Olá, ${auth.publicId ?? 'usuário'}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: palette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sua sessão enxOS está ativa. Escolha um módulo para continuar.',
            style: TextStyle(color: palette.textSecondary, height: 1.45),
          ),
          const SizedBox(height: 22),
          Container(
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.border),
            ),
            child: SwitchListTile.adaptive(
              value: _serviceRunning,
              onChanged: !ForegroundServiceController.isSupported || _serviceBusy
                  ? null
                  : _toggleService,
              secondary: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: palette.module.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.notifications_active_outlined,
                  color: palette.module,
                ),
              ),
              title: const Text('Serviço em segundo plano'),
              subtitle: Text(
                _serviceRunning
                    ? 'Ativo • notificação persistente'
                    : ForegroundServiceController.isSupported
                    ? 'Desativado • requer permissão de notificação'
                    : 'Disponível apenas no Android',
                style: TextStyle(color: palette.textSecondary),
              ),
            ),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Text(
                'Módulos',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${modules.unlockedCount}/3 desbloqueados',
                style: TextStyle(color: palette.textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...EnxModule.values.map(
            (module) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ModuleCard(
                module: module,
                unlocked: modules.isUnlocked(module),
                onTap: () => _openModule(module),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A chave privada de cada módulo é isolada da sessão global e não é armazenada.',
            style: TextStyle(
              color: palette.textMuted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.module,
    required this.unlocked,
    required this.onTap,
  });

  final EnxModule module;
  final bool unlocked;
  final VoidCallback onTap;

  IconData get _icon => switch (module) {
    EnxModule.inasx => Icons.hub_outlined,
    EnxModule.pigeon => Icons.send_outlined,
    EnxModule.freemarket => Icons.storefront_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final palette = EnxosTheme.paletteOf(context);
    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: palette.module.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(_icon, color: palette.module),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${module.id} · ${module.description}',
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                unlocked ? Icons.check_circle : Icons.lock_outline,
                size: 20,
                color: unlocked
                    ? palette.module
                    : palette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ModuleHomeScreen extends StatelessWidget {
  const ModuleHomeScreen({required this.module, super.key});

  final EnxModule module;

  @override
  Widget build(BuildContext context) {
    final palette = EnxosTheme.paletteOf(context);
    return EnxosShell(
      sectionLabel: module.title,
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