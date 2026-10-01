import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_state.dart';
import 'dashboard_screen.dart';
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
    return MaterialApp(
      title: 'enxOS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF08111D),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF64E1D4),
          brightness: Brightness.dark,
          surface: const Color(0xFF101C2A),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF101C2A),
          hintStyle: const TextStyle(color: Color(0xFF738498)),
          labelStyle: const TextStyle(color: Color(0xFFA7B7C8)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF24374A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF24374A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF64E1D4), width: 1.5),
          ),
        ),
      ),
      home: Consumer<AuthState>(
        builder: (context, auth, _) {
          if (!auth.isAuthenticated) return const LoginScreen();
          return const DashboardScreen();
        },
      ),
    );
  }
}