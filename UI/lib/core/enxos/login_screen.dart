import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_state.dart';
import 'enxos_shell.dart';
import 'enxos_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _publicIdController = TextEditingController();
  final _privateIdController = TextEditingController();
  bool _obscurePrivateId = true;

  @override
  void dispose() {
    _publicIdController.dispose();
    _privateIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthState>();
    final success = await auth.signIn(
      publicId: _publicIdController.text,
      privateId: _privateIdController.text,
    );
    if (!mounted || success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(auth.error ?? 'Não foi possível entrar.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final palette = EnxosTheme.paletteOf(context);
    return EnxosShell(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),
                  Text(
                    'Sua identidade.\nSeu ecossistema.',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Entre com suas credenciais globais para acessar o enxOS.',
                    style: TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  _DemoNotice(palette: palette),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _publicIdController,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'ID público',
                      hintText: 'id_public',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Informe seu ID público.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _privateIdController,
                    obscureText: _obscurePrivateId,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'ID privado',
                      hintText: 'Sua credencial privada',
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
                        ? 'Informe seu ID privado.'
                        : null,
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: auth.isLoading ? null : _submit,
                      child: auth.isLoading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Acessar enxOS'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'A credencial privada é usada somente durante a validação e não é armazenada nesta demonstração.',
                    style: TextStyle(fontSize: 12, height: 1.5),
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

class _DemoNotice extends StatelessWidget {
  const _DemoNotice({required this.palette});

  final EnxosPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.module.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.module.withValues(alpha: 0.25)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 19),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Modo de demonstração: sem servidor, qualquer par não vazio avança. Não use credenciais reais.',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}