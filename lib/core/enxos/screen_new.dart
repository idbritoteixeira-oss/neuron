import 'package:flutter/material.dart';

import 'enxos_shell.dart';
import 'enxos_theme.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = EnxosTheme.paletteOf(context);

    return EnxosShell(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Criar Identidade',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Módulo de registo em desenvolvimento para o ecossistema.',
                  style: TextStyle(color: palette.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Voltar ao Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
