import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:guardianes_chacra/features/battle/domain/world/guardian.dart';
import 'package:guardianes_chacra/features/content/domain/guardian_def.dart';

/// Un guardián construido, sin simulación.
class FakeGuardian implements GuardianView {
  new(this.def, {this.level = 1});

  @override
  final GuardianDef def;

  @override
  final int level;

  @override
  int get id => 1;

  @override
  String get slotId => 'e1';

  @override
  Vec2 get position => const Vec2(3, 3);

  @override
  String? get branchId => null;

  @override
  String get targetingId => 'first';

  @override
  double get range => def.levels[level - 1].range;

  @override
  double get attackSpeedMultiplier => 1;

  @override
  int get totalSpent => 60;
}
