import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_state.dart';
import 'enx_module.dart';
import 'foreground_service.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('enxOS'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              'Olá, ${auth.publicId ?? 'usuário'}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sua sessão enxOS está ativa. Escolha um módulo para continuar.',
              style: TextStyle(color: Color(0xFFA7B7C8), height: 1.45),
            ),
            const SizedBox(height: 22),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF101C2A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF24374A)),
              ),
              child: SwitchListTile.adaptive(
                value: _serviceRunning,
                onChanged: !ForegroundServiceController.isSupported ||
                        _serviceBusy
                    ? null
                    : _toggleService,
                secondary: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF64E1D4).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    color: Color(0xFF64E1D4),
                  ),
                ),
                title: const Text('Serviço em segundo plano'),
                subtitle: Text(
                  _serviceRunning
                      ? 'Ativo • notificação persistente'
                      : ForegroundServiceController.isSupported
                      ? 'Desativado • requer permissão de notificação'
                      : 'Disponível apenas no Android',
                  style: const TextStyle(color: Color(0xFFA7B7C8)),
                ),
              ),
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Text(
                  'Módulos',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${modules.unlockedCount}/3 desbloqueados',
                  style: const TextStyle(
                    color: Color(0xFF8294A8),
                    fontSize: 12,
                  ),
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
            const Text(
              'A chave privada de cada módulo é isolada da sessão global e não é armazenada.',
              style: TextStyle(
                color: Color(0xFF8294A8),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
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
    return Material(
      color: const Color(0xFF101C2A),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF24374A)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF64E1D4).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(_icon, color: const Color(0xFF64E1D4)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${module.id} · ${module.description}',
                      style: const TextStyle(
                        color: Color(0xFFA7B7C8),
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
                    ? const Color(0xFF64E1D4)
                    : const Color(0xFF8294A8),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(module.title),
        actions: [
          TextButton.icon(
            onPressed: () {
              context.read<ModuleState>().lock(module);
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.lock_outline),
            label: const Text('Bloquear'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 50,
                color: Color(0xFF64E1D4),
              ),
              const SizedBox(height: 18),
              Text(
                '${module.title} desbloqueado',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Sessão isolada • ${module.id}',
                style: const TextStyle(color: Color(0xFFA7B7C8)),
              ),
              const SizedBox(height: 18),
              const Text(
                'Tela-base do módulo. Conecte aqui os recursos específicos do produto.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF8294A8),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}