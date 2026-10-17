import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/features/progress/domain/progress.dart';
import 'package:guardianes_chacra/features/progress/domain/progression.dart';
import 'package:guardianes_chacra/features/progress/presentation/save_providers.dart';

/// El avance del jugador. Empieza desde el guardado; cada cambio lo guarda
/// el autoguardado (`lib/app/autosave.dart`), no este controlador.
class ProgressController extends Notifier<Progress> {
  @override
  Progress build() => ref.watch(savedGameProvider).progress;

  /// Anota un resultado con las reglas de [progression] y devuelve lo que
  /// se abrió recién.
  Unlocked recordResult(
    String levelId, {
    required int stars,
    required Progression progression,
  }) {
    final (progress, unlocked) = progression.record(
      state,
      levelId,
      stars: stars,
    );
    state = progress;
    return unlocked;
  }

  void discoverPest(String id) => state = state.discoverPest(id);

  void discoverGuardian(String id) => state = state.discoverGuardian(id);
}

final progressProvider = NotifierProvider<ProgressController, Progress>(
  ProgressController.new,
);
