import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_state.dart';
import 'enxos_shell.dart';
import 'enxos_theme.dart';
import 'screen_new.dart'; // Rota para o registro de nova identidade

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _publicIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _publicIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthState>();
    final success = await auth.signIn(
      publicId: _publicIdController.text,
      privateId: _passwordController.text,
    );
    if (!mounted || success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(auth.error ?? 'Não foi possível autenticar no núcleo.')),
    );
  }

  // Simulação de gatilho para biometria / PIN rápido de sessão
  Future<void> _authenticateWithBiometrics() async {
    final auth = context.read<AuthState>();
    
    // Aqui no futuro integras o local_auth para ler a impressão digital
    // e recuperar o token/credencial guardado de forma segura no SecureStorage.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Autenticação biométrica ativada para sessões futuras.')),
    );
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
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
                    'Insira as credenciais enxOS.',
                    style: TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _publicIdController,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'ID Público',
                      hintText: 'Ex: 12 caracteres',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Informe o seu ID público.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Senha de Segurança',
                      hintText: 'Sua senha',
                      prefixIcon: const Icon(Icons.key_outlined),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Informe a senha de segurança.'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: auth.isLoading ? null : _submit,
                      child: auth.isLoading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Entrar'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Botão secundário para Biometria / Acesso rápido
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: auth.isLoading ? null : _authenticateWithBiometrics,
                      icon: const Icon(Icons.fingerprint, size: 20),
                      label: const Text('Entrar com Biometria / PIN'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Ainda não tem uma identidade?',
                        style: TextStyle(color: palette.textSecondary, fontSize: 13),
                      ),
                      TextButton(
                        onPressed: _goToRegister,
                        child: const Text('Registar-se'),
                      ),
                    ],
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
