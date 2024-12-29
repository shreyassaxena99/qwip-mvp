import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:qwip_app/components/main_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qwip',
      theme: ThemeData(
        // Define global color scheme
        primaryColor: Color(0xFFF9F8F5), // Cream
        scaffoldBackgroundColor: Color(0xFFF9F8F5), // Brown
        textTheme: TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFFAD7E4D),
          ), // For large titles
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ), // For section titles
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ), // For regular text
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFAD7E4D), width: 2.0),
          ),
          labelStyle: TextStyle(color: Color(0xFFAD7E4D)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, // Text color
            backgroundColor: Color(0xFFAD7E4D), // Brown
            textStyle: TextStyle(
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            backgroundColor: Colors.white, // Brown text for text buttons
          ),
        ),
        dividerColor: Colors.grey,
        colorScheme:
            ColorScheme.fromSwatch().copyWith(secondary: Color(0xFFAD7E4D)),
      ),
      home: MainWrapper(), // Replace this with your first screen
    );
  }
}
