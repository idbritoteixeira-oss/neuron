import 'package:flutter/foundation.dart';

import 'enx_module.dart';

abstract interface class ModuleAuthRepository {
  Future<bool> authenticate({
    required EnxModule module,
    required String moduleId,
    required String privateId,
  });
}

/// Validação somente para demonstração offline; não confirma a identidade.
class DemoModuleAuthRepository implements ModuleAuthRepository {
  @override
  Future<bool> authenticate({
    required EnxModule module,
    required String moduleId,
    required String privateId,
  }) async {
    return moduleId.trim() == module.id && privateId.isNotEmpty;
  }
}

/// Mantém as sessões dos módulos separadas da sessão global do enxOS.
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
      _error = 'Informe o ID e o ID privado do módulo.';
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