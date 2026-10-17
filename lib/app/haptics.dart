import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/core/services/haptics_service.dart';

/// La vibración de la app. Por defecto, apagada; `main.dart` pone la real
/// (`SystemHapticsService`). El interruptor de Ajustes lo respeta cada
/// partida (ver `BattleFeedback`).
final hapticsServiceProvider = Provider<HapticsService>(
  (ref) => SilentHapticsService(),
);
