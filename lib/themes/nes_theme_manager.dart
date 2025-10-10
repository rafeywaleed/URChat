import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';

class NesThemeManager {
  static ThemeData createCustomTheme({
    required int themeIndex,
    required bool isDark,
  }) {
    final baseTheme = flutterNesTheme();

    // Get the color scheme for the selected theme
    final colorScheme = isDark
        ? _getDarkColorScheme(themeIndex)
        : _getLightColorScheme(themeIndex);

    // Create a custom theme that merges NES styling with our color scheme
    return baseTheme.copyWith(
      // Core color properties
      primaryColor: colorScheme.primary,
      scaffoldBackgroundColor: colorScheme.background,
      cardColor: colorScheme.surface,
      dialogBackgroundColor: colorScheme.surface,

      // Color scheme
      colorScheme: colorScheme,

      // App bar theming
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        titleTextStyle: baseTheme.appBarTheme.titleTextStyle?.copyWith(
          color: colorScheme.onPrimary,
        ),
        toolbarTextStyle: baseTheme.appBarTheme.toolbarTextStyle?.copyWith(
          color: colorScheme.onPrimary,
        ),
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),

      // Text theming with proper sizes
      textTheme: baseTheme.textTheme.copyWith(
        titleLarge: baseTheme.textTheme.titleLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: baseTheme.textTheme.titleMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(
          fontSize: 14,
        ),
        bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(
          fontSize: 12,
        ),
        bodySmall: baseTheme.textTheme.bodySmall?.copyWith(
          fontSize: 10,
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  static ColorScheme _getLightColorScheme(int themeIndex) {
    switch (themeIndex) {
      case 1: // MODERN
        return const ColorScheme.light(
          primary: Color(0xFF2E4057),
          primaryContainer: Color(0xFF4A6FA5),
          secondary: Color(0xFF4A6FA5),
          secondaryContainer: Color(0xFF6B8CBC),
          surface: Color(0xFFF8F9FA),
          background: Color(0xFFFFFFFF),
          error: Color(0xFFB00020),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFF212529),
          onBackground: Color(0xFF212529),
          onError: Colors.white,
          brightness: Brightness.light,
        );
      case 2: // ELEGANT
        return const ColorScheme.light(
          primary: Color(0xFF5D737E),
          primaryContainer: Color(0xFF7A8B99),
          secondary: Color(0xFF7A8B99),
          secondaryContainer: Color(0xFF9AA9B5),
          surface: Color(0xFFF8F9FA),
          background: Color(0xFFFFFFFF),
          error: Color(0xFFB00020),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFF3A3A3A),
          onBackground: Color(0xFF3A3A3A),
          onError: Colors.white,
          brightness: Brightness.light,
        );
      case 3: // CUTE
        return const ColorScheme.light(
          primary: Color(0xFFE91E63),
          primaryContainer: Color(0xFFEC407A),
          secondary: Color(0xFFEC407A),
          secondaryContainer: Color(0xFFF06292),
          surface: Color(0xFFFFF5F7),
          background: Color(0xFFFFF9FB),
          error: Color(0xFFB00020),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFF333333),
          onBackground: Color(0xFF333333),
          onError: Colors.white,
          brightness: Brightness.light,
        );
      default: // SIMPLE (Default NES)
        return const ColorScheme.light(
          primary: Color(0xFF000000),
          primaryContainer: Color(0xFF333333),
          secondary: Color(0xFF555555),
          secondaryContainer: Color(0xFF777777),
          surface: Color(0xFFFFFFFF),
          background: Color(0xFFF5F5F5),
          error: Color(0xFFB00020),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFF000000),
          onBackground: Color(0xFF000000),
          onError: Colors.white,
          brightness: Brightness.light,
        );
    }
  }

  static ColorScheme _getDarkColorScheme(int themeIndex) {
    switch (themeIndex) {
      case 1: // MODERN
        return const ColorScheme.dark(
          primary: Color(0xFF4A6FA5),
          primaryContainer: Color(0xFF6B8CBC),
          secondary: Color(0xFF6B8CBC),
          secondaryContainer: Color(0xFF8CA7D4),
          surface: Color.fromARGB(255, 253, 253, 253),
          background: Color.fromARGB(255, 57, 57, 57),
          error: Color(0xFFCF6679),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFFE0E0E0),
          onBackground: Color(0xFFE0E0E0),
          onError: Colors.black,
          brightness: Brightness.dark,
        );
      case 2: // ELEGANT
        return const ColorScheme.dark(
          primary: Color(0xFF7A8B99),
          primaryContainer: Color(0xFF5D737E),
          secondary: Color(0xFF5D737E),
          secondaryContainer: Color(0xFF4A5D66),
          surface: Color(0xFF1E2A32),
          background: Color(0xFF121A21),
          error: Color(0xFFCF6679),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFFE0E3E7),
          onBackground: Color(0xFFE0E3E7),
          onError: Colors.black,
          brightness: Brightness.dark,
        );
      case 3: // CUTE
        return const ColorScheme.dark(
          primary: Color(0xFFEC407A),
          primaryContainer: Color(0xFFF06292),
          secondary: Color(0xFFF06292),
          secondaryContainer: Color(0xFFF48FB1),
          surface: Color(0xFF1E1E2E),
          background: Color(0xFF121212),
          error: Color(0xFFCF6679),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFFE0E0E0),
          onBackground: Color(0xFFE0E0E0),
          onError: Colors.black,
          brightness: Brightness.dark,
        );
      default: // SIMPLE (Default NES)
        return const ColorScheme.dark(
          primary: Color(0xFF333333),
          primaryContainer: Color(0xFF555555),
          secondary: Color(0xFF777777),
          secondaryContainer: Color(0xFF999999),
          surface: Color(0xFF1E1E1E),
          background: Color(0xFF121212),
          error: Color(0xFFCF6679),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFFE0E0E0),
          onBackground: Color(0xFFE0E0E0),
          onError: Colors.black,
          brightness: Brightness.dark,
        );
    }
  }

  // Helper method to get message bubble colors
  static Color getMessageBubbleColor(
      bool isOwnMessage, ColorScheme colorScheme) {
    if (isOwnMessage) {
      return colorScheme.primaryContainer.withOpacity(0.8);
    } else {
      return colorScheme.surface;
    }
  }

  // Helper method to get message text color
  static Color getMessageTextColor(bool isOwnMessage, ColorScheme colorScheme) {
    if (isOwnMessage) {
      return colorScheme.onPrimaryContainer;
    } else {
      return colorScheme.onSurface;
    }
  }
}
