import 'package:meta/meta.dart';

/// El avance del jugador: las mejores estrellas de cada nivel, lo que
/// descubrió para el Bestiario y lo que ya desbloqueó. Es inmutable: cada
/// cambio devuelve uno nuevo (o el mismo, si no cambió nada).
@immutable
class Progress {
  const new({
    this.stars = const {},
    this.discoveredPests = const {},
    this.discoveredGuardians = const {},
    this.unlockedLevels = const {},
    this.unlockedGuardians = const {},
  });

  /// Mejores estrellas por id de nivel (solo los niveles ganados).
  final Map<String, int> stars;
  final Set<String> discoveredPests;
  final Set<String> discoveredGuardians;

  /// Niveles y guardianes que ya se abrieron (ver `Progression`): quedan
  /// abiertos aunque una actualización cambie sus reglas.
  final Set<String> unlockedLevels;
  final Set<String> unlockedGuardians;

  int starsOf(String levelId) => stars[levelId] ?? 0;

  /// Estrellas juntadas entre todos los niveles.
  int get totalStars => stars.values.fold(0, (sum, value) => sum + value);

  /// Anota un resultado; solo cuenta si mejora el anterior.
  Progress withResult(String levelId, {required int stars}) {
    if (stars <= starsOf(levelId)) return this;
    return _copy(stars: {...this.stars, levelId: stars});
  }

  Progress discoverPest(String id) => discoveredPests.contains(id)
      ? this
      : _copy(discoveredPests: {...discoveredPests, id});

  Progress discoverGuardian(String id) => discoveredGuardians.contains(id)
      ? this
      : _copy(discoveredGuardians: {...discoveredGuardians, id});

  /// Suma [levels] y [guardians] a lo desbloqueado.
  Progress withUnlocked({
    Iterable<String> levels = const [],
    Iterable<String> guardians = const [],
  }) {
    if (unlockedLevels.containsAll(levels) &&
        unlockedGuardians.containsAll(guardians)) {
      return this;
    }
    return _copy(
      unlockedLevels: {...unlockedLevels, ...levels},
      unlockedGuardians: {...unlockedGuardians, ...guardians},
    );
  }

  Progress _copy({
    Map<String, int>? stars,
    Set<String>? discoveredPests,
    Set<String>? discoveredGuardians,
    Set<String>? unlockedLevels,
    Set<String>? unlockedGuardians,
  }) => Progress(
    stars: stars ?? this.stars,
    discoveredPests: discoveredPests ?? this.discoveredPests,
    discoveredGuardians: discoveredGuardians ?? this.discoveredGuardians,
    unlockedLevels: unlockedLevels ?? this.unlockedLevels,
    unlockedGuardians: unlockedGuardians ?? this.unlockedGuardians,
  );

  @override
  bool operator ==(Object other) =>
      other is Progress &&
      _sameMap(other.stars, stars) &&
      _sameSet(other.discoveredPests, discoveredPests) &&
      _sameSet(other.discoveredGuardians, discoveredGuardians) &&
      _sameSet(other.unlockedLevels, unlockedLevels) &&
      _sameSet(other.unlockedGuardians, unlockedGuardians);

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(stars.entries.map((e) => (e.key, e.value))),
    Object.hashAllUnordered(discoveredPests),
    Object.hashAllUnordered(discoveredGuardians),
    Object.hashAllUnordered(unlockedLevels),
    Object.hashAllUnordered(unlockedGuardians),
  );

  @override
  String toString() =>
      'Progress(stars: $stars, discoveredPests: $discoveredPests, '
      'discoveredGuardians: $discoveredGuardians, '
      'unlockedLevels: $unlockedLevels, '
      'unlockedGuardians: $unlockedGuardians)';

  static bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  static bool _sameMap(Map<String, int> a, Map<String, int> b) =>
      a.length == b.length &&
      a.entries.every((entry) => b[entry.key] == entry.value);
}
