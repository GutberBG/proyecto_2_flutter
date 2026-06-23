import 'package:flutter/material.dart';
import '../models/brick.dart';
import '../models/ball.dart';
import 'game_engine.dart';

/// Renderizador basado en CustomPainter.
/// Dibuja el estado lógico del juego escalándolo proporcionalmente al tamaño físico de la pantalla.
class GamePainter extends CustomPainter {
  final GameEngine engine;

  GamePainter({required this.engine}) : super(repaint: engine);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Calcular factores de escala para adaptar 480x800 al tamaño actual
    final double scaleX = size.width / GameEngine.logicalWidth;
    final double scaleY = size.height / GameEngine.logicalHeight;

    canvas.save();
    // Escalamos el canvas para poder dibujar en coordenadas lógicas fijas
    canvas.scale(scaleX, scaleY);

    // 2. Dibujar fondo con gradiente futurista
    _drawBackground(canvas);

    // 3. Dibujar rejilla de fondo cibernética (Cyber Grid)
    _drawGrid(canvas);

    // 4. Dibujar los bloques (Bricks) activos
    _drawBricks(canvas);

    // 5. Dibujar la paleta del jugador (Paddle)
    _drawPaddle(canvas);

    // 6. Dibujar las pelotas (Balls)
    _drawBalls(canvas);

    canvas.restore();
  }

  /// Dibuja el fondo de la pantalla del juego con un gradiente lineal elegante.
  void _drawBackground(Canvas canvas) {
    final Rect backgroundRect = const Rect.fromLTWH(0, 0, GameEngine.logicalWidth, GameEngine.logicalHeight);
    final Paint bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0F0C20), // Azul espacial ultra oscuro
          Color(0xFF15102A), // Violeta oscuro
          Color(0xFF070510), // Negro azulado
        ],
      ).createShader(backgroundRect);

    canvas.drawRect(backgroundRect, bgPaint);
  }

  /// Dibuja una sutil rejilla cibernética de fondo que aporta estética cyberpunk/arcade.
  void _drawGrid(Canvas canvas) {
    final Paint gridPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.04) // Cian translúcido
      ..strokeWidth = 1.0;

    const double step = 40.0;
    for (double x = 0; x < GameEngine.logicalWidth; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, GameEngine.logicalHeight), gridPaint);
    }
    for (double y = 0; y < GameEngine.logicalHeight; y += step) {
      canvas.drawLine(Offset(0, y), Offset(GameEngine.logicalWidth, y), gridPaint);
    }
  }

  /// Dibuja todos los bloques aplicando estilos según sus vidas actuales y máximas.
  void _drawBricks(Canvas canvas) {
    for (Brick brick in engine.bricks) {
      if (brick.isDestroyed) continue;

      // Crear rectángulo redondeado del bloque
      final RRect brickRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(brick.x, brick.y, brick.width, brick.height),
        const Radius.circular(5.0),
      );

      // Definir gradiente de color según la resistencia restante del bloque
      Color colorStart;
      Color colorEnd;
      Color shadowColor;

      if (brick.maxLives == 2) {
        if (brick.currentLives == 2) {
          // Bloque fuerte intacto (Violeta/Magenta)
          colorStart = const Color(0xFFE040FB);
          colorEnd = const Color(0xFF651FFF);
          shadowColor = const Color(0xFFE040FB).withOpacity(0.4);
        } else {
          // Bloque fuerte dañado (Rosa/Rojo suave)
          colorStart = const Color(0xFFFF5252);
          colorEnd = const Color(0xFFFF1744);
          shadowColor = const Color(0xFFFF5252).withOpacity(0.4);
        }
      } else {
        // Bloque estándar (Cian/Té)
        colorStart = const Color(0xFF00E5FF);
        colorEnd = const Color(0xFF00B0FF);
        shadowColor = const Color(0xFF00E5FF).withOpacity(0.4);
      }

      // Dibujar brillo exterior/sombra del bloque (Efecto Neón)
      final Paint glowPaint = Paint()
        ..color = shadowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawRRect(brickRRect, glowPaint);

      // Dibujar relleno del bloque con gradiente
      final Paint fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorStart, colorEnd],
        ).createShader(brickRRect.outerRect);
      canvas.drawRRect(brickRRect, fillPaint);

      // Dibujar borde brillante para destacar el estilo 2.5D
      final Paint borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRRect(brickRRect, borderPaint);

      // Dibujar detalle interno (reflejo superior)
      final Paint reflectionPaint = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      
      final RRect reflectionRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(brick.x + 2, brick.y + 2, brick.width - 4, 3),
        const Radius.circular(2.0),
      );
      canvas.drawRRect(reflectionRRect, reflectionPaint);
    }
  }

  /// Dibuja la paleta del jugador con efectos metálicos y de brillo neon.
  void _drawPaddle(Canvas canvas) {
    final Rect paddleRect = Rect.fromLTWH(
      engine.paddleX,
      GameEngine.paddleY,
      GameEngine.paddleWidth,
      GameEngine.paddleHeight,
    );

    final RRect paddleRRect = RRect.fromRectAndRadius(
      paddleRect,
      const Radius.circular(8.0),
    );

    // 1. Dibujar el brillo/glow de neón detrás de la paleta
    final Paint glowPaint = Paint()
      ..color = const Color(0xFF00FF87).withOpacity(0.4) // Verde cian brillante
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    canvas.drawRRect(paddleRRect, glowPaint);

    // 2. Dibujar relleno de la paleta con gradiente metálico
    final Paint fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF00FF87), // Verde brillante
          Color(0xFF60EFFF), // Cian claro
          Color(0xFF00FF87),
        ],
      ).createShader(paddleRect);
    canvas.drawRRect(paddleRRect, fillPaint);

    // 3. Dibujar borde de relieve de paleta
    final Paint borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(paddleRRect, borderPaint);
  }

  /// Dibuja todas las pelotas con un gradiente radial que les confiere volumen tridimensional y brillo.
  void _drawBalls(Canvas canvas) {
    for (Ball ball in engine.balls) {
      final Offset ballCenter = Offset(ball.x, ball.y);

      // 1. Brillo exterior del neón de la pelota
      final Paint glowPaint = Paint()
        ..color = const Color(0xFFFFD600).withOpacity(0.5) // Oro neón
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
      canvas.drawCircle(ballCenter, GameEngine.ballRadius * 1.5, glowPaint);

      // 2. Relleno tridimensional (Gradiente Radial)
      final Paint ballPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3), // Foco de luz descentrado para efecto 3D
          radius: 0.9,
          colors: const [
            Colors.white,
            Color(0xFFFFD600), // Amarillo neón
            Color(0xFFFF6D00), // Naranja profundo en los bordes de la sombra
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromCircle(center: ballCenter, radius: GameEngine.ballRadius));

      canvas.drawCircle(ballCenter, GameEngine.ballRadius, ballPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) {
    // Al usar ChangeNotifier y super(repaint: engine), Flutter maneja la repintada eficientemente
    // cuando el motor notifica cambios.
    return true;
  }
}
