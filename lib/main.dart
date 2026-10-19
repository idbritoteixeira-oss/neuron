import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';

import 'core/enxos/auth_repository.dart';
import 'core/enxos/auth_state.dart';
import 'core/enxos/enxos_app.dart';
import 'core/enxos/enxos_ui_state.dart';
import 'core/enxos/enxos_watercolor_state.dart';
import 'core/enxos/module_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Mantém um fallback visível caso um widget falhe durante a construção.
  ErrorWidget.builder = (_) => const ColoredBox(
    color: Color(0xFFF4F6F8),
    child: SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Não foi possível abrir esta tela. Feche e abra o aplicativo novamente.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF192E38), fontSize: 16),
          ),
        ),
      ),
    ),
  );

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      FlutterForegroundTask.initCommunicationPort();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'enxOS inicialização',
          context: ErrorDescription(
            'ao inicializar o canal do serviço em primeiro plano',
          ),
        ),
      );
    }
  }

  // Não aguarde plugins ou armazenamento local antes de montar a primeira tela.
  final uiState = EnxosUiState();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<EnxosUiState>.value(value: uiState),
        ChangeNotifierProvider(create: (_) => EnxosWatercolorState()..start()),
        ChangeNotifierProvider(
          create: (_) => AuthState(NetworkEnxosAuthRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => ModuleState(NetworkModuleAuthRepository()),
        ),
      ],
      child: const EnxosApp(),
    ),
  );
  unawaited(uiState.restore());
}
