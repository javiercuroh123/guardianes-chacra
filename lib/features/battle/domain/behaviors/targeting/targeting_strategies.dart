import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:guardianes_chacra/features/battle/domain/world/pest.dart';

/// Decide a cuál de las plagas atacables apunta un guardián. El jugador
/// puede cambiarla en cada guardián.
abstract interface class TargetingStrategy {
  /// Elige entre [candidates] (ya filtradas por alcance y etiquetas) desde
  /// [origin], la posición del guardián. `null` si no hay ninguna.
  Pest? choose(List<Pest> candidates, Vec2 origin);
}

/// La que va primera: la que más avanzó hacia la collca.
final class FirstTargeting implements TargetingStrategy {
  const new();

  @override
  Pest? choose(List<Pest> candidates, Vec2 origin) =>
      _best(candidates, (a, b) => a.distance.compareTo(b.distance));
}

/// La que va última: la que menos avanzó.
final class LastTargeting implements TargetingStrategy {
  const new();

  @override
  Pest? choose(List<Pest> candidates, Vec2 origin) =>
      _best(candidates, (a, b) => b.distance.compareTo(a.distance));
}

/// La que tiene más vida; si empatan, la que va primera.
final class StrongestTargeting implements TargetingStrategy {
  const new();

  @override
  Pest? choose(List<Pest> candidates, Vec2 origin) => _best(candidates, (a, b) {
    final byHealth = a.health.compareTo(b.health);
    return byHealth != 0 ? byHealth : a.distance.compareTo(b.distance);
  });
}

/// La más cercana al guardián; si empatan, la que va primera.
final class ClosestTargeting implements TargetingStrategy {
  const new();

  @override
  Pest? choose(List<Pest> candidates, Vec2 origin) => _best(candidates, (a, b) {
    // Más cerca es mejor: se compara al revés.
    final byDistance = origin
        .distanceSquaredTo(b.position)
        .compareTo(origin.distanceSquaredTo(a.position));
    return byDistance != 0 ? byDistance : a.distance.compareTo(b.distance);
  });
}

/// La mejor según [compare] (positivo = `a` es mejor que `b`). En un empate
/// gana el menor id, para que el resultado nunca dependa del orden de la
/// lista.
Pest? _best(List<Pest> candidates, int Function(Pest a, Pest b) compare) {
  Pest? best;
  for (final pest in candidates) {
    if (best == null) {
      best = pest;
      continue;
    }
    final order = compare(pest, best);
    if (order > 0 || (order == 0 && pest.id < best.id)) best = pest;
  }
  return best;
}
