import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/app/rive/rive_build_option.dart';
import 'package:guardianes_chacra/app/text_scale.dart';
import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/commands.dart';
import 'package:guardianes_chacra/features/battle/domain/world/guardian.dart';
import 'package:guardianes_chacra/features/battle/presentation/menus/battle_menus.dart';
import 'package:guardianes_chacra/features/content/domain/guardian_def.dart';

import '../../../../helpers/battle_game_helpers.dart';
import '../../../../helpers/real_content.dart';
import '../../../../helpers/test_app.dart';

void main() {
  final content = useRealContent();
  late List<MenuChoice> chosen;

  Finder key(String value) => find.byKey(ValueKey(value));

  /// La etiqueta de abajo del menú.
  String label(WidgetTester tester) => tester
      .widget<Text>(
        find.descendant(of: key('menu-label'), matching: find.byType(Text)),
      )
      .data!;

  group('BuildMenu', () {
    Future<void> pumpBuildMenu(
      WidgetTester tester, {
      int corn = 1000,
      String? preview,
    }) async {
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
              entries: [
                BuildEntry(def: guardians['hondero']!, name: 'Hondero'),
                BuildEntry(def: guardians['tullpa']!, name: 'Tullpa'),
                BuildEntry(
                  def: guardians['condor']!,
                  name: 'Cóndor',
                  lockRule: 'Se abre al ganar Andenes',
                ),
              ],
              canAfford: (cost) => cost <= corn,
              preview: preview,
              onChoose: chosen.add,
            ),
          ),
        ),
      );
      // El abanico se abre en ~0,5 s.
      await tester.pump(const Duration(milliseconds: 600));
    }

    testWidgets('un guardián que alcanza se elige con su comando', (
      tester,
    ) async {
      await pumpBuildMenu(tester);
      final hondero = content().guardians['hondero']!;

      await tester.tap(key('build-hondero'));

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

    testWidgets('lo que no alcanza el maíz se sacude y lo dice abajo', (
      tester,
    ) async {
      final tullpa = content().guardians['tullpa']!.levels.first.cost;
      await pumpBuildMenu(tester, corn: tullpa - 1);
      expect(
        tester.widget<RiveBuildOption>(key('build-tullpa')).affordable,
        isFalse,
      );

      await tester.tap(key('build-tullpa'));
      await tester.pump();

      expect(chosen, isEmpty);
      expect(label(tester), 'No alcanza el maíz');
    });

    testWidgets('un guardián bloqueado se ve con candado y dice su regla', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpBuildMenu(tester);
      expect(
        tester.widget<RiveBuildOption>(key('build-condor')).locked,
        isTrue,
      );
      expect(
        find.bySemanticsLabel('Cóndor: bloqueado. Se abre al ganar Andenes'),
        findsOneWidget,
      );

      await tester.tap(key('build-condor'));
      await tester.pump();

      expect(chosen, isEmpty);
      expect(label(tester), 'Se abre al ganar Andenes');
      semantics.dispose();
    });

    testWidgets('la etiqueta guía: elegir, qué ataca y confirmar', (
      tester,
    ) async {
      await pumpBuildMenu(tester);
      expect(label(tester), 'Toca un guardián para ver su alcance');

      await pumpBuildMenu(tester, preview: 'tullpa');
      expect(
        label(tester),
        'Tullpa · plagas de tierra\nToca otra vez para confirmar',
      );
      expect(
        tester.widget<RiveBuildOption>(key('build-tullpa')).selected,
        isTrue,
      );
    });

    testWidgets('las tarjetas salen del espacio una tras otra', (tester) async {
      usePhoneLandscape(tester);
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: BuildMenu(
              slotId: 'e1',
              center: const Offset(400, 190),
              bounds: const Size(853, 384),
              entries: [
                for (final def in content().guardians.values)
                  BuildEntry(def: def, name: def.id),
              ],
              canAfford: (_) => true,
              onChoose: (_) {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 120));
      final first = tester.getCenter(key('build-hondero'));
      final last = tester.getCenter(
        key('build-${content().guardians.keys.last}'),
      );
      // La primera ya se alejó del centro; la última sigue cerca.
      expect((first - const Offset(400, 190)).distance, greaterThan(20));
      expect((last - const Offset(400, 190)).distance, lessThan(20));

      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
    });

    testWidgets('con letra grande crece hasta 1,3', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpBuildMenu(tester);

      final context = tester.element(key('build-hondero'));
      expect(
        MediaQuery.textScalerOf(context).scale(10),
        closeTo(10 * TextScaleLimits.battle, 1e-9),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('GuardianCard', () {
    late List<PlayerCommand> commands;
    late List<String> events;

    Future<void> pumpCard(
      WidgetTester tester,
      GuardianView guardian, {
      int corn = 1000,
      String? preview,
    }) async {
      usePhoneLandscape(tester);
      chosen = [];
      commands = [];
      events = [];
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: GuardianCard(
              guardian: guardian,
              center: const Offset(200, 190),
              bounds: const Size(853, 384),
              sellValue: 42,
              canAfford: (cost) => cost <= corn,
              nameOf: (type) =>
                  content().texts.text('guardian.$type.name', language: 'es'),
              branchNameOf: (branch) => branch,
              locale: 'es',
              preview: preview,
              onChoose: chosen.add,
              onCommand: commands.add,
              onSpecialize: () => events.add('specialize'),
              onClose: () => events.add('close'),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('muestra nivel, a qué ataca y "actual → siguiente"', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpCard(tester, _FakeGuardian(content().guardians['hondero']!));

      expect(
        find.bySemanticsLabel(
          RegExp(
            r'^Hondero · Nivel 1\. Ataca: tierra y aire\. Daño: \d+, luego \d+',
          ),
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('Mejorar y Vender se eligen; Objetivo cambia con un toque', (
      tester,
    ) async {
      final hondero = content().guardians['hondero']!;
      await pumpCard(tester, _FakeGuardian(hondero));

      await tester.tap(key('menu-upgrade'));
      await tester.tap(key('menu-sell'));
      await tester.tap(key('menu-targeting'));
      await tester.tap(key('menu-close'));

      expect(chosen.map((choice) => choice.id), ['upgrade', 'sell']);
      expect(chosen.first.range, hondero.levels[1].range);
      expect(chosen.first.command, isA<UpgradeGuardian>());
      expect(chosen.last.command, isA<SellGuardian>());
      expect(
        commands.single,
        isA<SetTargeting>().having((c) => c.strategy, 'strategy', 'last'),
      );
      expect(events, ['close']);
      expect(find.text('Vender +42'), findsOneWidget);
      expect(find.text('Objetivo: Primera'), findsOneWidget);
    });

    testWidgets('sin maíz, Mejorar se sacude y lo dice abajo', (tester) async {
      await pumpCard(
        tester,
        _FakeGuardian(content().guardians['hondero']!),
        corn: 0,
      );

      await tester.tap(key('menu-upgrade'));
      await tester.pump();

      expect(chosen, isEmpty);
      expect(label(tester), 'No alcanza el maíz');
    });

    testWidgets('el primer toque pide confirmar abajo', (tester) async {
      await pumpCard(
        tester,
        _FakeGuardian(content().guardians['hondero']!),
        preview: 'upgrade',
      );

      expect(label(tester), 'Toca otra vez para confirmar');
    });

    testWidgets('en el último nivel ofrece Especializar', (tester) async {
      final hondero = content().guardians['hondero']!;
      await pumpCard(
        tester,
        _FakeGuardian(hondero, level: hondero.levels.length),
      );

      expect(key('menu-upgrade'), findsNothing);
      await tester.tap(key('menu-specialize'));
      expect(events, ['specialize']);
    });

    testWidgets('el Pututu no ataca: no tiene Objetivo', (tester) async {
      await pumpCard(tester, _FakeGuardian(content().guardians['pututu']!));

      expect(key('menu-targeting'), findsNothing);
      expect(key('menu-sell'), findsOneWidget);
    });
  });

  group('SpecializationWindow', () {
    Future<void> pumpWindow(
      WidgetTester tester, {
      int corn = 1000,
      String? preview,
    }) async {
      usePhoneLandscape(tester);
      chosen = [];
      final hondero = content().guardians['hondero']!;
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: SpecializationWindow(
              guardian: _FakeGuardian(hondero, level: hondero.levels.length),
              canAfford: (cost) => cost <= corn,
              branchNameOf: (branch) => branch,
              branchDescriptionOf: (branch) => 'Descripción de $branch',
              preview: preview,
              onChoose: chosen.add,
              onClose: () => chosen.clear(),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('tocar una rama la elige con su comando', (tester) async {
      await pumpWindow(tester);
      final branch = content().guardians['hondero']!.branches.first;

      await tester.tap(key('menu-branch-${branch.id}'));

      expect(chosen.single.id, 'branch:${branch.id}');
      expect(chosen.single.range, branch.level.range);
      expect(
        chosen.single.command,
        isA<SpecializeGuardian>().having(
          (c) => c.branchId,
          'branchId',
          branch.id,
        ),
      );
    });

    testWidgets('Elegir confirma la rama marcada', (tester) async {
      final branch = content().guardians['hondero']!.branches.last;
      await pumpWindow(tester, preview: 'branch:${branch.id}');

      await tester.tap(key('menu-branch-confirm'));

      expect(chosen.single.id, 'branch:${branch.id}');
    });

    testWidgets('sin rama marcada, Elegir no hace nada', (tester) async {
      await pumpWindow(tester);

      await tester.tap(key('menu-branch-confirm'), warnIfMissed: false);

      expect(chosen, isEmpty);
    });

    testWidgets('sin maíz, la rama no se elige', (tester) async {
      await pumpWindow(tester, corn: 0);
      final branch = content().guardians['hondero']!.branches.first;

      await tester.tap(key('menu-branch-${branch.id}'));
      await tester.pump();

      expect(chosen, isEmpty);
      expect(find.text('No alcanza el maíz'), findsOneWidget);
    });
  });
}

/// Un guardián construido, sin simulación.
class _FakeGuardian implements GuardianView {
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
