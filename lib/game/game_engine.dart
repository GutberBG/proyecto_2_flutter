import 'dart:math';
import 'package:flutter/material.dart';
import '../models/brick.dart';
import '../models/ball.dart';
import '../models/game_state.dart';

/// Motor principal del videojuego Brick Breaker.
/// Maneja la física de múltiples pelotas, detección de colisiones, estados y carga de niveles.
/// Utiliza un sistema de coordenadas lógicas de 480x800 para independencia de pantalla.
class GameEngine extends ChangeNotifier {
  // --- Dimensiones Lógicas de Juego ---
  static const double logicalWidth = 480.0;
  static const double logicalHeight = 800.0;

  // --- Dimensiones y Parámetros del Jugador (Paleta) ---
  static const double paddleWidth = 110.0;
  static const double paddleHeight = 16.0;
  static const double paddleY = 700.0;
  static const double paddleSpeed = 480.0; // Píxeles lógicos por segundo

  // --- Dimensiones y Parámetros de la Pelota ---
  static const double ballRadius = 8.0;
  static const double baseBallSpeed = 380.0; // Píxeles lógicos por segundo

  // --- Variables de Estado del Juego ---
  GameState _gameState = GameState.start;
  int _score = 0;
  int _lives = 3;
  int _currentLevel = 1;
  
  // Posición y velocidad de la paleta
  double _paddleX = (logicalWidth - paddleWidth) / 2;
  bool isMovingLeft = false;
  bool isMovingRight = false;

  // Lista dinámica de pelotas activas (permite Multiball)
  final List<Ball> _balls = [];

  // Lista de bloques del nivel actual
  final List<Brick> _bricks = [];

  // Cronómetro del tiempo transcurrido en la partida
  double _elapsedTime = 0.0;

  // --- Getters Públicos ---
  GameState get gameState => _gameState;
  int get score => _score;
  int get lives => _lives;
  int get currentLevel => _currentLevel;
  double get paddleX => _paddleX;
  List<Ball> get balls => _balls;
  List<Brick> get bricks => _bricks;
  double get elapsedTime => _elapsedTime;

  /// Retorna el tiempo transcurrido formateado como MM:SS.
  String get formattedTime {
    final int minutes = _elapsedTime ~/ 60;
    final int seconds = _elapsedTime.toInt() % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Retorna verdadero si alguna de las pelotas está adherida a la paleta.
  bool get isBallAttachedToPaddle => _balls.any((b) => b.isAttached);

  // --- Inicialización y Control de Flujo ---

  /// Inicia una nueva partida en el nivel actualmente seleccionado.
  void startNewGame() {
    _score = 0;
    _lives = 3;
    _elapsedTime = 0.0;
    _gameState = GameState.playing;
    loadLevel(_currentLevel);
    notifyListeners();
  }

  /// Permite al usuario seleccionar el nivel de partida antes de jugar.
  void selectLevel(int level) {
    if (_gameState == GameState.start || _gameState == GameState.gameWon || _gameState == GameState.gameOver) {
      _currentLevel = level.clamp(1, 5);
      notifyListeners();
    }
  }

  /// Cambia el estado actual del juego.
  void setGameState(GameState state) {
    _gameState = state;
    notifyListeners();
  }

  /// Pausa o reanuda el juego.
  void togglePause() {
    if (_gameState == GameState.playing) {
      _gameState = GameState.paused;
    } else if (_gameState == GameState.paused) {
      _gameState = GameState.playing;
    }
    notifyListeners();
  }

  /// Limpia la partida actual y regresa a la pantalla de menú de inicio.
  void goToMenu() {
    _gameState = GameState.start;
    _balls.clear();
    notifyListeners();
  }

  /// Lanza las pelotas que estén pegadas a la paleta.
  void launchBall() {
    if (_gameState == GameState.playing) {
      bool launchedAny = false;
      for (var ball in _balls) {
        if (ball.isAttached) {
          ball.isAttached = false;
          double randomAngle = (Random().nextDouble() - 0.5) * 0.4; // -11 a +11 grados
          double speed = baseBallSpeed + (_currentLevel * 15.0);
          ball.vx = speed * sin(randomAngle);
          ball.vy = -speed * cos(randomAngle);
          launchedAny = true;
        }
      }
      if (launchedAny) {
        notifyListeners();
      }
    }
  }

  /// Spawnea una pelota extra en juego (función Multiball).
  /// Se lanza desde la posición de la paleta hacia arriba con ángulo aleatorio.
  void addExtraBall() {
    if (_gameState != GameState.playing) return;
    
    double speed = baseBallSpeed + (_currentLevel * 15.0);
    // Ángulo aleatorio amplio de rebote (-45 a 45 grados)
    double randomAngle = (Random().nextDouble() - 0.5) * 1.5;
    
    _balls.add(Ball(
      x: _paddleX + paddleWidth / 2,
      y: paddleY - ballRadius - 2.0,
      vx: speed * sin(randomAngle),
      vy: -speed * cos(randomAngle),
      isAttached: false,
    ));
    
    notifyListeners();
  }

  /// Carga la distribución de bloques y posiciona los elementos para el nivel indicado.
  void loadLevel(int level) {
    _currentLevel = level;
    _paddleX = (logicalWidth - paddleWidth) / 2;
    isMovingLeft = false;
    isMovingRight = false;
    
    // Inicializar con una sola pelota adherida a la paleta
    _balls.clear();
    _balls.add(Ball(
      x: _paddleX + paddleWidth / 2,
      y: paddleY - ballRadius,
      vx: 0.0,
      vy: 0.0,
      isAttached: true,
    ));
    
    _generateBricksForLevel(level);
    notifyListeners();
  }

  /// Avanza al siguiente nivel si corresponde, o finaliza con victoria.
  void nextLevel() {
    if (_currentLevel < 5) {
      _gameState = GameState.playing;
      loadLevel(_currentLevel + 1);
    } else {
      _gameState = GameState.gameWon;
    }
    notifyListeners();
  }

  // --- Generador de Niveles ---

  void _generateBricksForLevel(int level) {
    _bricks.clear();

    const double brickWidth = 50.0;
    const double brickHeight = 20.0;
    const double spacing = 5.0;
    const double gridWidth = (8 * brickWidth) + (7 * spacing); // 435 logical pixels
    const double startX = (logicalWidth - gridWidth) / 2;     // Centrado horizontal
    const double startY = 80.0;                                // Margen superior del tablero

    switch (level) {
      case 1:
        // --- Nivel 1: Pared Estándar ---
        for (int r = 0; r < 4; r++) {
          int maxLives = (r == 0) ? 2 : 1;
          for (int c = 0; c < 8; c++) {
            _bricks.add(Brick(
              x: startX + c * (brickWidth + spacing),
              y: startY + r * (brickHeight + spacing),
              width: brickWidth,
              height: brickHeight,
              maxLives: maxLives,
              scoreValue: maxLives * 100,
            ));
          }
        }
        break;

      case 2:
        // --- Nivel 2: La Pirámide ---
        for (int r = 0; r < 4; r++) {
          int cols = 2 + (r * 2);
          double rowWidth = (cols * brickWidth) + ((cols - 1) * spacing);
          double rowStartX = (logicalWidth - rowWidth) / 2;
          int maxLives = (r < 2) ? 2 : 1;

          for (int c = 0; c < cols; c++) {
            _bricks.add(Brick(
              x: rowStartX + c * (brickWidth + spacing),
              y: startY + r * (brickHeight + spacing),
              width: brickWidth,
              height: brickHeight,
              maxLives: maxLives,
              scoreValue: maxLives * 100,
            ));
          }
        }
        break;

      case 3:
        // --- Nivel 3: Columnas Alternadas ---
        for (int r = 0; r < 5; r++) {
          int maxLives = (r % 2 == 0) ? 2 : 1;
          for (int c = 0; c < 8; c++) {
            if ((r + c) % 2 == 0) {
              _bricks.add(Brick(
                x: startX + c * (brickWidth + spacing),
                y: startY + r * (brickHeight + spacing),
                width: brickWidth,
                height: brickHeight,
                maxLives: maxLives,
                scoreValue: maxLives * 120,
              ));
            }
          }
        }
        break;

      case 4:
        // --- Nivel 4: La Fortaleza ---
        for (int r = 0; r < 5; r++) {
          for (int c = 0; c < 8; c++) {
            bool isBorder = (r == 0 || r == 4 || c == 0 || c == 7);
            if (isBorder) {
              _bricks.add(Brick(
                x: startX + c * (brickWidth + spacing),
                y: startY + r * (brickHeight + spacing),
                width: brickWidth,
                height: brickHeight,
                maxLives: 2,
                scoreValue: 200,
              ));
            } else if (r == 2 && (c >= 2 && c <= 5)) {
              _bricks.add(Brick(
                x: startX + c * (brickWidth + spacing),
                y: startY + r * (brickHeight + spacing),
                width: brickWidth,
                height: brickHeight,
                maxLives: 1,
                scoreValue: 300,
              ));
            }
          }
        }
        break;

      case 5:
        // --- Nivel 5: Desafío Final en V ---
        for (int r = 0; r < 5; r++) {
          int col1 = r;
          int col2 = 7 - r;

          _bricks.add(Brick(
            x: startX + col1 * (brickWidth + spacing),
            y: startY + r * (brickHeight + spacing),
            width: brickWidth,
            height: brickHeight,
            maxLives: 2,
            scoreValue: 250,
          ));

          if (col1 != col2) {
            _bricks.add(Brick(
              x: startX + col2 * (brickWidth + spacing),
              y: startY + r * (brickHeight + spacing),
              width: brickWidth,
              height: brickHeight,
              maxLives: 2,
              scoreValue: 250,
            ));
          }
          
          if (r > 0 && r < 4) {
            for (int c = col1 + 1; c < col2; c++) {
              if ((r + c) % 2 == 1) {
                _bricks.add(Brick(
                  x: startX + c * (brickWidth + spacing),
                  y: startY + r * (brickHeight + spacing),
                  width: brickWidth,
                  height: brickHeight,
                  maxLives: 1,
                  scoreValue: 400,
                ));
              }
            }
          }
        }
        break;
    }
  }

  // --- Bucle de Actualización Física (Game Loop) ---

  /// Actualiza la física de todas las pelotas activas y procesa colisiones.
  /// Se ejecuta a 60 FPS desde el Ticker del Widget.
  void update(double dt) {
    if (_gameState != GameState.playing) return;

    // Incrementar el cronómetro del juego
    _elapsedTime += dt;

    // 1. Movimiento de la Paleta del Jugador
    if (isMovingLeft) {
      _paddleX -= paddleSpeed * dt;
    }
    if (isMovingRight) {
      _paddleX += paddleSpeed * dt;
    }
    _paddleX = _paddleX.clamp(0.0, logicalWidth - paddleWidth);

    // Lista auxiliar para almacenar pelotas que caen y deben eliminarse
    final List<Ball> ballsToRemove = [];

    // 2. Procesar física individual para cada pelota activa
    for (var ball in _balls) {
      // Si la pelota está adherida, sigue la posición central de la paleta
      if (ball.isAttached) {
        ball.x = _paddleX + paddleWidth / 2;
        ball.y = paddleY - ballRadius;
        continue;
      }

      // Movimiento lineal
      ball.x += ball.vx * dt;
      ball.y += ball.vy * dt;

      // Colisión con límites laterales
      if (ball.x - ballRadius < 0.0) {
        ball.x = ballRadius;
        ball.vx = ball.vx.abs(); // Rebota derecha
      } else if (ball.x + ballRadius > logicalWidth) {
        ball.x = logicalWidth - ballRadius;
        ball.vx = -ball.vx.abs(); // Rebota izquierda
      }

      // Colisión con el techo
      if (ball.y - ballRadius < 0.0) {
        ball.y = ballRadius;
        ball.vy = ball.vy.abs(); // Rebota abajo
      }

      // Caída por el fondo (se marca para eliminar)
      if (ball.y + ballRadius > logicalHeight) {
        ballsToRemove.add(ball);
        continue;
      }

      // Colisiones individuales con la paleta y los bloques
      _checkSingleBallPaddleCollision(ball);
      _checkSingleBallBricksCollision(ball);
    }

    // 3. Eliminar del juego las pelotas perdidas
    for (var ball in ballsToRemove) {
      _balls.remove(ball);
    }

    // 4. Si ya no quedan pelotas activas, se pierde una vida
    if (_balls.isEmpty) {
      _loseLife();
    }

    notifyListeners();
  }

  // --- Métodos de Colisión Individual ---

  /// Evalúa y procesa la colisión de una sola pelota con la paleta.
  void _checkSingleBallPaddleCollision(Ball ball) {
    final double left = _paddleX;
    final double top = paddleY;
    final double right = _paddleX + paddleWidth;
    final double bottom = paddleY + paddleHeight;

    final double closestX = ball.x.clamp(left, right);
    final double closestY = ball.y.clamp(top, bottom);

    final double diffX = ball.x - closestX;
    final double diffY = ball.y - closestY;
    final double distanceSquared = (diffX * diffX) + (diffY * diffY);

    if (distanceSquared < ballRadius * ballRadius) {
      // Impacto detectado en la paleta
      double relativeHitX = (ball.x - (_paddleX + paddleWidth / 2)) / (paddleWidth / 2);
      relativeHitX = relativeHitX.clamp(-1.0, 1.0);

      const double maxBounceAngle = 60.0 * pi / 180.0;
      double angle = relativeHitX * maxBounceAngle;

      double speed = baseBallSpeed + (_currentLevel * 15.0);
      
      ball.vx = speed * sin(angle);
      ball.vy = -speed * cos(angle);

      // Reposicionar para evitar atascos
      ball.y = paddleY - ballRadius;
    }
  }

  /// Evalúa y procesa la colisión de una sola pelota con la rejilla de bloques.
  void _checkSingleBallBricksCollision(Ball ball) {
    for (int i = 0; i < _bricks.length; i++) {
      Brick brick = _bricks[i];
      if (brick.isDestroyed) continue;

      double left = brick.x;
      double right = brick.x + brick.width;
      double top = brick.y;
      double bottom = brick.y + brick.height;

      double closestX = ball.x.clamp(left, right);
      double closestY = ball.y.clamp(top, bottom);

      double diffX = ball.x - closestX;
      double diffY = ball.y - closestY;
      double distanceSquared = (diffX * diffX) + (diffY * diffY);

      if (distanceSquared < ballRadius * ballRadius) {
        // Impacto en el bloque
        brick.hit();

        if (brick.isDestroyed) {
          _score += brick.scoreValue;
        } else {
          _score += 30;
        }

        // Resolución de rebotes
        if (diffX == 0 && diffY == 0) {
          ball.vy = -ball.vy;
        } else if (diffX != 0 && diffY != 0) {
          if (diffX.abs() > diffY.abs()) {
            if (diffX > 0) {
              ball.vx = ball.vx.abs();
              ball.x = closestX + ballRadius;
            } else {
              ball.vx = -ball.vx.abs();
              ball.x = closestX - ballRadius;
            }
          } else {
            if (diffY > 0) {
              ball.vy = ball.vy.abs();
              ball.y = closestY + ballRadius;
            } else {
              ball.vy = -ball.vy.abs();
              ball.y = closestY - ballRadius;
            }
          }
        } else {
          if (diffX != 0) {
            if (diffX > 0) {
              ball.vx = ball.vx.abs();
              ball.x = closestX + ballRadius;
            } else {
              ball.vx = -ball.vx.abs();
              ball.x = closestX - ballRadius;
            }
          } else {
            if (diffY > 0) {
              ball.vy = ball.vy.abs();
              ball.y = closestY + ballRadius;
            } else {
              ball.vy = -ball.vy.abs();
              ball.y = closestY - ballRadius;
            }
          }
        }

        // Evaluar nivel completado
        if (_bricks.every((b) => b.isDestroyed)) {
          if (_currentLevel < 5) {
            _gameState = GameState.nextLevel;
          } else {
            _gameState = GameState.gameWon;
          }
        }
        break; // Detener en el primer bloque chocado
      }
    }
  }

  /// Pierde una vida y evalúa el Game Over o la re-instanciación de la pelota inicial.
  void _loseLife() {
    _lives--;
    if (_lives <= 0) {
      _gameState = GameState.gameOver;
    } else {
      _paddleX = (logicalWidth - paddleWidth) / 2;
      isMovingLeft = false;
      isMovingRight = false;
      _balls.clear();
      _balls.add(Ball(
        x: _paddleX + paddleWidth / 2,
        y: paddleY - ballRadius,
        vx: 0,
        vy: 0,
        isAttached: true,
      ));
    }
  }
}
