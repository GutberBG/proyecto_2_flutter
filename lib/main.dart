import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/game_screen.dart';

void main() {
  // Asegurar la inicialización correcta de bindings de Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // Bloquear orientación en vertical para mantener la relación de aspecto del juego
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Hacer la barra de estado del sistema transparente para una experiencia inmersiva
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF080612),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const NeonBreakerApp());
}

/// Clase principal de la aplicación Neon Breaker.
class NeonBreakerApp extends StatelessWidget {
  const NeonBreakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neon Breaker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00E5FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00E5FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}
