/// Clase modelo que representa un bloque dentro del juego.
/// Contiene su posición lógica, dimensiones, resistencia y puntaje.
class Brick {
  /// Posición horizontal superior izquierda (coordenada X lógica).
  final double x;

  /// Posición vertical superior izquierda (coordenada Y lógica).
  final double y;

  /// Ancho lógico del bloque.
  final double width;

  /// Alto lógico del bloque.
  final double height;

  /// Cantidad inicial de golpes requeridos para romper el bloque.
  final int maxLives;

  /// Cantidad de golpes restantes para romper el bloque.
  int currentLives;

  /// Puntos otorgados al romper por completo este bloque.
  final int scoreValue;

  Brick({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.maxLives,
    this.scoreValue = 100,
  }) : currentLives = maxLives;

  /// Registra un golpe reduciendo la vida del bloque.
  void hit() {
    if (currentLives > 0) {
      currentLives--;
    }
  }

  /// Retorna si el bloque ha sido completamente destruido.
  bool get isDestroyed => currentLives <= 0;
}
