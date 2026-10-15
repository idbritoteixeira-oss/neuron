import 'package:flutter/material.dart';

import '../../../core/enxos/enxos_theme.dart';

class PigeonTabBar extends StatelessWidget {
  const PigeonTabBar({
    required this.controller,
    required this.primary,
    required this.palette,
    super.key,
  });

  final TabController controller;
  final Color primary;
  final EnxosPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.border, width: 1)),
      ),
      child: TabBar(
        controller: controller,
        labelColor: primary,
        unselectedLabelColor: palette.textSecondary,
        indicatorColor: primary,
        indicatorWeight: 2.5,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Mensagens'),
          Tab(text: 'Contatos'),
          Tab(text: 'Feed'),
          Tab(text: 'PTT'),
        ],
      ),
    );
  }
}
