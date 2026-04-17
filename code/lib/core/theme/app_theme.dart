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
    'pinkBlossom',
    'skyBlue',
    'darkGraphite',
    'dieciOLED',
    'nord',
    'midnight',
  ];

  static const List<String> lightThemeNames = [
    'redGraphite',
    'shibuya',
    'pinkBlossom',
    'skyBlue',
  ];

  static const List<String> darkThemeNames = [
    'darkGraphite',
    'dieciOLED',
    'nord',
    'midnight',
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

  // Pink Blossom (light)
  static const pinkBlossom = AppThemeTokens(
    colorBg: Color(0xFFFFFAFB),
    colorSurface: Color(0xFFFFF0F3),
    colorSurfaceHover: Color(0xFFFFE4E9),
    colorText: Color(0xFF2D1B21),
    colorTextMuted: Color(0xFF6B5159),
    colorTextDisabled: Color(0xFFB39BA3),
    colorAccent: Color(0xFFD81B60),
    colorAccentMuted: Color(0xFFFCE4EC),
    colorBorder: Color(0xFFFFE0E8),
    syntaxHeading: Color(0xFFD81B60),
    syntaxBold: Color(0xFF2D1B21),
    syntaxCode: Color(0xFFC2185B),
    syntaxLink: Color(0xFFD81B60),
    syntaxQuote: Color(0xFF6B5159),
    syntaxComment: Color(0xFFB39BA3),
    brightness: Brightness.light,
  );

  // Sky Blue (light)
  static const skyBlue = AppThemeTokens(
    colorBg: Color(0xFFFAFCFF),
    colorSurface: Color(0xFFF0F6FC),
    colorSurfaceHover: Color(0xFFE6F1FA),
    colorText: Color(0xFF1C2D3A),
    colorTextMuted: Color(0xFF4A5F6F),
    colorTextDisabled: Color(0xFF8A9BA8),
    colorAccent: Color(0xFF1976D2),
    colorAccentMuted: Color(0xFFE3F2FD),
    colorBorder: Color(0xFFD6E9F8),
    syntaxHeading: Color(0xFF1976D2),
    syntaxBold: Color(0xFF1C2D3A),
    syntaxCode: Color(0xFF1565C0),
    syntaxLink: Color(0xFF1976D2),
    syntaxQuote: Color(0xFF4A5F6F),
    syntaxComment: Color(0xFF8A9BA8),
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

  // Midnight (dark, deep blue)
  static const midnight = AppThemeTokens(
    colorBg: Color(0xFF0D1117),
    colorSurface: Color(0xFF161B22),
    colorSurfaceHover: Color(0xFF21262D),
    colorText: Color(0xFFC9D1D9),
    colorTextMuted: Color(0xFF8B949E),
    colorTextDisabled: Color(0xFF484F58),
    colorAccent: Color(0xFF58A6FF),
    colorAccentMuted: Color(0xFF1C2D41),
    colorBorder: Color(0xFF30363D),
    syntaxHeading: Color(0xFF58A6FF),
    syntaxBold: Color(0xFFC9D1D9),
    syntaxCode: Color(0xFF79C0FF),
    syntaxLink: Color(0xFF58A6FF),
    syntaxQuote: Color(0xFF8B949E),
    syntaxComment: Color(0xFF6E7681),
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
      'pinkBlossom' => pinkBlossom,
      'skyBlue' => skyBlue,
      'darkGraphite' => darkGraphite,
      'dieciOLED' => dieciOLED,
      'nord' => nord,
      'midnight' => midnight,
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
          minimumSize: WidgetStatePropertyAll(Size(0, 36)),
          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerColor: tokens.colorBorder,
      iconTheme: IconThemeData(color: tokens.colorTextMuted),
    );
  }
}
