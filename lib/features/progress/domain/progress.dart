import 'package:meta/meta.dart';

/// El avance del jugador: las mejores estrellas de cada nivel y lo que ya
/// descubrió para el Bestiario. Es inmutable: cada cambio devuelve uno
/// nuevo (o el mismo, si no cambió nada).
///
/// En la Fase 6 vive en memoria; en la Fase 7 se guarda en el teléfono.
@immutable
class Progress {
  const new({
    this.stars = const {},
    this.discoveredPests = const {},
    this.discoveredGuardians = const {},
  });

  /// Mejores estrellas por id de nivel (solo los niveles ganados).
  final Map<String, int> stars;
  final Set<String> discoveredPests;
  final Set<String> discoveredGuardians;

  int starsOf(String levelId) => stars[levelId] ?? 0;

  /// Anota un resultado; solo cuenta si mejora el anterior.
  Progress withResult(String levelId, {required int stars}) {
    if (stars <= starsOf(levelId)) return this;
    return _copy(stars: {...this.stars, levelId: stars});
  }

  // TODO(fase-7): las reglas de desbloqueo pasan a los datos.
  /// Si el nivel en la posición [index] de [levelIds] está abierto: por
  /// ahora, el primero siempre y cada uno de los demás al ganar el anterior.
  bool isUnlocked(List<String> levelIds, int index) =>
      index == 0 || starsOf(levelIds[index - 1]) > 0;

  Progress discoverPest(String id) => discoveredPests.contains(id)
      ? this
      : _copy(discoveredPests: {...discoveredPests, id});

  Progress discoverGuardian(String id) => discoveredGuardians.contains(id)
      ? this
      : _copy(discoveredGuardians: {...discoveredGuardians, id});

  Progress _copy({
    Map<String, int>? stars,
    Set<String>? discoveredPests,
    Set<String>? discoveredGuardians,
  }) => Progress(
    stars: stars ?? this.stars,
    discoveredPests: discoveredPests ?? this.discoveredPests,
    discoveredGuardians: discoveredGuardians ?? this.discoveredGuardians,
  );
}
