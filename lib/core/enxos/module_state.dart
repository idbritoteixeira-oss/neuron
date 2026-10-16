import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'enx_module.dart'; // Mantém o import correto do enum

abstract interface class ModuleAuthRepository {
  Future<bool> authenticate({
    required EnxModule module,
    required String moduleId,
    required String privateId,
  });
}

class NetworkModuleAuthRepository implements ModuleAuthRepository {
  // Endpoint real do backend do Pigeon
  static const String _pigeonLoginUrl = 'https://tts.enxos.online/f/p1319.php';

  @override
  Future<bool> authenticate({
    required EnxModule module,
    required String moduleId,
    required String privateId,
  }) async {
    if (module != EnxModule.pigeon) {
      return false;
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
          'pigeon_id': cleanId,
          'pin': cleanPin,
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

// ---------------------------------------------------------
// FALTAVA ESTA CLASSE NO SEU FICHEIRO MODULE_STATE.DART
// ---------------------------------------------------------
class ModuleState extends ChangeNotifier {
  ModuleState(this._repository);

  final ModuleAuthRepository _repository;
  final Set<EnxModule> _unlockedModules = {};
  String? _error;

  String? get error => _error;
  int get unlockedCount => _unlockedModules.length;

  bool isUnlocked(EnxModule module) => _unlockedModules.contains(module);

  Future<bool> unlock({
    required EnxModule module,
    required String moduleId,
    required String privateId,
  }) async {
    _error = null;
    if (moduleId.trim().isEmpty || privateId.isEmpty) {
      _error = 'Informe o ID e o PIN do módulo.';
      notifyListeners();
      return false;
    }

    try {
      final authenticated = await _repository.authenticate(
        module: module,
        moduleId: moduleId.trim(),
        privateId: privateId,
      );
      if (!authenticated) {
        _error = 'As credenciais de ${module.title} não foram validadas.';
        notifyListeners();
        return false;
      }

      _unlockedModules.add(module);
      notifyListeners();
      return true;
    } catch (_) {
      _error = 'Não foi possível validar o acesso ao módulo.';
      notifyListeners();
      return false;
    }
  }

  void lock(EnxModule module) {
    _unlockedModules.remove(module);
    notifyListeners();
  }

  void clear() {
    _unlockedModules.clear();
    _error = null;
    notifyListeners();
  }
}
