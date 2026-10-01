import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';

import 'core/enxos/auth_repository.dart';
import 'core/enxos/auth_state.dart';
import 'core/enxos/enxos_app.dart';
import 'core/enxos/module_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    FlutterForegroundTask.initCommunicationPort();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthState(DemoEnxosAuthRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => ModuleState(DemoModuleAuthRepository()),
        ),
      ],
      child: const EnxosApp(),
    ),
  );
}