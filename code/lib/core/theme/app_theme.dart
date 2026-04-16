import 'package:flutter/material.dart';

/// Bear-style theme tokens
class AppThemeTokens {
  final Color colorBg;
  final Color colorSurface;
  final Color colorSurfaceHover;
  final Color colorText;
  final Color colorTextMuted;
  final Color colorTextDisabled;
  final Color colorAccent;
  final Color colorAccentMuted;
  final Color colorBorder;
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
    required this.colorText,
    required this.colorTextMuted,
    required this.colorTextDisabled,
    required this.colorAccent,
    required this.colorAccentMuted,
    required this.colorBorder,
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
    'redGraphite',
    'shibuya',
    'darkGraphite',
    'dieciOLED',
    'nord',
  ];

  // Red Graphite (light, default)
  static const redGraphite = AppThemeTokens(
    colorBg: Color(0xFFFFFFFF),
    colorSurface: Color(0xFFF7F7F7),
    colorSurfaceHover: Color(0xFFEEEEEE),
    colorText: Color(0xFF333333),
    colorTextMuted: Color(0xFF888888),
    colorTextDisabled: Color(0xFFBBBBBB),
    colorAccent: Color(0xFFD14C3E),
    colorAccentMuted: Color(0xFFFFE4E1),
    colorBorder: Color(0xFFE5E5E5),
    syntaxHeading: Color(0xFFD14C3E),
    syntaxBold: Color(0xFF333333),
    syntaxCode: Color(0xFFB44B41),
    syntaxLink: Color(0xFFB44B41),
    syntaxQuote: Color(0xFF888888),
    syntaxComment: Color(0xFFBBBBBB),
    brightness: Brightness.light,
  );

  // Shibuya (light, warm beige)
  static const shibuya = AppThemeTokens(
    colorBg: Color(0xFFFBF9F5),
    colorSurface: Color(0xFFF0EDE6),
    colorSurfaceHover: Color(0xFFE8E4DC),
    colorText: Color(0xFF3D3D3D),
    colorTextMuted: Color(0xFF888888),
    colorTextDisabled: Color(0xFFBBBBBB),
    colorAccent: Color(0xFFC97B63),
    colorAccentMuted: Color(0xFFF5E6E0),
    colorBorder: Color(0xFFE0DCD3),
    syntaxHeading: Color(0xFFC97B63),
    syntaxBold: Color(0xFF3D3D3D),
    syntaxCode: Color(0xFFB86F5A),
    syntaxLink: Color(0xFFB86F5A),
    syntaxQuote: Color(0xFF888888),
    syntaxComment: Color(0xFFBBBBBB),
    brightness: Brightness.light,
  );

  // Dark Graphite (dark)
  static const darkGraphite = AppThemeTokens(
    colorBg: Color(0xFF1E1E1E),
    colorSurface: Color(0xFF2A2A2A),
    colorSurfaceHover: Color(0xFF333333),
    colorText: Color(0xFFE0E0E0),
    colorTextMuted: Color(0xFF888888),
    colorTextDisabled: Color(0xFF555555),
    colorAccent: Color(0xFFE85D4E),
    colorAccentMuted: Color(0xFF3D2A28),
    colorBorder: Color(0xFF3A3A3A),
    syntaxHeading: Color(0xFFE85D4E),
    syntaxBold: Color(0xFFE0E0E0),
    syntaxCode: Color(0xFFD97B6F),
    syntaxLink: Color(0xFFD97B6F),
    syntaxQuote: Color(0xFF888888),
    syntaxComment: Color(0xFF666666),
    brightness: Brightness.dark,
  );

  // Dieci OLED (true black)
  static const dieciOLED = AppThemeTokens(
    colorBg: Color(0xFF000000),
    colorSurface: Color(0xFF000000),
    colorSurfaceHover: Color(0xFF1C1C1C),
    colorText: Color(0xFFE0E0E0),
    colorTextMuted: Color(0xFF888888),
    colorTextDisabled: Color(0xFF444444),
    colorAccent: Color(0xFFFF9500),
    colorAccentMuted: Color(0xFF2A1F00),
    colorBorder: Color(0xFF2A2A2A),
    syntaxHeading: Color(0xFFFF9500),
    syntaxBold: Color(0xFFE0E0E0),
    syntaxCode: Color(0xFFFFAA33),
    syntaxLink: Color(0xFFFFAA33),
    syntaxQuote: Color(0xFF888888),
    syntaxComment: Color(0xFF555555),
    brightness: Brightness.dark,
  );

  // Nord (dark, cool tones)
  static const nord = AppThemeTokens(
    colorBg: Color(0xFF2E3440),
    colorSurface: Color(0xFF3B4252),
    colorSurfaceHover: Color(0xFF434C5E),
    colorText: Color(0xFFECEFF4),
    colorTextMuted: Color(0xFFD8DEE9),
    colorTextDisabled: Color(0xFF616E88),
    colorAccent: Color(0xFF88C0D0),
    colorAccentMuted: Color(0xFF2E3D47),
    colorBorder: Color(0xFF4C566A),
    syntaxHeading: Color(0xFF88C0D0),
    syntaxBold: Color(0xFFECEFF4),
    syntaxCode: Color(0xFF8FBCBB),
    syntaxLink: Color(0xFF8FBCBB),
    syntaxQuote: Color(0xFFD8DEE9),
    syntaxComment: Color(0xFF616E88),
    brightness: Brightness.dark,
  );

  /// Migrate legacy theme names
  static String migrateName(String name) {
    return switch (name) {
      'cadmiumLight' => 'redGraphite',
      'oneDark' => 'darkGraphite',
      'materialDark' => 'dieciOLED',
      'graphiteLight' => 'redGraphite',
      'ulyssesLight' => 'shibuya',
      _ => name,
    };
  }

  /// Get theme tokens by name
  static AppThemeTokens getTokens(String name) {
    return switch (name) {
      'redGraphite' => redGraphite,
      'shibuya' => shibuya,
      'darkGraphite' => darkGraphite,
      'dieciOLED' => dieciOLED,
      'nord' => nord,
      _ => redGraphite,
    };
  }

  /// Build ThemeData from tokens
  static ThemeData getTheme(String name) {
    final tokens = getTokens(name);
    return ThemeData(
      useMaterial3: true,
      brightness: tokens.brightness,
      scaffoldBackgroundColor: tokens.colorBg,
      colorScheme: ColorScheme(
        brightness: tokens.brightness,
        primary: tokens.colorAccent,
        onPrimary: tokens.brightness == Brightness.dark ? Colors.black : Colors.white,
        secondary: tokens.colorAccent,
        onSecondary: tokens.brightness == Brightness.dark ? Colors.black : Colors.white,
        error: const Color(0xFFE53935),
        onError: Colors.white,
        surface: tokens.colorSurface,
        onSurface: tokens.colorText,
      ),
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: tokens.colorText, fontSize: 15),
        bodyLarge: TextStyle(color: tokens.colorText, fontSize: 17),
      ),
      menuButtonTheme: MenuButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: tokens.colorText),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return tokens.colorSurfaceHover;
            }
            return Colors.transparent;
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: tokens.colorText),
      ),
      dividerColor: tokens.colorBorder,
      iconTheme: IconThemeData(color: tokens.colorTextMuted),
    );
  }
}
