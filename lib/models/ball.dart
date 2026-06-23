/// Clase modelo que representa una pelota en el juego.
/// Soporta la existencia de múltiples pelotas en pantalla.
class Ball {
  /// Posición lógica horizontal (coordenada X).
  double x;

  /// Posición lógica vertical (coordenada Y).
  double y;

  /// Velocidad horizontal (píxeles lógicos por segundo).
  double vx;

  /// Velocidad vertical (píxeles lógicos por segundo).
  double vy;

  /// Indica si esta pelota específica está "pegada" a la paleta del jugador.
  bool isAttached;

  Ball({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    this.isAttached = false,
  });
}
