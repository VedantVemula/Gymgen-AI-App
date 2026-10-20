import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static final display = GoogleFonts.outfit(
    fontSize: 44,
    height: 1.05,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.2,
    color: AppColors.ink,
  );

  static final heading1 = GoogleFonts.outfit(
    fontSize: 32,
    height: 1.1,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    color: AppColors.textPrimary,
  );

  static final heading2 = GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
  );

  static final heading3 = GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static final body = GoogleFonts.inter(
    fontSize: 15,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  static TextStyle get bodyMedium => body;

  static final bodyStrong = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static final label = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static final overline = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.6,
    color: AppColors.textSecondary,
  );

  static final numeric = GoogleFonts.outfit(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );
}