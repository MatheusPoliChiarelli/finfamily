import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg = Color(0xFF0F1113);
  static const surface = Color(0xFF16191C);
  static const surfaceRaised = Color(0xFF1C2024);
  static const border = Color(0xFF262B30);
  static const borderAccent = Color(0xFF3A3320);

  static const textPrimary = Color(0xFFECEDEE);
  static const textSecondary = Color(0xFF9AA1A8);
  static const textMuted = Color(0xFF6B737B);

  static const accent = Color(0xFFC9A96A);
  static const onAccent = Color(0xFF2A2113);
  static const income = Color(0xFF5FD4A0);
  static const expense = Color(0xFFE0785F);
}

class AppTheme {
  static const money = <FontFeature>[FontFeature.tabularFigures()];

  static TextStyle display(double size, {Color? color}) => GoogleFonts.instrumentSerif(
        fontSize: size,
        color: color ?? AppColors.textPrimary,
        height: 1.1,
      );

  static TextStyle displayMoney(double size, {Color? color}) => GoogleFonts.instrumentSerif(
        fontSize: size,
        color: color ?? AppColors.textPrimary,
        height: 1.1,
        fontFeatures: money,
      );

  static TextStyle ui(double size, {Color? color, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.inter(
        fontSize: size,
        color: color ?? AppColors.textPrimary,
        fontWeight: weight,
      );

  static TextStyle uiMoney(double size, {Color? color, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.inter(
        fontSize: size,
        color: color ?? AppColors.textPrimary,
        fontWeight: weight,
        fontFeatures: money,
      );

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.dark(
          surface: AppColors.surface,
          primary: AppColors.accent,
          onPrimary: AppColors.onAccent,
          error: AppColors.expense,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        dividerColor: AppColors.border,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceRaised,
          hintStyle: AppTheme.ui(14, color: AppColors.textMuted),
          labelStyle: AppTheme.ui(13, color: AppColors.textSecondary),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.accent, width: 1),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.expense, width: 0.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.expense, width: 1),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.onAccent,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      );
}