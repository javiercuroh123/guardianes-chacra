import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/app/text_scale.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/commands.dart';
import 'package:guardianes_chacra/features/battle/presentation/menus/battle_menus.dart';

import '../../../../helpers/battle_game_helpers.dart';
import '../../../../helpers/real_content.dart';
import '../../../../helpers/test_app.dart';

void main() {
  final content = useRealContent();
  late List<MenuChoice> chosen;

  Future<void> pumpBuildMenu(WidgetTester tester, {int corn = 1000}) async {
    usePhoneLandscape(tester);
    chosen = [];
    final guardians = content().guardians;
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: BuildMenu(
            slotId: 'e1',
            center: const Offset(400, 190),
            bounds: const Size(853, 384),
            guardians: [guardians['hondero']!, guardians['tullpa']!],
            canAfford: (cost) => cost <= corn,
            nameOf: (type) => type,
            onChoose: chosen.add,
          ),
        ),
      ),
    );
  }

  testWidgets('un guardián que alcanza se elige con su comando', (
    tester,
  ) async {
    await pumpBuildMenu(tester);
    final hondero = content().guardians['hondero']!;

    await tester.tap(find.byKey(const ValueKey('build-hondero')));

    final choice = chosen.single;
    expect(choice.id, 'hondero');
    expect(choice.range, hondero.levels.first.range);
    expect(
      choice.command,
      isA<BuildGuardian>()
          .having((c) => c.slotId, 'slotId', 'e1')
          .having((c) => c.guardianType, 'guardianType', 'hondero'),
    );
  });

  testWidgets('lo que no alcanza el maíz no responde', (tester) async {
    final tullpa = content().guardians['tullpa']!.levels.first.cost;
    await pumpBuildMenu(tester, corn: tullpa - 1);

    await tester.tap(find.byKey(const ValueKey('build-tullpa')));

    expect(chosen, isEmpty);
  });

  testWidgets('con letra grande crece hasta 1,3', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpBuildMenu(tester);

    final context = tester.element(find.byKey(const ValueKey('build-hondero')));
    expect(
      MediaQuery.textScalerOf(context).scale(10),
      closeTo(10 * TextScaleLimits.battle, 1e-9),
    );
    expect(tester.takeException(), isNull);
  });
}
