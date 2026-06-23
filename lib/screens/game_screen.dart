import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../game/game_engine.dart';
import '../game/game_painter.dart';
import '../models/game_state.dart';
import '../widgets/game_controls.dart';

/// Pantalla principal del videojuego.
/// Responsable del ciclo del Ticker (60 FPS), el diseño responsivo de la interfaz
/// y la presentación de menús y overlays contextuales.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late final GameEngine _engine;
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Instanciar el motor de juego
    _engine = GameEngine();

    // Crear un Ticker nativo sincronizado con la tasa de refresco física de la pantalla.
    // Esto proporciona actualizaciones uniformes a 60 FPS independientes del hardware.
    _ticker = createTicker((Duration elapsed) {
      if (_engine.gameState == GameState.playing) {
        // Calculamos el delta de tiempo real en segundos
        final double dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
        
        // Clampeamos el dt a un máximo (ej. 30 FPS) para evitar saltos drásticos de física
        // en caso de tirones puntuales del sistema operativo.
        _engine.update(dt.clamp(0.0, 0.03));
      }
      _lastElapsed = elapsed;
    });

    // Iniciamos el Ticker inmediatamente
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080612), // Fondo ultra-oscuro espacial
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _engine,
          builder: (context, child) {
            return Column(
              children: [
                // 1. Dashboard Superior (Puntuación, Nivel y Vidas)
                _buildTopDashboard(),

                // 2. Área de Juego (CustomPaint con Aspect Ratio Fijo)
                Expanded(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(
                          color: const Color(0xFF00E5FF).withOpacity(0.25),
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withOpacity(0.06),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18.0),
                        child: AspectRatio(
                          aspectRatio: GameEngine.logicalWidth / GameEngine.logicalHeight, // 480:800
                          child: Stack(
                            children: [
                              // Lienzo de Dibujo del CustomPaint
                              CustomPaint(
                                size: Size.infinite,
                                painter: GamePainter(engine: _engine),
                              ),

                              // Overlays de Menús del Juego según el Estado
                              _buildStateOverlays(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Controles Inferiores (Botones de dirección y acción)
                GameControls(engine: _engine),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- Widgets del Dashboard Superior ---

  /// Construye el panel superior translúcido (efecto cristal esmerilado).
  Widget _buildTopDashboard() {
    return Container(
      margin: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sección de Puntaje
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "PUNTUACIÓN",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _engine.score.toString().padLeft(6, '0'),
                style: const TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),

          // Sección del Nivel Actual y Cronómetro
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF651FFF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF651FFF).withOpacity(0.5),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  "NIVEL ${_engine.currentLevel}/5",
                  style: const TextStyle(
                    color: Color(0xFFE040FB),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_rounded,
                    color: Colors.white70,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _engine.formattedTime,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Sección de Vidas (Iconos de Corazones Neón)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "VIDAS",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: List.generate(3, (index) {
                  final bool active = index < _engine.lives;
                  return Padding(
                    padding: const EdgeInsets.only(left: 3.0),
                    child: Icon(
                      active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: active ? const Color(0xFFFF1744) : Colors.white24,
                      size: 18,
                      shadows: active
                          ? [
                              const Shadow(
                                color: Color(0xFFFF1744),
                                blurRadius: 10,
                              )
                            ]
                          : null,
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Constructor de Overlays de Estado ---

  /// Evalúa el estado del motor y devuelve el overlay flotante correspondiente.
  Widget _buildStateOverlays() {
    switch (_engine.gameState) {
      case GameState.start:
        return _buildMenuOverlay(
          title: "NEON BREAKER",
          subtitle: "Un rompebloques minimalista y fluido desarrollado en Flutter nativo.",
          buttonText: "INICIAR JUEGO",
          themeColor: const Color(0xFF00E5FF),
          onPressed: () => _engine.startNewGame(),
          extra: Column(
            children: [
              const Text(
                "SELECCIONAR NIVEL DE INICIO:",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final int lvl = index + 1;
                  final bool isSelected = _engine.currentLevel == lvl;
                  return GestureDetector(
                    onTap: () => _engine.selectLevel(lvl),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6.0),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF00E5FF).withOpacity(0.18)
                            : Colors.white.withOpacity(0.04),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF00E5FF)
                              : Colors.white24,
                          width: 2.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withOpacity(0.25),
                                  blurRadius: 10,
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          "$lvl",
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF00E5FF) : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              const Text(
                "Usa los botones laterales para mover la paleta.\nPresiona LANZAR para comenzar cada bola.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.5),
              ),
            ],
          ),
        );

      case GameState.paused:
        return _buildMenuOverlay(
          title: "PAUSA",
          subtitle: "El juego se encuentra suspendido temporalmente.",
          buttonText: "REANUDAR",
          themeColor: const Color(0xFFFFD600),
          onPressed: () => _engine.togglePause(),
          onSecondaryPressed: () => _engine.goToMenu(),
          secondaryButtonText: "IR AL MENÚ",
        );

      case GameState.nextLevel:
        return _buildMenuOverlay(
          title: "¡NIVEL COMPLETADO!",
          subtitle: "Has destruido todos los bloques del Nivel ${_engine.currentLevel}.",
          buttonText: "SIGUIENTE NIVEL",
          themeColor: const Color(0xFF00FF87),
          onPressed: () => _engine.nextLevel(),
          extra: Text(
            "Puntuación acumulada: ${_engine.score}",
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        );

      case GameState.gameOver:
        return _buildMenuOverlay(
          title: "GAME OVER",
          subtitle: "Te has quedado sin vidas en el Nivel ${_engine.currentLevel}.",
          buttonText: "INTENTAR DE NUEVO",
          themeColor: const Color(0xFFFF1744),
          onPressed: () => _engine.startNewGame(),
          onSecondaryPressed: () => _engine.goToMenu(),
          secondaryButtonText: "IR AL MENÚ",
          extra: Text(
            "Puntuación Final: ${_engine.score}",
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        );

      case GameState.gameWon:
        return _buildMenuOverlay(
          title: "¡VICTORIA TOTAL!",
          subtitle: "¡Impresionante! Has superado los 5 niveles del juego.",
          buttonText: "JUGAR DE NUEVO",
          themeColor: const Color(0xFFFFD600),
          onPressed: () => _engine.startNewGame(),
          onSecondaryPressed: () => _engine.goToMenu(),
          secondaryButtonText: "IR AL MENÚ",
          extra: Column(
            children: [
              const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD600), size: 48),
              const SizedBox(height: 8),
              Text(
                "Puntaje de Campeón: ${_engine.score}",
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );

      case GameState.playing:
        // No mostrar overlay si se está jugando activamente
        return const SizedBox.shrink();
    }
  }

  /// Estructura común de diseño de los menús flotantes.
  Widget _buildMenuOverlay({
    required String title,
    required String subtitle,
    required String buttonText,
    required Color themeColor,
    required VoidCallback onPressed,
    VoidCallback? onSecondaryPressed,
    String? secondaryButtonText,
    Widget? extra,
  }) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF070510).withOpacity(0.92), // Desenfoque oscuro translúcido
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Título con resplandor neón
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: themeColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    shadows: [
                      Shadow(
                        color: themeColor.withOpacity(0.7),
                        blurRadius: 20,
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Subtítulo descriptivo
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                
                // Elemento widget extra opcional
                if (extra != null) ...[
                  const SizedBox(height: 18),
                  extra,
                ],
                
                const SizedBox(height: 32),

                // Botón de acción con estilo retro-neón
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor.withOpacity(0.12),
                    foregroundColor: themeColor,
                    shadowColor: themeColor.withOpacity(0.3),
                    surfaceTintColor: Colors.transparent,
                    side: BorderSide(color: themeColor, width: 2.0),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 10,
                  ),
                  onPressed: onPressed,
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                if (onSecondaryPressed != null && secondaryButtonText != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white30, width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: onSecondaryPressed,
                    child: Text(
                      secondaryButtonText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
