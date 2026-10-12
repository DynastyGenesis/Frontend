import 'package:flutter/material.dart';

class AppColors {
  static const brandPink = Color(0xFFF8979C);
  static const brandPinkDark = Color(0xFFE77F86);
  static const pinkTint = Color(0xFFFFF0F1);
  static const pinkBorder = Color(0xFFF6C9CC);
  static const green = Color(0xFF3B8053);
  static const blue = Color(0xFF12375C);
  static const ink = Color(0xFF212121);
  static const muted = Color(0xFF585858);
  static const background = Color(0xFFF6F6F6);
  static const border = Color(0xFFEEEEEE);
  static const white = Colors.white;
}

class AppTheme {
  static ThemeData light() => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.brandPink,
          primary: AppColors.brandPink,
          onPrimary: AppColors.white,
          secondary: AppColors.blue,
          onSecondary: AppColors.white,
          surface: AppColors.white,
          onSurface: AppColors.ink,
        ),
        fontFamily: 'Open Sans',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.ink,
          elevation: 0,
          centerTitle: false,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.white,
          indicatorColor: AppColors.pinkTint,
          labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
                color: states.contains(WidgetState.selected)
                    ? AppColors.brandPinkDark
                    : AppColors.muted,
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w700
                    : FontWeight.w500,
              )),
          iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
                color: states.contains(WidgetState.selected)
                    ? AppColors.brandPinkDark
                    : AppColors.muted,
              )),
        ),
        cardTheme: CardThemeData(
          color: AppColors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.brandPink, width: 1.5),
          ),
        ),
      );
}
