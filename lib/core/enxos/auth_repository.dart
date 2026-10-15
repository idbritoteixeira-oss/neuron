import 'dart:convert';
import 'package:http/http.dart' as http;

abstract interface class EnxosAuthRepository {
  Future<AuthResult> authenticate({
    required String publicId,
    required String privateId, // Na prática, corresponde à senha de segurança exigida pelo backend
  });
}

class AuthResult {
  const AuthResult({required this.authenticated, this.message, this.tokenPortao, this.tokens});

  final bool authenticated;
  final String? message;
  final String? tokenPortao;
  final List<dynamic>? tokens;
}

class NetworkEnxosAuthRepository implements EnxosAuthRepository {
  static const String _loginUrl = 'https://dll.enxos.online/f/d1319.php';

  @override
  Future<AuthResult> authenticate({
    required String publicId,
    required String privateId,
  }) async {
    final pubIdClean = publicId.trim();
    final pwdClean = privateId.trim();

    if (pubIdClean.isEmpty || pwdClean.isEmpty) {
      return const AuthResult(
        authenticated: false,
        message: 'Preencha o ID público e a senha de segurança.',
      );
    }

    try {
      final response = await http.post(
        Uri.parse(_loginUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'action': 'login',
          'id_pub': pubIdClean,
          'password': pwdClean,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final success = data['success'] ?? false;

        if (success) {
          return AuthResult(
            authenticated: true,
            message: data['message'],
            tokenPortao: data['token'],
            tokens: data['dll_tts'],
          );
        } else {
          return AuthResult(
            authenticated: false,
            message: data['message'] ?? 'Credenciais inválidas ou conta inativa.',
          );
        }
      } else {
        return AuthResult(
          authenticated: false,
          message: 'Erro de comunicação com o núcleo (Código ${response.statusCode}).',
        );
      }
    } catch (e) {
      return AuthResult(
        authenticated: false,
        message: 'Falha na conexão de rede: $e',
      );
    }
  }
}
