import 'package:flutter/material.dart';

class AppThemeTokens {
  final Color colorBg;
  final Color colorSurface;
  final Color colorSurfaceHover;
  final Color colorBorder;
  final Color colorText;
  final Color colorTextMuted;
  final Color colorAccent;
  final Color colorAccentMuted;
  final Color syntaxHeading;
  final Color syntaxBold;
  final Color syntaxCode;
  final Color syntaxLink;
  final Color syntaxQuote;
  final Color syntaxComment;
  final Brightness brightness;

  const AppThemeTokens({
    required this.colorBg,
    required this.colorSurface,
    required this.colorSurfaceHover,
    required this.colorBorder,
    required this.colorText,
    required this.colorTextMuted,
    required this.colorAccent,
    required this.colorAccentMuted,
    required this.syntaxHeading,
    required this.syntaxBold,
    required this.syntaxCode,
    required this.syntaxLink,
    required this.syntaxQuote,
    required this.syntaxComment,
    required this.brightness,
  });
}

class AppTheme {
  AppTheme._();

  static const List<String> themeNames = [
    'snow', 'latte', 'dusk', 'midnight', 'forest',
  ];

  static const Map<String, String> _legacyThemeMap = {
    'cadmiumLight': 'snow',
    'graphiteLight': 'snow',
    'ulyssesLight': 'latte',
    'oneDark': 'dusk',
    'materialDark': 'midnight',
  };

  static String migrateName(String name) =>
      _legacyThemeMap[name] ?? (themeNames.contains(name) ? name : 'snow');

  static const Map<String, AppThemeTokens> _tokens = {
    'snow': AppThemeTokens(
      brightness: Brightness.light,
      colorBg: Color(0xFFFFFFFF),
      colorSurface: Color(0xFFF7F7F8),
      colorSurfaceHover: Color(0xFFEFEFEF),
      colorBorder: Color(0xFFE5E5E5),
      colorText: Color(0xFF1A1A1A),
      colorTextMuted: Color(0xFF9B9B9B),
      colorAccent: Color(0xFF2563EB),
      colorAccentMuted: Color(0x1A2563EB),
      syntaxHeading: Color(0xFF1D4ED8),
      syntaxBold: Color(0xFF1A1A1A),
      syntaxCode: Color(0xFFD97706),
      syntaxLink: Color(0xFF2563EB),
      syntaxQuote: Color(0xFF6B7280),
      syntaxComment: Color(0xFF9CA3AF),
    ),
    'latte': AppThemeTokens(
      brightness: Brightness.light,
      colorBg: Color(0xFFFAF7F2),
      colorSurface: Color(0xFFF0EBE3),
      colorSurfaceHover: Color(0xFFE8E0D5),
      colorBorder: Color(0xFFDDD5C8),
      colorText: Color(0xFF2C2416),
      colorTextMuted: Color(0xFF9C8E7E),
      colorAccent: Color(0xFFC2692A),
      colorAccentMuted: Color(0x1AC2692A),
      syntaxHeading: Color(0xFFA0522D),
      syntaxBold: Color(0xFF2C2416),
      syntaxCode: Color(0xFF6B8E23),
      syntaxLink: Color(0xFFC2692A),
      syntaxQuote: Color(0xFF8B7355),
      syntaxComment: Color(0xFFA89880),
    ),
    'dusk': AppThemeTokens(
      brightness: Brightness.dark,
      colorBg: Color(0xFF1E2330),
      colorSurface: Color(0xFF171C28),
      colorSurfaceHover: Color(0xFF252B3A),
      colorBorder: Color(0xFF2E3548),
      colorText: Color(0xFFCDD6F4),
      colorTextMuted: Color(0xFF6C7086),
      colorAccent: Color(0xFF89B4FA),
      colorAccentMuted: Color(0x1A89B4FA),
      syntaxHeading: Color(0xFFCBA6F7),
      syntaxBold: Color(0xFFCDD6F4),
      syntaxCode: Color(0xFFA6E3A1),
      syntaxLink: Color(0xFF89B4FA),
      syntaxQuote: Color(0xFF6C7086),
      syntaxComment: Color(0xFF585B70),
    ),
    'midnight': AppThemeTokens(
      brightness: Brightness.dark,
      colorBg: Color(0xFF0D0D0D),
      colorSurface: Color(0xFF141414),
      colorSurfaceHover: Color(0xFF1F1F1F),
      colorBorder: Color(0xFF2A2A2A),
      colorText: Color(0xFFE8E8E8),
      colorTextMuted: Color(0xFF555555),
      colorAccent: Color(0xFF60A5FA),
      colorAccentMuted: Color(0x1A60A5FA),
      syntaxHeading: Color(0xFFA78BFA),
      syntaxBold: Color(0xFFE8E8E8),
      syntaxCode: Color(0xFF34D399),
      syntaxLink: Color(0xFF60A5FA),
      syntaxQuote: Color(0xFF555555),
      syntaxComment: Color(0xFF404040),
    ),
    'forest': AppThemeTokens(
      brightness: Brightness.dark,
      colorBg: Color(0xFF1A2318),
      colorSurface: Color(0xFF141C12),
      colorSurfaceHover: Color(0xFF1F2B1D),
      colorBorder: Color(0xFF2A3828),
      colorText: Color(0xFFD4E6D0),
      colorTextMuted: Color(0xFF5A7055),
      colorAccent: Color(0xFF6DBF67),
      colorAccentMuted: Color(0x1A6DBF67),
      syntaxHeading: Color(0xFFA8D5A2),
      syntaxBold: Color(0xFFD4E6D0),
      syntaxCode: Color(0xFFF0C060),
      syntaxLink: Color(0xFF6DBF67),
      syntaxQuote: Color(0xFF5A7055),
      syntaxComment: Color(0xFF3D5238),
    ),
  };

  static AppThemeTokens getTokens(String name) =>
      _tokens[migrateName(name)] ?? _tokens['snow']!;

  static ThemeData getTheme(String name) {
    final t = getTokens(name);
    return _buildTheme(t);
  }

  static ThemeData _buildTheme(AppThemeTokens t) {
    return ThemeData(
      useMaterial3: true,
      brightness: t.brightness,
      scaffoldBackgroundColor: t.colorBg,
      colorScheme: ColorScheme(
        brightness: t.brightness,
        primary: t.colorAccent,
        onPrimary: t.brightness == Brightness.dark ? Colors.black : Colors.white,
        secondary: t.colorAccent,
        onSecondary: t.brightness == Brightness.dark ? Colors.black : Colors.white,
        error: Colors.red,
        onError: Colors.white,
        surface: t.colorSurface,
        onSurface: t.colorText,
      ),
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: t.colorText),
        bodyLarge: TextStyle(color: t.colorText),
      ),
      menuButtonTheme: MenuButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: t.colorText),
          ),
        ),
      ),
      dividerColor: t.colorBorder,
      iconTheme: IconThemeData(color: t.colorTextMuted),
    );
  }
}
