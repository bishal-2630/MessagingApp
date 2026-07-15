import 'package:flutter/material.dart';

class AppTheme {
static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1A1A2E),
    colorScheme: const ColorScheme.dark(
    primary: Color(0xFF7C4DFF),
    surface: Color(0xFF1A1A2E),
    onPrimary: Colors.white
    ),

    appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1A2E),
        elevation: 0,
    ),

    inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF16213E), 
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
        ),
    ),

);


}