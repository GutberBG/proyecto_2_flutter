import 'package:flutter/material.dart';
import '../game/game_engine.dart';
import '../models/game_state.dart';

/// Widget de controles de dirección inferiores.
/// Utiliza `Listener` en lugar de `GestureDetector` para capturar eventos táctiles nativos
/// de inmediato sin el retardo habitual de pulsación, permitiendo un control fluido.
class GameControls extends AnimatedWidget {
  final GameEngine engine;

  const GameControls({
    super.key,
    required this.engine,
  }) : super(listenable: engine);

  @override
  Widget build(BuildContext context) {
    final bool isAttached = engine.isBallAttachedToPaddle;
    final bool isPaused = engine.gameState == GameState.paused;
    final bool isPlaying = engine.gameState == GameState.playing;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Botón Izquierda
          _buildDirectionButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onStart: () => engine.isMovingLeft = true,
            onEnd: () => engine.isMovingLeft = false,
          ),

          // Botón de Acción Central (Lanzar / Pausa / Reanudar)
          _buildActionButton(
            isAttached: isAttached,
            isPaused: isPaused,
            isPlaying: isPlaying,
          ),

          // Botón de Pelota Extra (Multiball)
          _buildExtraBallButton(
            isPlaying: isPlaying,
            isPaused: isPaused,
          ),

          // Botón Derecha
          _buildDirectionButton(
            icon: Icons.arrow_forward_ios_rounded,
            onStart: () => engine.isMovingRight = true,
            onEnd: () => engine.isMovingRight = false,
          ),
        ],
      ),
    );
  }

  /// Construye un botón de dirección con eventos de puntero inmediatos.
  Widget _buildDirectionButton({
    required IconData icon,
    required VoidCallback onStart,
    required VoidCallback onEnd,
  }) {
    return Listener(
      onPointerDown: (_) => onStart(),
      onPointerUp: (_) => onEnd(),
      onPointerCancel: (_) => onEnd(),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white24,
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  /// Construye el botón de acción central que cambia de función dinámicamente.
  Widget _buildActionButton({
    required bool isAttached,
    required bool isPaused,
    required bool isPlaying,
  }) {
    String label = "JUGAR";
    IconData icon = Icons.play_arrow_rounded;
    Color buttonColor = Colors.blue;

    if (isPaused) {
      label = "SEGUIR";
      icon = Icons.play_arrow_rounded;
      buttonColor = Colors.green;
    } else if (isPlaying) {
      if (isAttached) {
        label = "LANZAR";
        icon = Icons.rocket_launch_rounded;
        buttonColor = Colors.orange;
      } else {
        label = "PAUSA";
        icon = Icons.pause_rounded;
        buttonColor = Colors.blueGrey;
      }
    }

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
      ),
      onPressed: () {
        if (isPaused) {
          engine.togglePause();
        } else if (isPlaying) {
          if (isAttached) {
            engine.launchBall();
          } else {
            engine.togglePause();
          }
        }
      },
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  /// Construye el botón para añadir pelotas extra en la pantalla.
  Widget _buildExtraBallButton({required bool isPlaying, required bool isPaused}) {
    final bool active = isPlaying && !isPaused;

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? Colors.amber : Colors.white.withOpacity(0.04),
        foregroundColor: active ? Colors.black87 : Colors.white24,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: active ? 2 : 0,
      ),
      onPressed: active ? () => engine.addExtraBall() : null,
      icon: Icon(Icons.add_circle_outline_rounded, color: active ? Colors.black87 : Colors.white24, size: 18),
      label: const Text(
        "+ BOLA",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
