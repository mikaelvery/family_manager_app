import 'package:flutter/material.dart';

class CustomPickers {
  static Future<DateTime?> showCustomDatePicker(BuildContext context, { 
    required DateTime initialDate, 
    DateTime? firstDate, 
    DateTime? lastDate,
  }) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF5F6D),
              onPrimary: Colors.white,
              surface: Color(0xFFFFE0E6),
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFFFF5F6D),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  static Future<TimeOfDay?> showCustomTimePicker(BuildContext context, {
    required TimeOfDay initialTime,
  }) {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: Color(0xFFFFE0E6),
              hourMinuteColor: Color(0xFFFF5F6D),
              hourMinuteTextColor: Colors.white,
              dialHandColor: Color(0xFFFF5F6D),
              dialBackgroundColor: Color(0xFFFFB6C1),
              entryModeIconColor: Color(0xFFFF5F6D),
            ),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF5F6D),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFFFF5F6D),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
