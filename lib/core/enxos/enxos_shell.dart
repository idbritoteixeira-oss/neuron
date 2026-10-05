import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'enxos_grid_painter.dart';
import 'enx_module.dart';
import 'enxos_theme.dart';
import 'enxos_ui_state.dart';
import 'enxos_watercolor_state.dart';
import 'foreground_service.dart';

class EnxosShell extends StatelessWidget {
  const EnxosShell({
    required this.child,
    this.module,
    this.onLauncherTap,
    this.onSignOut,
    this.extraActionLabel,
    this.extraActionIcon,
    this.onExtraAction,
    super.key,
  });

  final Widget child;
  final EnxModule? module;
  final EnxosLauncherCallback? onLauncherTap;
  final VoidCallback? onSignOut;
  final String? extraActionLabel;
  final IconData? extraActionIcon;
  final VoidCallback? onExtraAction;

  @override
  Widget build(BuildContext context) {
    final palette = EnxosTheme.paletteOf(context);
    final uiState = context.watch<EnxosUiState>();
    final watercolor = context.watch<EnxosWatercolorState>();

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
                                padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                                child: child,
                              ),
                            ),
                                  _AppLauncher(
                              palette: palette,
                              selectedModule: module,
                              onSelect: onLauncherTap,
                            ),
_Footer(
                              palette: palette,
                              watercolor: watercolor,
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

class _Header extends StatefulWidget {
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
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
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
        await ForegroundServiceController.start();
      } else {
        await ForegroundServiceController.stop();
      }
      await _refreshServiceState();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao alterar serviço.')),
        );
      }
    } finally {
      if (mounted) setState(() => _serviceBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentModule = widget.module;
    final logoText = currentModule?.abbreviation ?? 'os';
    final logoColor = currentModule == null
        ? widget.palette.module
        : Color(currentModule.brandColorValue);
    final logoTextColor = logoColor.computeLuminance() > 0.30
        ? const Color(0xFF17242A)
        : Colors.white;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 20, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: widget.palette.border, width: 2)),
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
                color: widget.palette.textPrimary,
                fontSize: 29,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const Spacer(),
          PopupMenuButton<_ShellAction>(
            tooltip: 'Opções',
            icon: Icon(Icons.more_vert, color: widget.palette.textPrimary),
            onSelected: (action) {
              switch (action) {
                case _ShellAction.toggleTheme:
                  widget.uiState.toggleTheme();
                case _ShellAction.settings:
                  _showSettings(context);
                case _ShellAction.toggleService:
                  _toggleService(!_serviceRunning);
                case _ShellAction.extra:
                  widget.onExtraAction?.call();
                case _ShellAction.signOut:
                  widget.onSignOut?.call();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _ShellAction.toggleTheme,
                child: _MenuLabel(
                  icon: widget.uiState.isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  text: widget.uiState.isDark ? 'Tema claro' : 'Tema escuro',
                ),
              ),
              const PopupMenuItem(
                value: _ShellAction.settings,
                child: _MenuLabel(
                  icon: Icons.tune_outlined,
                  text: 'Configurações',
                ),
              ),
              if (ForegroundServiceController.isSupported)
                PopupMenuItem(
                  value: _ShellAction.toggleService,
                  child: _MenuLabel(
                    icon: _serviceRunning
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_none_outlined,
                    text: _serviceRunning
                        ? 'Desativar notificações'
                        : 'Ativar notificações',
                  ),
                ),
              if (widget.onExtraAction != null)
                PopupMenuItem(
                  value: _ShellAction.extra,
                  child: _MenuLabel(
                    icon: widget.extraActionIcon ?? Icons.more_horiz,
                    text: widget.extraActionLabel ?? 'Ação do módulo',
                  ),
                ),
              if (widget.onSignOut != null) ...[
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: _ShellAction.signOut,
                  child: _MenuLabel(
                    icon: Icons.logout,
                    text: 'Sair do enxOS',
                  ),
                ),
              ],
            ],
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

class _AppLauncher extends StatelessWidget {
  const _AppLauncher({
    required this.palette,
    required this.selectedModule,
    required this.onSelect,
  });

  static const _moduleOrder = [
    EnxModule.pigeon,
    EnxModule.inasx,
    EnxModule.freemarket,
  ];
  static const _maxModuleButtons = 4;

  final EnxosPalette palette;
  final EnxModule? selectedModule;
  final EnxosLauncherCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final items = [
      _LauncherItem(
        label: 'enxOS',
        abbreviation: 'os',
        color: palette.module,
      ),
      ..._moduleOrder.take(_maxModuleButtons).map(
        (module) => _LauncherItem(
          label: module.title,
          abbreviation: module.abbreviation,
          color: Color(module.brandColorValue),
          module: module,
        ),
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      decoration: BoxDecoration(
        color: palette.card,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: _AppLauncherButton(
                item: item,
                palette: palette,
                selected: item.module == selectedModule,
                onSelect: onSelect,
              ),
            ),
        ],
      ),
    );
  }
}

class _LauncherItem {
  const _LauncherItem({
    required this.label,
    required this.abbreviation,
    required this.color,
    this.module,
  });

  final String label;
  final String abbreviation;
  final Color color;
  final EnxModule? module;
}

class _AppLauncherButton extends StatelessWidget {
  const _AppLauncherButton({
    required this.item,
    required this.palette,
    required this.selected,
    required this.onSelect,
  });

  final _LauncherItem item;
  final EnxosPalette palette;
  final bool selected;
  final EnxosLauncherCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final enabled = onSelect != null && !selected;
    final textColor = item.color.computeLuminance() > 0.30
        ? const Color(0xFF17242A)
        : Colors.white;

    return Tooltip(
      message: item.module != null && onSelect == null
          ? 'Entre no enxOS para abrir este módulo'
          : item.label,
      child: Opacity(
        opacity: item.module != null && onSelect == null ? 0.45 : 1,
        child: Material(
          color: selected
              ? item.color.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: enabled ? () => onSelect!(item.module) : null,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      item.abbreviation,
                      maxLines: 1,
                      style: TextStyle(
                        color: textColor,
                        fontSize: item.abbreviation.length > 3 ? 9 : 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? palette.textPrimary
                          : palette.textSecondary,
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.palette, required this.watercolor});

  final EnxosPalette palette;
  final EnxosWatercolorState watercolor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 9, 18, 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          watercolor.sourceValue == null
              ? '{/enxOS ${watercolor.isConnected ? '...' : 'offline'}}'
              : '{/enxOS ${watercolor.sourceValue}}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: palette.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            fontFamily: 'monospace',
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

enum _ShellAction { toggleTheme, settings, toggleService, extra, signOut }