import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final surfaceVariant = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
    final divider = isDark ? AppColors.darkDivider : AppColors.divider;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final inputFill = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppTypography.fontFamily,

      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        error: AppColors.error,
        onError: Colors.white,
        // These ensure Material 3 components pick the right backgrounds
        surfaceContainerHighest: surfaceVariant,
        outline: divider,
        outlineVariant: divider.withOpacity(0.5),
        scrim: Colors.black54,
        inverseSurface: isDark ? AppColors.surface : AppColors.darkSurface,
        onInverseSurface: isDark ? AppColors.textPrimary : AppColors.darkTextPrimary,
        primaryContainer: AppColors.secondary,
        onPrimaryContainer: AppColors.primaryDark,
        secondaryContainer: isDark
            ? AppColors.accent.withOpacity(0.15)
            : AppColors.accent.withOpacity(0.1),
        onSecondaryContainer: AppColors.accentDark,
      ),

      scaffoldBackgroundColor: bg,

      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.headlineMedium.copyWith(color: textPrimary),
        iconTheme: IconThemeData(color: textPrimary),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
            : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: divider, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          minimumSize: const Size(double.infinity, 56),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          minimumSize: const Size(double.infinity, 56),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: AppTypography.bodyMedium.copyWith(color: isDark ? AppColors.darkTextHint : AppColors.textHint),
        labelStyle: AppTypography.bodyMedium.copyWith(color: textSecondary),
      ),

      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),

      listTileTheme: ListTileThemeData(
        tileColor: surface,
        iconColor: textSecondary,
        textColor: textPrimary,
        subtitleTextStyle: AppTypography.bodySmall.copyWith(color: textSecondary),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return isDark ? AppColors.darkTextSecondary : Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return isDark ? AppColors.darkSurfaceVariant : AppColors.divider;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: AppTypography.headlineMedium.copyWith(color: textPrimary),
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: textSecondary),
      ),

      textTheme: TextTheme(
        displayLarge:  AppTypography.displayLarge.copyWith(color: textPrimary),
        displayMedium: AppTypography.displayMedium.copyWith(color: textPrimary),
        headlineLarge: AppTypography.headlineLarge.copyWith(color: textPrimary),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: textPrimary),
        headlineSmall: AppTypography.headlineSmall.copyWith(color: textPrimary),
        titleLarge:    AppTypography.titleLarge.copyWith(color: textPrimary),
        titleMedium:   AppTypography.titleMedium.copyWith(color: textPrimary),
        bodyLarge:     AppTypography.bodyLarge.copyWith(color: textPrimary),
        bodyMedium:    AppTypography.bodyMedium.copyWith(color: textPrimary),
        bodySmall:     AppTypography.bodySmall.copyWith(color: textSecondary),
        labelLarge:    AppTypography.labelLarge.copyWith(color: textPrimary),
        labelMedium:   AppTypography.labelMedium.copyWith(color: textSecondary),
        labelSmall:    AppTypography.labelSmall.copyWith(color: textSecondary),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: isDark
            ? AppColors.primary.withOpacity(0.25)
            : AppColors.secondary,
        labelStyle: AppTypography.labelMedium.copyWith(color: textPrimary),
        side: BorderSide(color: divider, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        checkmarkColor: AppColors.primary,
        iconTheme: IconThemeData(color: textSecondary),
      ),

      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.secondary,
        thumbColor: AppColors.primary,
        overlayColor: Color(0x1A0F9D58),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.secondary,
        circularTrackColor: AppColors.secondary,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.darkElevated : AppColors.textPrimary,
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
