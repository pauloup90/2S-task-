import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color brandGold = Color(0xFFE58A13);
  static const Color brandGoldLight = Color(0xFFFFF7ED);
  static const Color brandDark = Color(0xFF18181B);

  static const Color surfaceWarm = Color(0xFFF8FAFC);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color borderSubtle = Color(0xFFE4E4E7);
  static const Color textPrimary = Color(0xFF18181B);
  static const Color textSecondary = Color(0xFF52525B);
  static const Color textMuted = Color(0xFFA1A1AA);

  static const Color statusQuotationBg = Color(0xFFFEF3C7);
  static const Color statusQuotationText = Color(0xFF92400E);
  static const Color statusConfirmedBg = Color(0xFFDCFCE7);
  static const Color statusConfirmedText = Color(0xFF166534);
  static const Color statusCancelledBg = Color(0xFFF4F4F5);
  static const Color statusCancelledText = Color(0xFF71717A);
  static const Color statusSyncPendingBg = Color(0xFFFFF7ED);
  static const Color statusSyncPendingText = Color(0xFFC2410C);

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerText = Color(0xFFB91C1C);
  static const Color dangerBg = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);

  static ThemeData get lightTheme {
    final radius10 = BorderRadius.circular(10);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: brandGold,
      scaffoldBackgroundColor: surfaceWarm,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandGold,
        primary: brandGold,
        secondary: brandDark,
        surface: surfaceCard,
        onPrimary: Colors.white,
        onSurface: textPrimary,
        error: danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: brandDark,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(color: brandDark, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.2),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderSubtle),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: radius10,
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius10,
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius10,
          borderSide: const BorderSide(color: brandGold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius10,
          borderSide: const BorderSide(color: danger),
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandGold,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: radius10),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandDark,
          side: const BorderSide(color: borderSubtle),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: radius10),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 2,
        indicatorColor: const Color(0xFFFED7AA),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: brandDark)
              : const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary),
        ),
      ),
      dividerTheme: const DividerThemeData(color: borderSubtle, thickness: 1, space: 1),
    );
  }
}
