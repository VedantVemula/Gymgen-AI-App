import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Base surfaces (light)
  static const background = Color(0xFFF4F7FE);
  static const backgroundAlt = Color(0xFFEEF3FF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFEEF3FF);

  // Brand
  static const accent = Color(0xFF246BFF);
  static const accentDeep = Color(0xFF1245B8);
  static const accentSoft = Color(0xFF78A4FF);
  static const accentGlow = Color(0xFF4C86FF);

  // Ink
  static const ink = Color(0xFF0A1633);
  static const inkSoft = Color(0xFF22305A);
  static const textPrimary = Color(0xFF12245A);
  static const textSecondary = Color(0xFF687797);
  static const textMuted = Color(0xFF98A5BF);

  // Signals
  static const success = Color(0xFF35C99A);
  static const successDeep = Color(0xFF159A72);
  static const warning = Color(0xFFFFB020);
  static const energy = Color(0xFFFF7A45);
  static const error = Color(0xFFE85D68);
  static const water = Color(0xFF4A9BFF);

  // Lines & shadows
  static const border = Color(0xFFDCE5F5);
  static const borderSoft = Color(0xFFE8EDF6);
  static const shadow = Color(0xFF1E3A66);

  // Dark-mode counterparts (used by AppTheme dark theme)
  static const darkBackground = Color(0xFF07101F);
  static const darkSurface = Color(0xFF101A2E);
  static const darkSurfaceVariant = Color(0xFF16233C);
  static const darkBorder = Color(0xFF243354);
  static const darkTextPrimary = Color(0xFFE8EEFB);
  static const darkTextSecondary = Color(0xFF9CAACB);
}

/// A ThemeExtension so screens can read palette values that differ
/// between light/dark without hardcoding.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color accent;
  final Color energy;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.accent,
    required this.energy,
  });

  static const light = AppPalette(
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceVariant: AppColors.surfaceVariant,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    border: AppColors.border,
    accent: AppColors.accent,
    energy: AppColors.energy,
  );

  static const dark = AppPalette(
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceVariant: AppColors.darkSurfaceVariant,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    border: AppColors.darkBorder,
    accent: AppColors.accentSoft,
    energy: AppColors.energy,
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? accent,
    Color? energy,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      energy: energy ?? this.energy,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      energy: Color.lerp(energy, other.energy, t)!,
    );
  }
}