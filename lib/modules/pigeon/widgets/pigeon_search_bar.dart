import 'package:flutter/material.dart';

import '../../../core/enxos/enxos_theme.dart';

class PigeonSearchBar extends StatelessWidget {
  const PigeonSearchBar({
    required this.controller,
    required this.primary,
    required this.palette,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final Color primary;
  final EnxosPalette palette;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border.withValues(alpha: 0.7)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        cursorColor: Colors.white,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          filled: false,
          fillColor: Colors.transparent,
          hintText: 'Pesquisar...',
          hintStyle: const TextStyle(color: Colors.white, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.white, size: 18),
          prefixIconConstraints: const BoxConstraints(minWidth: 32),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpar busca',
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  icon: const Icon(Icons.close, color: Colors.white, size: 17),
                ),
          suffixIconConstraints: const BoxConstraints(minWidth: 36),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}
