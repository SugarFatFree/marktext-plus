import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const List<String> themeNames = [
    'cadmiumLight', 'oneDark', 'materialDark', 'graphiteLight', 'ulyssesLight',
  ];

  static final Map<String, ThemeData> themes = {
    'cadmiumLight': _buildTheme(
      brightness: Brightness.light,
      background: const Color(0xFFFFFFFF),
      foreground: const Color(0xFF333333),
      primary: const Color(0xFF4CAF50),
      surface: const Color(0xFFF5F5F5),
    ),
    'oneDark': _buildTheme(
      brightness: Brightness.dark,
      background: const Color(0xFF282C34),
      foreground: const Color(0xFFABB2BF),
      primary: const Color(0xFF61AFEF),
      surface: const Color(0xFF21252B),
    ),
    'materialDark': _buildTheme(
      brightness: Brightness.dark,
      background: const Color(0xFF212121),
      foreground: const Color(0xFFFFFFFF),
      primary: const Color(0xFF82B1FF),
      surface: const Color(0xFF303030),
    ),
    'graphiteLight': _buildTheme(
      brightness: Brightness.light,
      background: const Color(0xFFF5F5F5),
      foreground: const Color(0xFF333333),
      primary: const Color(0xFF607D8B),
      surface: const Color(0xFFEEEEEE),
    ),
    'ulyssesLight': _buildTheme(
      brightness: Brightness.light,
      background: const Color(0xFFFAFAFA),
      foreground: const Color(0xFF414141),
      primary: const Color(0xFF2196F3),
      surface: const Color(0xFFF0F0F0),
    ),
  };

  static ThemeData getTheme(String name) {
    return themes[name] ?? themes['cadmiumLight']!;
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color foreground,
    required Color primary,
    required Color surface,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: brightness == Brightness.dark ? Colors.black : Colors.white,
        secondary: primary,
        onSecondary: brightness == Brightness.dark ? Colors.black : Colors.white,
        error: Colors.red,
        onError: Colors.white,
        surface: surface,
        onSurface: foreground,
      ),
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: foreground),
        bodyLarge: TextStyle(color: foreground),
      ),
      // Ensure menu items use normal weight by default (not Material3 w500)
      menuButtonTheme: MenuButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: foreground),
          ),
        ),
      ),
      dividerColor: foreground.withValues(alpha: 0.12),
      iconTheme: IconThemeData(color: foreground.withValues(alpha: 0.7)),
    );
  }
}
