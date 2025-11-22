import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hapticvision/shared/menu/main_menu.dart';

void main() {
  // Suprimir logs en modo release
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // Nota: no se desactivan indicadores visuales del framework aquí para
  // evitar referencias a símbolos dependientes de la versión del SDK.

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HapticVision',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const MainMenu(),
    );
  }
}
