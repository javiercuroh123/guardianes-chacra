import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/features/progress/domain/progress.dart';

// TODO(fase-7): cargarlo y guardarlo con el repositorio de progreso.
/// El progreso del jugador. En la Fase 6 vive en memoria (se pierde al
/// cerrar la app).
class ProgressController extends Notifier<Progress> {
  @override
  Progress build() => const Progress();

  void recordResult(String levelId, {required int stars}) =>
      state = state.withResult(levelId, stars: stars);

  void discoverPest(String id) => state = state.discoverPest(id);

  void discoverGuardian(String id) => state = state.discoverGuardian(id);
}

final progressProvider = NotifierProvider<ProgressController, Progress>(
  ProgressController.new,
);
