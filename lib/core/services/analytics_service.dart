import 'package:flutter/foundation.dart';

/// La analítica, detrás de una interfaz (como el audio y los anuncios): el
/// juego anota eventos con nombre y datos, y no sabe a dónde van. Por ahora
/// la app usa [DebugAnalyticsService] (los escribe en la consola); con
/// Firebase Analytics (Fase 11) solo se agrega otra implementación.
abstract interface class AnalyticsService {
  /// Anota [event] con sus [parameters] (textos o números).
  void log(String event, Map<String, Object> parameters);
}

/// No anota nada. Es la implementación por defecto (tests y release, hasta
/// conectar un servicio real).
class NoAnalyticsService implements AnalyticsService {
  @override
  void log(String event, Map<String, Object> parameters) {}
}

/// Escribe cada evento en la consola, para ver qué se mandaría.
class DebugAnalyticsService implements AnalyticsService {
  @override
  void log(String event, Map<String, Object> parameters) =>
      debugPrint('Analítica: $event $parameters');
}
