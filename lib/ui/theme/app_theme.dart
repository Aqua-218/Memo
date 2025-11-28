import 'package:flutter/material.dart';

import '../../domain/entities/font_size.dart';

/// App theme configuration.
/// 
/// Spec: NFR-002 - Accessibility for elderly users
/// - Large fonts, high contrast, simple design
class AppTheme {
  AppTheme._();

  /// Primary color - calm blue for elderly users.
  static const Color primaryColor = Color(0xFF4A90A4);

  /// Secondary color.
  static const Color secondaryColor = Color(0xFF7CB342);

  /// Error color - visible but not harsh.
  static const Color errorColor = Color(0xFFD32F2F);

  /// Warning color.
  static const Color warningColor = Color(0xFFFFA726);

  /// Success color.
  static const Color successColor = Color(0xFF66BB6A);

  /// Background color - warm white for readability.
  static const Color backgroundColor = Color(0xFFFAFAFA);

  /// Surface color.
  static const Color surfaceColor = Colors.white;

  /// Text colors.
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  /// Creates light theme with specified font size.
  static ThemeData lightTheme(FontSize fontSize) {
    final textTheme = _createTextTheme(fontSize);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: surfaceColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 16,
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 16,
          ),
          side: const BorderSide(color: primaryColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        labelStyle: textTheme.bodyMedium,
        hintStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        extendedPadding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey.shade600,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: textTheme.labelSmall,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: Colors.white,
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: textTheme.bodyLarge,
      ),
    );
  }

  static TextTheme _createTextTheme(FontSize fontSize) {
    final baseSize = fontSize.scaleFactor;

    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 32 * baseSize,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        height: 1.3,
      ),
      displayMedium: TextStyle(
        fontSize: 28 * baseSize,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        height: 1.3,
      ),
      displaySmall: TextStyle(
        fontSize: 24 * baseSize,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        height: 1.3,
      ),
      headlineLarge: TextStyle(
        fontSize: 22 * baseSize,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        height: 1.4,
      ),
      headlineMedium: TextStyle(
        fontSize: 20 * baseSize,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        height: 1.4,
      ),
      headlineSmall: TextStyle(
        fontSize: 18 * baseSize,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        height: 1.4,
      ),
      titleLarge: TextStyle(
        fontSize: 20 * baseSize,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontSize: 18 * baseSize,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        height: 1.4,
      ),
      titleSmall: TextStyle(
        fontSize: 16 * baseSize,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        height: 1.4,
      ),
      bodyLarge: TextStyle(
        fontSize: 18 * baseSize,
        fontWeight: FontWeight.normal,
        color: textPrimary,
        height: 1.6,
      ),
      bodyMedium: TextStyle(
        fontSize: 16 * baseSize,
        fontWeight: FontWeight.normal,
        color: textPrimary,
        height: 1.6,
      ),
      bodySmall: TextStyle(
        fontSize: 14 * baseSize,
        fontWeight: FontWeight.normal,
        color: textSecondary,
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontSize: 16 * baseSize,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        height: 1.4,
      ),
      labelMedium: TextStyle(
        fontSize: 14 * baseSize,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        height: 1.4,
      ),
      labelSmall: TextStyle(
        fontSize: 12 * baseSize,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        height: 1.4,
      ),
    );
  }
}
