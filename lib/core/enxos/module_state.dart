import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'enx_module.dart'; // Mantém o import correto do enum

abstract interface class ModuleAuthRepository {
  Future<ModuleAuthResult> authenticate({
    required EnxModule module,
    required String moduleId,
    required String privateId,
  });
}

class ModuleAuthResult {
  const ModuleAuthResult({required this.authenticated, this.sessionCookie});

  final bool authenticated;
  final String? sessionCookie;
}

class NetworkModuleAuthRepository implements ModuleAuthRepository {
  // Endpoint real do backend do Pigeon
  static const String _pigeonLoginUrl = 'https://tts.enxos.online/f/p1319.php';

  @override
  Future<ModuleAuthResult> authenticate({
    required EnxModule module,
    required String moduleId,
    required String privateId,
  }) async {
    if (module != EnxModule.pigeon) {
      return const ModuleAuthResult(authenticated: false);
    }

    final cleanId = moduleId.trim();
    final cleanPin = privateId.trim();

    if (cleanId.isEmpty || cleanPin.isEmpty) {
      return const ModuleAuthResult(authenticated: false);
    }

    try {
      final response = await http
          .post(
            Uri.parse(_pigeonLoginUrl),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {'action': 'login', 'pigeon_id': cleanId, 'pin': cleanPin},
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final success = data['success'] ?? false;
        return ModuleAuthResult(
          authenticated: success == true,
          sessionCookie: _cookieHeader(response.headers['set-cookie']),
        );
      }
      return const ModuleAuthResult(authenticated: false);
    } catch (_) {
      return const ModuleAuthResult(authenticated: false);
    }
  }

  String? _cookieHeader(String? setCookie) {
    if (setCookie == null || setCookie.isEmpty) return null;
    final cookies = setCookie
        .split(RegExp(r',\s*(?=[A-Za-z0-9_-]+=)'))
        .map((cookie) => cookie.split(';').first.trim())
        .where((cookie) => cookie.contains('=') && !cookie.startsWith('='))
        .toSet();
    return cookies.isEmpty ? null : cookies.join('; ');
  }
}

// ---------------------------------------------------------
// FALTAVA ESTA CLASSE NO SEU FICHEIRO MODULE_STATE.DART
// ---------------------------------------------------------
class ModuleState extends ChangeNotifier {
  ModuleState(this._repository);

  final ModuleAuthRepository _repository;
  final Set<EnxModule> _unlockedModules = {};
  final Map<EnxModule, String> _moduleIds = {};
  final Map<EnxModule, String> _sessionCookies = {};
  String? _error;

  String? get error => _error;
  int get unlockedCount => _unlockedModules.length;

  bool isUnlocked(EnxModule module) => _unlockedModules.contains(module);
  String? moduleIdFor(EnxModule module) => _moduleIds[module];
  String? sessionCookieFor(EnxModule module) => _sessionCookies[module];

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
      final result = await _repository.authenticate(
        module: module,
        moduleId: moduleId.trim(),
        privateId: privateId,
      );
      if (!result.authenticated) {
        _error = 'As credenciais de ${module.title} não foram validadas.';
        notifyListeners();
        return false;
      }

      _unlockedModules.add(module);
      _moduleIds[module] = moduleId.trim();
      final cookie = result.sessionCookie;
      if (cookie == null || cookie.isEmpty) {
        _sessionCookies.remove(module);
      } else {
        _sessionCookies[module] = cookie;
      }
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
    _moduleIds.remove(module);
    _sessionCookies.remove(module);
    notifyListeners();
  }

  void clear() {
    _unlockedModules.clear();
    _moduleIds.clear();
    _sessionCookies.clear();
    _error = null;
    notifyListeners();
  }
}
