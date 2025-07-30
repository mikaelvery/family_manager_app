import 'package:flutter/material.dart';

class CustomPickers {
  // ------------------------------- DATE PICKER -------------------------------
  static Future<DateTime?> showCustomDatePicker(
    BuildContext context, {
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    Color accent = const Color(0xFFFF5F6D),
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surface = isDark ? const Color(0xFF111827) : Colors.white;
    final onSurface = isDark ? const Color(0xFFE5E7EB) : const Color(0xFF111827);

    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2100),
      builder: (ctx, child) {
        final base = ThemeData(
          brightness: isDark ? Brightness.dark : Brightness.light,
          useMaterial3: true,
          colorScheme: (isDark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
            primary: accent,
            onPrimary: Colors.white,
            surface: surface,
            onSurface: onSurface,
          ),
        );


        return Theme(
          data: base.copyWith(
            datePickerTheme: DatePickerThemeData(
              backgroundColor: surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              headerBackgroundColor: accent,
              headerForegroundColor: Colors.white,
              // Le sélecteur de jour adoptera primary auto
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: accent,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  /// TimePicker avec un thème personnalisé
 static Future<TimeOfDay?> showCustomTimePicker(
    BuildContext context, {
    required TimeOfDay initialTime,
    Color accent = const Color(0xFFFF5F6D),
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surface = isDark ? const Color(0xFF111827) : Colors.white;
    final onSurface = isDark ? const Color(0xFFE5E7EB) : const Color(0xFF111827);
    final dialBg = isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6);

    return showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (ctx, child) {
        final base = ThemeData(
          brightness: isDark ? Brightness.dark : Brightness.light,
          useMaterial3: true,
          colorScheme: (isDark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
            primary: accent,
            onPrimary: Colors.white,
            surface: surface,
            onSurface: onSurface,
          ),
        );

        return Theme(
          data: base.copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: surface,
              dialBackgroundColor: dialBg,
              dialHandColor: accent,
              dialTextColor: onSurface,
              hourMinuteColor: accent, 
              hourMinuteTextColor: Colors.white,
              dayPeriodColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
              dayPeriodTextColor: onSurface,
              hourMinuteShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              helpTextStyle: const TextStyle(fontWeight: FontWeight.w700),
              inputDecorationTheme: InputDecorationTheme(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              entryModeIconColor: accent,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: accent,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          // Force 24h
          child: MediaQuery(
            data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
