import 'package:flutter/material.dart';

import '../../core/enxos/dashboard_screen.dart';
import '../../core/enxos/enx_module.dart';

class FreeMarketScreen extends StatelessWidget {
  const FreeMarketScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const ModuleHomeScreen(module: EnxModule.freemarket);
}