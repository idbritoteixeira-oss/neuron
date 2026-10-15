import 'package:flutter/material.dart';

class PigeonSearchBar extends StatelessWidget {
  const PigeonSearchBar({
    required this.controller,
    required this.primary,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final Color primary;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        cursorColor: Colors.white,
        decoration: const InputDecoration(
          hintText: 'Pesquisar...',
          hintStyle: TextStyle(color: Colors.white),
          prefixIcon: Icon(Icons.search, color: Colors.white, size: 18),
          prefixIconConstraints: BoxConstraints(minWidth: 32),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}
