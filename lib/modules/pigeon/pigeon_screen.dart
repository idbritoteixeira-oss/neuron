import 'package:flutter/material.dart';

import '../../core/enxos/dashboard_screen.dart';
import '../../core/enxos/enx_module.dart';

class PigeonScreen extends StatelessWidget {
  const PigeonScreen({required this.onLauncherTap, super.key});

  final EnxosLauncherCallback onLauncherTap;

  @override
  Widget build(BuildContext context) =>
      ModuleHomeScreen(
        module: EnxModule.pigeon,
    onLauncherTap: onLauncherTap,
      );
}