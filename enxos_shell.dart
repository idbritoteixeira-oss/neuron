import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'enxos_grid_painter.dart';
import 'enx_module.dart';
import 'enxos_theme.dart';
import 'enxos_ui_state.dart';
import 'enxos_watercolor_state.dart';
import 'foreground_service_state.dart';
import 'foreground_service_state.dart';

// Enum para identificar qual app foi tapped
enum AppLaunchTarget { home, inasx, pigeon, freemarket }

// Model para cada botão da bandeja
class AppTrayItem {
  final AppLaunchTarget target;
  final String label;
  final Color color;
  final IconData icon;
  final bool enabled;

  AppTrayItem({
    required this.target,
    required this.label,
    required this.color,
    required this.icon,
    this.enabled = true,
  });
}

class EnxosShell extends StatelessWidget {
  const EnxosShell({
    required this.child,
    this.module,
    this.onSignOut,
    this.extraActionLabel,
    this.extraActionIcon,
    this.onExtraAction,
    this.onAppLaunched,
    this.appTrayItems,
    super.key,
  });

  final Widget child;
  final EnxModule? module;
  final VoidCallback? onSignOut;
  final String? extraActionLabel;
  final IconData? extraActionIcon;
  final VoidCallback? onExtraAction;
  final Function(AppLaunchTarget)? onAppLaunched;
  final List<AppTrayItem>? appTrayItems;

  @override
  Widget build(BuildContext context) {
    final palette = EnxosTheme.paletteOf(context);
    final uiState = context.watch<EnxosUiState>();
    final watercolor = context.watch<EnxosWatercolorState>();

    // Default app tray items se nenhum for fornecido
    final trayItems = appTrayItems ??
        [
          AppTrayItem(
            target: AppLaunchTarget.home,
            label: 'OS',
            color: palette.module,
            icon: Icons.home_outlined,
          ),
          AppTrayItem(
            target: AppLaunchTarget.pigeon,
            label: 'pru',
            color: const Color(0xFF5AB31E),
            icon: Icons.send_outlined,
          ),
          AppTrayItem(
            target: AppLaunchTarget.inasx,
            label: 'inx',
            color: const Color(0xFF5D5D5D),
            icon: Icons.hub_outlined,
          ),
          AppTrayItem(
            target: AppLaunchTarget.freemarket,
            label: 'fre',
            color: const Color(0xFFB3611E),
            icon: Icons.storefront_outlined,
          ),
        ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              color: watercolor.color ?? palette.page,
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: EnxosGridPainter(color: palette.grid),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = math.min(constraints.maxWidth * 0.94, 850.0);
                final height = constraints.maxHeight * 0.94;

                return Center(
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: palette.card,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: palette.border),
                        boxShadow: [
                          BoxShadow(
                            color: palette.shadow,
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Column(
                          children: [
                            _Header(
                              palette: palette,
                              uiState: uiState,
                              module: module,
                              onSignOut: onSignOut,
                              extraActionLabel: extraActionLabel,
                              extraActionIcon: extraActionIcon,
                              onExtraAction: onExtraAction,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  16,
                                  18,
                                  12,
                                ),
                                child: child,
                              ),
                            ),
                            _AppTray(
                              palette: palette,
                              items: trayItems,
                              onItemTapped: onAppLaunched,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.palette,
    required this.uiState,
    required this.module,
    required this.onSignOut,
    required this.extraActionLabel,
    required this.extraActionIcon,
    required this.onExtraAction,
  });

  final EnxosPalette palette;
  final EnxosUiState uiState;
  final EnxModule? module;
  final VoidCallback? onSignOut;
  final String? extraActionLabel;
  final IconData? extraActionIcon;
  final VoidCallback? onExtraAction;

  @override
  Widget build(BuildContext context) {
    final currentModule = module;
    final logoText = currentModule?.abbreviation ?? 'OS';
    final logoColor = currentModule == null
        ? palette.module
        : Color(currentModule.brandColorValue);
    final logoTextColor = logoColor.computeLuminance() > 0.30
        ? const Color(0xFF17242A)
        : Colors.white;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 20, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.border, width: 2)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: logoColor,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              logoText,
              style: TextStyle(
                color: logoTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              currentModule?.title ?? 'enxOS',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 29,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const Spacer(),
          PopupMenuButton<_ShellAction>(
            tooltip: 'Opções',
            icon: Icon(Icons.more_vert, color: palette.textPrimary),
            onSelected: (action) {
              switch (action) {
                case _ShellAction.toggleTheme:
                  uiState.toggleTheme();
                case _ShellAction.settings:
                  _showSettings(context);
                case _ShellAction.serviceToggle:
                  final serviceState = context.read<ForegroundServiceState>();
                  serviceState.toggle(!serviceState.isRunning);
                case _ShellAction.extra:
                  onExtraAction?.call();
                case _ShellAction.signOut:
                  onSignOut?.call();
              }
            },
            itemBuilder: (context) {
              final serviceState = context.watch<ForegroundServiceState>();
              return [
                PopupMenuItem(
                  value: _ShellAction.toggleTheme,
                  child: _MenuLabel(
                    icon: uiState.isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    text: uiState.isDark ? 'Tema claro' : 'Tema escuro',
                  ),
                ),
                const PopupMenuItem(
                  value: _ShellAction.settings,
                  child: _MenuLabel(
                    icon: Icons.tune_outlined,
                    text: 'Configurações',
                  ),
                ),
                if (serviceState.isSupported)
                  PopupMenuItem(
                    value: _ShellAction.serviceToggle,
                    child: _MenuLabel(
                      icon: serviceState.isRunning
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_none_outlined,
                      text: serviceState.isRunning
                          ? 'Desativar notificações'
                          : 'Ativar notificações',
                    ),
                  ),
                if (onExtraAction != null)
                  PopupMenuItem(
                    value: _ShellAction.extra,
                    child: _MenuLabel(
                      icon: extraActionIcon ?? Icons.more_horiz,
                      text: extraActionLabel ?? 'Ação do módulo',
                    ),
                  ),
                if (onSignOut != null) ...[
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: _ShellAction.signOut,
                    child: _MenuLabel(
                      icon: Icons.logout,
                      text: 'Sair do enxOS',
                    ),
                  ),
                ],
              ];
            },
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const _AppearanceDialog(),
    );
  }
}

class _MenuLabel extends StatelessWidget {
  const _MenuLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 19),
        const SizedBox(width: 12),
        Text(text),
      ],
    );
  }
}

class _AppTray extends StatelessWidget {
  const _AppTray({
    required this.palette,
    required this.items,
    required this.onItemTapped,
  });

  final EnxosPalette palette;
  final List<AppTrayItem> items;
  final Function(AppLaunchTarget)? onItemTapped;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.map((item) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _AppTrayButton(
                item: item,
                onTap: item.enabled
                    ? () => onItemTapped?.call(item.target)
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AppTrayButton extends StatelessWidget {
  const _AppTrayButton({
    required this.item,
    required this.onTap,
  });

  final AppTrayItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = item.color.computeLuminance() > 0.30
        ? const Color(0xFF17242A)
        : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Opacity(
          opacity: item.enabled ? 1.0 : 0.5,
          child: Container(
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                item.label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppearanceDialog extends StatelessWidget {
  const _AppearanceDialog();

  @override
  Widget build(BuildContext context) {
    final palette = EnxosTheme.paletteOf(context);
    final uiState = context.watch<EnxosUiState>();
    final watercolor = context.watch<EnxosWatercolorState>();

    return AlertDialog(
      backgroundColor: palette.modal,
      title: const Text('Aparência'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            uiState.isDark ? 'Tema escuro ativo' : 'Tema claro ativo',
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: watercolor.color ?? palette.page,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.border),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  watercolor.isConnected
                      ? 'Cor de fundo sincronizada'
                      : 'Usando fundo local — sincronização indisponível',
                  style: TextStyle(color: palette.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'A cor é atualizada a cada 12 segundos. A escolha do tema fica salva neste dispositivo.',
            style: TextStyle(
              color: palette.textMuted,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: watercolor.refresh,
          child: const Text('Atualizar cor'),
        ),
        FilledButton(
          onPressed: uiState.toggleTheme,
          child: Text(uiState.isDark ? 'Usar tema claro' : 'Usar tema escuro'),
        ),
      ],
    );
  }
}

enum _ShellAction { toggleTheme, settings, serviceToggle, extra, signOut }
