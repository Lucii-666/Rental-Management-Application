import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Light palette (Emerald & Amber) ───────────────────────────────────────
  static const Color primaryColor    = Color(0xFF059669);
  static const Color secondaryColor  = Color(0xFF065F46);
  static const Color accentColor     = Color(0xFFF59E0B);
  static const Color backgroundColor = Color(0xFFF0FDF4);
  static const Color surfaceColor    = Color(0xFFFFFFFF);
  static const Color textColor       = Color(0xFF064E3B);
  static const Color lightTextColor  = Color(0xFF6B7280);

  // ── Dark palette ───────────────────────────────────────────────────────────
  static const Color darkPrimaryColor    = Color(0xFF34D399);
  static const Color darkSecondaryColor  = Color(0xFF6EE7B7);
  static const Color darkAccentColor     = Color(0xFFFBBF24);
  static const Color darkBackgroundColor = Color(0xFF0F1B17);
  static const Color darkSurfaceColor    = Color(0xFF1A2E27);
  static const Color darkTextColor       = Color(0xFFE2E8F0);
  static const Color darkLightTextColor  = Color(0xFF94A3B8);

  // ── Context-aware color helpers ────────────────────────────────────────────
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color primary(BuildContext context) =>
      isDark(context) ? darkPrimaryColor : primaryColor;

  static Color secondary(BuildContext context) =>
      isDark(context) ? darkSecondaryColor : secondaryColor;

  static Color accent(BuildContext context) =>
      isDark(context) ? darkAccentColor : accentColor;

  static Color bg(BuildContext context) =>
      isDark(context) ? darkBackgroundColor : backgroundColor;

  static Color surface(BuildContext context) =>
      isDark(context) ? darkSurfaceColor : surfaceColor;

  static Color text(BuildContext context) =>
      isDark(context) ? darkTextColor : textColor;

  static Color subtext(BuildContext context) =>
      isDark(context) ? darkLightTextColor : lightTextColor;

  static Color card(BuildContext context) =>
      isDark(context) ? darkSurfaceColor : surfaceColor;

  static Color dividerColor(BuildContext context) =>
      isDark(context) ? Colors.white12 : Colors.grey.shade200;

  static Color shimmer(BuildContext context) =>
      isDark(context) ? Colors.white10 : Colors.black.withValues(alpha: 0.04);

  static BoxShadow softShadow(BuildContext context) => BoxShadow(
        color: isDark(context)
            ? Colors.black26
            : Colors.black.withValues(alpha: 0.06),
        blurRadius: 12,
        offset: const Offset(0, 4),
      );

  // ── Input decoration helper ─────────────────────────────────────────────
  static InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }

  // ── Light theme ────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: surfaceColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        prefixIconColor: primaryColor,
        labelStyle: const TextStyle(color: lightTextColor),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: DividerThemeData(color: Colors.grey.shade200, thickness: 1),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
    );
  }

  // ── Dark theme ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimaryColor,
        secondary: darkSecondaryColor,
        tertiary: darkAccentColor,
        surface: darkSurfaceColor,
        onPrimary: Color(0xFF0F1B17),
        onSecondary: Color(0xFF0F1B17),
        onSurface: darkTextColor,
      ),
      scaffoldBackgroundColor: darkBackgroundColor,
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: darkTextColor,
        displayColor: darkTextColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackgroundColor,
        foregroundColor: darkTextColor,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimaryColor,
          foregroundColor: const Color(0xFF0F1B17),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkTextColor,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: darkPrimaryColor.withValues(alpha: 0.3)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: darkPrimaryColor.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkPrimaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        prefixIconColor: darkPrimaryColor,
        labelStyle: const TextStyle(color: darkLightTextColor),
      ),
      cardTheme: CardThemeData(
        color: darkSurfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Colors.white10, thickness: 1),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: darkPrimaryColor,
        foregroundColor: Color(0xFF0F1B17),
        elevation: 2,
      ),
    );
  }
}
