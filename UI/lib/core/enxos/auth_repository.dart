/// Interface para ligar a sessão enxOS ao serviço de identidade real.
///
/// A implementação incluída é apenas para demonstração offline. Ela valida
/// campos preenchidos, não comprova identidade e não deve ser usada em produção.
abstract interface class EnxosAuthRepository {
  Future<AuthResult> authenticate({
    required String publicId,
    required String privateId,
  });
}

class AuthResult {
  const AuthResult({required this.authenticated, this.message});

  final bool authenticated;
  final String? message;
}

class DemoEnxosAuthRepository implements EnxosAuthRepository {
  @override
  Future<AuthResult> authenticate({
    required String publicId,
    required String privateId,
  }) async {
    if (publicId.trim().isEmpty || privateId.isEmpty) {
      return const AuthResult(
        authenticated: false,
        message: 'Preencha o ID público e o ID privado.',
      );
    }

    return const AuthResult(authenticated: true);
  }
}