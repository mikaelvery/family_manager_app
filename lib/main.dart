import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart'; 
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notre Famille ♡',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fr'), // <-- Forcer le français
        supportedLocales: const [
          Locale('fr'),
          Locale('en'),
          // Ajoute d'autres si nécessaire
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],  
        theme: ThemeData(
          textTheme: GoogleFonts.montserratTextTheme(),
          primaryColor: const Color(0xFFFF866E),
          inputDecorationTheme: InputDecorationTheme(
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: const Color(0xFFFF5F6D), width: 2),
            ),
            labelStyle: TextStyle(color: Colors.grey[700]),
            floatingLabelStyle: TextStyle(color: const Color(0xFFFF5F6D)),
            prefixIconColor: const Color(0xFFFF5F6D),
          ),
          checkboxTheme: CheckboxThemeData(
            fillColor: WidgetStateProperty.all(const Color(0xFFFF5F6D)),
          ),
        ),

      home: const LoginScreen(), 
    );
  }
}
