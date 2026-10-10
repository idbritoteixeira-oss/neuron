import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'enx_module.dart';
import 'enxos_theme.dart';
import 'module_state.dart';

class ModuleUnlockDialog extends StatefulWidget {
  const ModuleUnlockDialog({required this.module, super.key});

  final EnxModule module;

  @override
  State<ModuleUnlockDialog> createState() => _ModuleUnlockDialogState();
}

class _ModuleUnlockDialogState extends State<ModuleUnlockDialog>
    with SingleTickerProviderStateMixin {
  final List<int> _digits = [];
  bool _error = false;
  bool _loading = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigit(int digit) {
    if (_digits.length >= 6 || _loading) return;
    HapticFeedback.lightImpact();
    setState(() {
      _digits.add(digit);
      _error = false;
    });
    if (_digits.length == 6) _validate();
  }

  void _onDelete() {
    if (_digits.isEmpty || _loading) return;
    HapticFeedback.lightImpact();
    setState(() => _digits.removeLast());
  }

  Future<void> _validate() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 120));

    final pin = _digits.join();
    final unlocked = await context.read<ModuleState>().unlock(
      module: widget.module,
      moduleId: widget.module.id,
      privateId: pin,
    );

    if (!mounted) return;

    if (unlocked) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
      return;
    }

    HapticFeedback.heavyImpact();
    _shakeController.forward(from: 0);
    setState(() {
      _error = true;
      _loading = false;
      _digits.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = EnxosTheme.paletteOf(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      alignment: Alignment.center,
      child: Center(
        child: SizedBox(
          width: 320,
          child: Container(
            decoration: BoxDecoration(
              color: palette.modal,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: palette.border),
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícone
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: palette.module.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: palette.module,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  widget.module.title,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.module.id,
                  style: TextStyle(
                    color: palette.textMuted,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    final offset = _error
                        ? 8 * (0.5 - (_shakeAnimation.value % 1).abs())
                        : 0.0;
                    return Transform.translate(
                      offset: Offset(offset * 6, 0),
                      child: child,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (i) {
                      final filled = i < _digits.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _error
                              ? Colors.redAccent
                              : filled
                                  ? palette.module
                                  : Colors.transparent,
                          border: Border.all(
                            color: _error
                                ? Colors.redAccent
                                : filled
                                    ? palette.module
                                    : palette.textMuted.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedOpacity(
                  opacity: _error ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    context.watch<ModuleState>().error ?? 'PIN incorreto',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),
                if (_loading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(color: palette.module),
                  )
                else
                  _NumPad(
                    palette: palette,
                    onDigit: _onDigit,
                    onDelete: _onDelete,
                  ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: palette.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

class _NumPad extends StatelessWidget {
  const _NumPad({
    required this.palette,
    required this.onDigit,
    required this.onDelete,
  });

  final EnxosPalette palette;
  final void Function(int) onDigit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    const layout = [
      [1, 2, 3],
      [4, 5, 6],
      [7, 8, 9],
      [-1, 0, -2],
    ];

    return Column(
      children: layout.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              if (key == -1) return const SizedBox(width: 72, height: 56);
              if (key == -2) {
                return _NumKey(
                  palette: palette,
                  onTap: onDelete,
                  child: Icon(
                    Icons.backspace_outlined,
                    size: 20,
                    color: palette.textSecondary,
                  ),
                );
              }
              return _NumKey(
                palette: palette,
                onTap: () => onDigit(key),
                child: Text(
                  '$key',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _NumKey extends StatelessWidget {
  const _NumKey({
    required this.palette,
    required this.child,
    required this.onTap,
  });

  final EnxosPalette palette;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Material(
        color: palette.border.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
            width: 72,
            height: 56,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}