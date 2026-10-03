import 'package:flutter/material.dart';
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

class _ModuleUnlockDialogState extends State<ModuleUnlockDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _moduleIdController;
  final _privateIdController = TextEditingController();
  bool _obscurePrivateId = true;

  @override
  void initState() {
    super.initState();
    _moduleIdController = TextEditingController(text: widget.module.id);
  }

  @override
  void dispose() {
    _moduleIdController.dispose();
    _privateIdController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (!_formKey.currentState!.validate()) return;
    final unlocked = await context.read<ModuleState>().unlock(
      module: widget.module,
      moduleId: _moduleIdController.text,
      privateId: _privateIdController.text,
    );
    if (!mounted) return;
    if (unlocked) {
      Navigator.of(context).pop(true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.read<ModuleState>().error ?? 'Não foi possível desbloquear.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = EnxosTheme.paletteOf(context);
    return AlertDialog(
      backgroundColor: palette.modal,
      title: Text('Desbloquear ${widget.module.title}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Informe as credenciais individuais do módulo ${widget.module.id}.',
              style: TextStyle(color: palette.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _moduleIdController,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'ID do módulo',
                prefixIcon: Icon(Icons.tag),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Informe o ID do módulo.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _privateIdController,
              obscureText: _obscurePrivateId,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'ID privado do módulo',
                prefixIcon: const Icon(Icons.key_outlined),
                suffixIcon: IconButton(
                  tooltip: _obscurePrivateId
                      ? 'Mostrar ID privado'
                      : 'Ocultar ID privado',
                  onPressed: () => setState(
                    () => _obscurePrivateId = !_obscurePrivateId,
                  ),
                  icon: Icon(
                    _obscurePrivateId
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Informe o ID privado do módulo.'
                  : null,
              onFieldSubmitted: (_) => _unlock(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _unlock,
          child: const Text('Desbloquear'),
        ),
      ],
    );
  }
}