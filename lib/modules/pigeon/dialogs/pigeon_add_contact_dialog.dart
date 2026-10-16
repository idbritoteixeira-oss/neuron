import 'package:flutter/material.dart';

import '../../../core/enxos/enxos_theme.dart';

class PigeonAddContactDialog extends StatefulWidget {
  const PigeonAddContactDialog({required this.palette, super.key});

  final EnxosPalette palette;

  @override
  State<PigeonAddContactDialog> createState() => _PigeonAddContactDialogState();
}

class _PigeonAddContactDialogState extends State<PigeonAddContactDialog> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final id = _idController.text.trim();
    if (!RegExp(r'^\d{10}$').hasMatch(id)) {
      setState(() => _error = 'O Pigeon ID deve ter 10 números.');
      return;
    }
    Navigator.of(context).pop((id: id, name: _nameController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.palette.modal,
      title: Text(
        'Adicionar contato',
        style: TextStyle(color: widget.palette.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _idController,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 10,
            decoration: const InputDecoration(
              labelText: 'Pigeon ID',
              counterText: '',
            ),
            style: TextStyle(color: widget.palette.textPrimary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            maxLength: 40,
            decoration: const InputDecoration(
              labelText: 'Nome para este contato (opcional)',
            ),
            style: TextStyle(color: widget.palette.textPrimary),
          ),
          if (_error != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Adicionar')),
      ],
    );
  }
}
