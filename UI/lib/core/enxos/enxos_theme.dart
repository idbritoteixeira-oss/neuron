import 'package:flutter/material.dart';

class EnxosPalette {
  const EnxosPalette({
    required this.page,
    required this.grid,
    required this.card,
    required this.modal,
    required this.borderAvatar,
    required this.buttonHover,
    required this.textPrimary,
    required this.textBody,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.inputBorder,
    required this.input,
    required this.module,
    required this.moduleHover,
    required this.badgeMessage,
    required this.badgeFeed,
    required this.shadow,
  });

  final Color page;
  final Color grid;
  final Color card;
  final Color modal;
  final Color borderAvatar;
  final Color buttonHover;
  final Color textPrimary;
  final Color textBody;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color inputBorder;
  final Color input;
  final Color module;
  final Color moduleHover;
  final Color badgeMessage;
  final Color badgeFeed;
  final Color shadow;

  static const light = EnxosPalette(
    page: Color(0xFFF4F6F8),
    grid: Color(0x0A000000),
    card: Color(0xFFFFFFFF),
    modal: Color(0xFFFFFFFF),
    borderAvatar: Color(0xFFF0F0F0),
    buttonHover: Color(0x0F000000),
    textPrimary: Color(0xFF192E38),
    textBody: Color(0xFF222222),
    textSecondary: Color(0xFF555555),
    textMuted: Color(0xFF888888),
    border: Color(0xFFF0F0F0),
    inputBorder: Color(0xFFE1E8ED),
    input: Color(0xFFFFFFFF),
    module: Color(0xFF192E38),
    moduleHover: Color(0xFF0F1E26),
    badgeMessage: Color(0xFFE41E3F),
    badgeFeed: Color(0xFF5AB31E),
    shadow: Color(0x2E000000),
  );

  static const dark = EnxosPalette(
    page: Color(0xFF0B0C10),
    grid: Color(0x0AFFFFFF),
    card: Color(0xFF14181F),
    modal: Color(0xFF1A202C),
    borderAvatar: Color(0xFF242B35),
    buttonHover: Color(0x14FFFFFF),
    textPrimary: Color(0xFFF1F5F9),
    textBody: Color(0xFFE2E8F0),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF64748B),
    border: Color(0xFF242B35),
    inputBorder: Color(0xFF2D3748),
    input: Color(0xFF0F1217),
    module: Color(0xFF192E38),
    moduleHover: Color(0xFF0F1E26),
    badgeMessage: Color(0xFFE41E3F),
    badgeFeed: Color(0xFF5AB31E),
    shadow: Color(0x80000000),
  );
}

class EnxosTheme {
  const EnxosTheme._();

  static EnxosPalette paletteOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? EnxosPalette.dark
      : EnxosPalette.light;

  static final ThemeData light = _build(
    EnxosPalette.light,
    Brightness.light,
  );

  static final ThemeData dark = _build(
    EnxosPalette.dark,
    Brightness.dark,
  );

  static ThemeData _build(EnxosPalette palette, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: palette.module,
      brightness: brightness,
      surface: palette.card,
    );
    final defaultTextTheme = ThemeData(brightness: brightness).textTheme;

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: defaultTextTheme.apply(
        bodyColor: palette.textBody,
        displayColor: palette.textPrimary,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: palette.card,
      dividerColor: palette.border,
      popupMenuTheme: PopupMenuThemeData(
        color: palette.modal,
        textStyle: TextStyle(color: palette.textBody),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.input,
        hintStyle: TextStyle(color: palette.textMuted),
        labelStyle: TextStyle(color: palette.textSecondary),
        prefixIconColor: palette.textSecondary,
        suffixIconColor: palette.textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.inputBorder, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.inputBorder, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.module, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered)
                ? palette.moduleHover
                : palette.module,
          ),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          overlayColor: WidgetStatePropertyAll(palette.buttonHover),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: palette.module),
      ),
    );
  }
}