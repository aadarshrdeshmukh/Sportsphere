import 'package:flutter/material.dart';

class AppTheme {
  // Light Mode Core Colors
  static const primary = Color(0xFF0B6E4F); // Deep emerald green
  static const primaryLight = Color(0xFF10956A);
  static const primaryContainer = Color(0xFFE8F5EE); // Soft green tint
  static const secondary = Color(0xFFFF6B35); // Sports energetic orange
  static const secondaryContainer = Color(0xFFFFF0EB);
  static const live = Color(0xFFE53935); // Vibrant live red
  static const liveContainer = Color(0xFFFFEBEE);
  static const win = Color(0xFF2E7D32);
  static const surface = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF7F9F8); // Very soft neutral background
  static const text = Color(0xFF111827); // Deep slate high contrast
  static const outline = Color(0xFFE5E9E6); // Clean subtle border
  static const outlineVariant = Color(0xFFD1D8D4);
  static const muted = Color(0xFF6B7280); // Neutral secondary text
  static const paleGreen = Color(0xFFE8F5EE);

  // Dark Mode Equivalents
  static const darkBg = Color(0xFF0F1613);
  static const darkSurface = Color(0xFF18221D);
  static const darkSurfaceVariant = Color(0xFF23302A);
  static const darkOnSurface = Color(0xFFF3F4F6);
  static const darkOutline = Color(0xFF283830);
  static const darkMuted = Color(0xFF9CA3AF);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: primary,
          onPrimary: Colors.white,
          primaryContainer: primaryContainer,
          onPrimaryContainer: primary,
          secondary: secondary,
          onSecondary: Colors.white,
          secondaryContainer: secondaryContainer,
          onSecondaryContainer: secondary,
          error: live,
          onError: Colors.white,
          surface: surface,
          onSurface: text,
          surfaceContainer: surface,
          surfaceContainerHighest: Color(0xFFEEF2F0),
          outline: outline,
          outlineVariant: outlineVariant,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: text,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          shadowColor: Color(0x15000000),
          titleTextStyle: TextStyle(
            color: text,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
          iconTheme: IconThemeData(color: text, size: 22),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: outline, width: 1),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: surface,
          selectedColor: primary,
          disabledColor: outline,
          checkmarkColor: Colors.transparent,
          showCheckmark: false,
          side: const BorderSide(color: outline, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: muted,
          ),
          secondaryLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: primary,
          unselectedLabelColor: muted,
          indicatorColor: primary,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: outline,
          labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          unselectedLabelStyle:
              TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 48),
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            minimumSize: const Size(0, 44),
            side: const BorderSide(color: primary, width: 1.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          height: 64,
          backgroundColor: surface,
          indicatorColor: primaryContainer,
          elevation: 0,
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        dividerTheme: const DividerThemeData(color: outline, space: 1),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: darkBg,
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: primaryLight,
          onPrimary: Colors.white,
          primaryContainer: darkSurfaceVariant,
          onPrimaryContainer: Colors.white,
          secondary: secondary,
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFF332018),
          onSecondaryContainer: secondary,
          error: live,
          onError: Colors.white,
          surface: darkSurface,
          onSurface: darkOnSurface,
          surfaceContainer: darkSurface,
          surfaceContainerHighest: darkSurfaceVariant,
          outline: darkOutline,
          outlineVariant: Color(0xFF35443D),
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 22),
        appBarTheme: const AppBarTheme(
          backgroundColor: darkSurface,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          shadowColor: Color(0x30000000),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
          iconTheme: IconThemeData(color: Colors.white, size: 22),
        ),
        cardTheme: CardThemeData(
          color: darkSurface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: darkOutline, width: 1),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: darkSurface,
          selectedColor: primaryLight,
          disabledColor: darkOutline,
          checkmarkColor: Colors.transparent,
          showCheckmark: false,
          side: const BorderSide(color: darkOutline, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: darkMuted,
          ),
          secondaryLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: primaryLight,
          unselectedLabelColor: darkMuted,
          indicatorColor: primaryLight,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: darkOutline,
          labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          unselectedLabelStyle:
              TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primaryLight,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 48),
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryLight,
            minimumSize: const Size(0, 44),
            side: const BorderSide(color: primaryLight, width: 1.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 64,
          backgroundColor: darkSurface,
          indicatorColor: primaryLight.withValues(alpha: 0.25),
          elevation: 0,
          labelTextStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final isSelected = states.contains(WidgetState.selected);
            return IconThemeData(
              size: 22,
              color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
            );
          }),
        ),
        dividerTheme: const DividerThemeData(color: darkOutline, space: 1),
      );
}
