import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Los niveles recién abiertos que el valle todavía no mostró. La batalla
/// los suma al ganar; el valle, la próxima vez que se ve, dibuja el camino
/// de piedritas hasta cada uno y los saca. Vive en memoria: si el juego se
/// cierra antes, el camino aparece ya hecho.
class ValleyRevealController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void add(Iterable<String> levelIds) {
    if (levelIds.isEmpty) return;
    state = {...state, ...levelIds};
  }

  void clear() => state = const {};
}

final valleyRevealProvider =
    NotifierProvider<ValleyRevealController, Set<String>>(
      ValleyRevealController.new,
    );
