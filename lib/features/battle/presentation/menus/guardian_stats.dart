import 'package:guardianes_chacra/app/rive/rive_guardian_info.dart';
import 'package:guardianes_chacra/app/rive/rive_icons.dart';
import 'package:guardianes_chacra/features/content/domain/behavior_spec.dart';
import 'package:guardianes_chacra/features/content/domain/guardian_def.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';
import 'package:guardianes_chacra/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// Lo que muestra la ficha de un guardián, sacado de sus datos: la
/// estadística principal (daño; frenado para la Llama; brío para el
/// Pututu), el alcance y a qué plagas ataca.
///
/// Los valores van "actual → siguiente" si hay una mejora.
abstract final class GuardianStats {
  /// Las dos filas de la ficha para pasar de [current] a [next] (`null` en
  /// el último nivel o ya especializado).
  static List<GuardianStat> rows(
    GuardianLevelDef current,
    GuardianLevelDef? next, {
    required AppLocalizations l10n,
    required String locale,
  }) {
    final number = NumberFormat('#,##0.#', locale);
    final main = _main(current);
    final mainNext = next == null ? null : _main(next);
    return [
      GuardianStat(
        icon: main.icon,
        label: switch (main.kind) {
          _Kind.damage => l10n.cardDamage,
          _Kind.slow => l10n.cardSlow,
          _Kind.speedBonus => l10n.cardBoost,
        },
        current: main.format(number),
        next: mainNext?.format(number),
      ),
      GuardianStat(
        icon: RiveIcon.target,
        label: l10n.cardRange,
        current: number.format(current.range),
        next: next == null ? null : number.format(next.range),
      ),
    ];
  }

  /// "Ataca: tierra y aire".
  static String attacks(GuardianLevelDef level, AppLocalizations l10n) =>
      l10n.menuAttacks(targets(level, l10n));

  /// "tierra y aire", "plagas voladoras"…
  static String targets(GuardianLevelDef level, AppLocalizations l10n) {
    final ground = level.targets.contains(PestTag.ground);
    final flying = level.targets.contains(PestTag.flying);
    return switch ((ground, flying)) {
      (true, true) => l10n.targetsBoth,
      (true, false) => l10n.targetsGround,
      (false, true) => l10n.targetsAir,
      (false, false) => l10n.targetsNone,
    };
  }

  /// El ícono junto a "Ataca": tierra, aire, los dos (mira) o apoyo.
  static RiveIcon attackIcon(GuardianLevelDef level) {
    final ground = level.targets.contains(PestTag.ground);
    final flying = level.targets.contains(PestTag.flying);
    return switch ((ground, flying)) {
      (true, true) => RiveIcon.target,
      (true, false) => RiveIcon.ground,
      (false, true) => RiveIcon.air,
      (false, false) => RiveIcon.shield,
    };
  }

  static _Main _main(GuardianLevelDef level) {
    for (final behavior in level.behaviors) {
      if (behavior.type == 'support_aura') {
        final bonus = _number(behavior, 'attackSpeedBonus');
        return _Main(_Kind.speedBonus, bonus * 100, RiveIcon.fastForward);
      }
    }
    for (final behavior in level.behaviors) {
      final slow = _onHit(behavior, 'slow');
      if (slow != null) {
        final factor = _number(slow, 'factor', fallback: 1);
        return _Main(_Kind.slow, (1 - factor) * 100, RiveIcon.pause);
      }
    }
    var damage = 0.0;
    for (final behavior in level.behaviors) {
      damage += _number(behavior, 'damage');
    }
    return _Main(_Kind.damage, damage, RiveIcon.damage);
  }

  /// El efecto [type] que deja al golpear, si lo tiene.
  static BehaviorSpec? _onHit(BehaviorSpec behavior, String type) {
    final effects = behavior.params['onHit'];
    if (effects is! List) return null;
    for (final effect in effects) {
      if (effect is Map && effect['type'] == type) {
        return BehaviorSpec(type, Map<String, Object?>.from(effect));
      }
    }
    return null;
  }

  static double _number(
    BehaviorSpec behavior,
    String key, {
    double fallback = 0,
  }) => (behavior.params[key] as num?)?.toDouble() ?? fallback;
}

enum _Kind { damage, slow, speedBonus }

class _Main {
  const new(this.kind, this.value, this.icon);

  final _Kind kind;
  final double value;
  final RiveIcon icon;

  /// El daño tal cual; frenado y brío en porcentaje. El signo menos es un
  /// guion: la letra recortada no trae el tipográfico.
  String format(NumberFormat number) => switch (kind) {
    _Kind.damage => number.format(value),
    _Kind.slow => '-${value.round()} %',
    _Kind.speedBonus => '+${value.round()} %',
  };
}
