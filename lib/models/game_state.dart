/// Define los diferentes estados en los que puede encontrarse la partida.
enum GameState {
  /// Pantalla inicial del juego, esperando que el jugador presione "Iniciar".
  start,

  /// El juego está activo y actualizándose a 60 FPS.
  playing,

  /// La partida ha sido pausada temporalmente por el jugador.
  paused,

  /// El jugador ha agotado todas sus vidas.
  gameOver,

  /// El jugador ha completado todos los niveles disponibles.
  gameWon,

  /// Pantalla intermedia de transición al superar un nivel.
  nextLevel,
}
