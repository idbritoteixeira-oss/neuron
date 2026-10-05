import 'package:flutter/material.dart';

import '../../core/enxos/dashboard_screen.dart';
import '../../core/enxos/enx_module.dart';

class FreeMarketScreen extends StatelessWidget {
  const FreeMarketScreen({required this.onLauncherTap, super.key});

  final EnxosLauncherCallback onLauncherTap;

  @override
  Widget build(BuildContext context) =>
      ModuleHomeScreen(
        module: EnxModule.freemarket,
        onLauncherTap: onLauncherTap,
      );
}