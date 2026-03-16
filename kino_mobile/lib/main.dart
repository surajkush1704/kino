import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const KinoApp());
}

class KinoApp extends StatelessWidget {
  const KinoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kino',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.purpleAccent,
          secondary: Colors.redAccent,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
