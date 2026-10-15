import 'package:flutter/foundation.dart';

import 'auth_repository.dart';

class AuthState extends ChangeNotifier {
  AuthState(this._repository);

  final EnxosAuthRepository _repository;

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _publicId;
  String? _error;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get publicId => _publicId;
  String? get error => _error;

  Future<bool> signIn({
    required String publicId,
    required String privateId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.authenticate(
        publicId: publicId.trim(),
        privateId: privateId,
      );
      _isAuthenticated = result.authenticated;
      _publicId = result.authenticated ? publicId.trim() : null;
      _error = result.message;
      return result.authenticated;
    } catch (_) {
      _isAuthenticated = false;
      _publicId = null;
      _error = 'Não foi possível validar a sessão. Tente novamente.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void signOut() {
    _isAuthenticated = false;
    _publicId = null;
    _error = null;
    notifyListeners();
  }
}