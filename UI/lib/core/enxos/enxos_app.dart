import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_state.dart';
import 'dashboard_screen.dart';
import 'enxos_theme.dart';
import 'enxos_ui_state.dart';
import 'foreground_service.dart';
import 'login_screen.dart';

class EnxosApp extends StatefulWidget {
  const EnxosApp({super.key});

  @override
  State<EnxosApp> createState() => _EnxosAppState();
}

class _EnxosAppState extends State<EnxosApp> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      ForegroundServiceController.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final uiState = context.watch<EnxosUiState>();
    return MaterialApp(
      title: 'enxOS',
      debugShowCheckedModeBanner: false,
      theme: EnxosTheme.light,
      darkTheme: EnxosTheme.dark,
      themeMode: uiState.themeMode,
      home: Consumer<AuthState>(
        builder: (context, auth, _) {
          if (!auth.isAuthenticated) return const LoginScreen();
          return const DashboardScreen();
        },
      ),
    );
  }
}