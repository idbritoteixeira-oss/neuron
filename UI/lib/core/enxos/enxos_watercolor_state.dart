import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EnxosWatercolorState extends ChangeNotifier {
  EnxosWatercolorState({http.Client? client}) : _client = client ?? http.Client();

  static final _source = Uri.parse(
    'https://tts.enxos.online/s/r2021.php',
  );
  static const _refreshInterval = Duration(seconds: 12);

  final http.Client _client;
  Timer? _timer;
  Color? _color;
  String? _sourceValue;
  String? _error;
  bool _isConnected = false;
  bool _isRefreshing = false;
  bool _isDisposed = false;

  Color? get color => _color;
  String? get sourceValue => _sourceValue;
  String? get error => _error;
  bool get isConnected => _isConnected;

  void start() {
    if (_timer != null || _isDisposed) return;
    unawaited(refresh());
    _timer = Timer.periodic(_refreshInterval, (_) => unawaited(refresh()));
  }

  Future<void> refresh() async {
    if (_isRefreshing || _isDisposed) return;
    _isRefreshing = true;

    try {
      final response = await _client
          .get(_source)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        throw http.ClientException(
          'A fonte de cor respondeu com HTTP ${response.statusCode}.',
          _source,
        );
      }

      final value = response.body.trim();
      if (value.length < 3) {
        throw const FormatException('Resposta curta demais para definir a cor.');
      }

      final suffix = value.substring(value.length - 3);
      final parsedColor = int.tryParse('FF$suffix$suffix', radix: 16);
      if (parsedColor == null) {
        throw const FormatException(
          'Os três últimos caracteres da resposta não formam uma cor hexadecimal.',
        );
      }

      _color = Color(parsedColor);
      _sourceValue = value;
      _isConnected = true;
      _error = null;
    } catch (error) {
      _isConnected = false;
      _error = error.toString();
    } finally {
      _isRefreshing = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _client.close();
    super.dispose();
  }
}