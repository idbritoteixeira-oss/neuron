import 'dart:convert';
import 'package:http/http.dart' as http;
import 'enx_module.dart';
import 'auth_repository.dart'; // Se precisar alinhar estruturas, ou crie a sua interface dedicada

abstract interface class ModuleAuthRepository {
  Future<bool> authenticate({
    required EnxModule module,
    required String moduleId,
    required String privateId, // Corresponde ao PIN no contexto do Pigeon
  });
}

class NetworkModuleAuthRepository implements ModuleAuthRepository {
  // Endpoint real do backend do Pigeon que você compartilhou
  static const String _pigeonLoginUrl = 'https://tts.enxos.online/f/p1319.php';

  @override
  Future<bool> authenticate({
    required EnxModule module,
    required String moduleId,
    required String privateId,
  }) async {
    // Por enquanto focamos estritamente no Pigeon conforme alinhado
    if (module != EnxModule.pigeon) {
      return false; // Outros módulos serão implementados futuramente
    }

    final cleanId = moduleId.trim();
    final cleanPin = privateId.trim();

    if (cleanId.isEmpty || cleanPin.isEmpty) {
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse(_pigeonLoginUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'action': 'login',
          'pigeon_id': cleanId, // Mapeia exatamente para o $_POST['pigeon_id'] / $_POST['id_pru'] do PHP
          'pin': cleanPin,       // Mapeia para o $_POST['pin']
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final success = data['success'] ?? false;
        return success;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
