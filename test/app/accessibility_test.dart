import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/app/ads.dart';
import 'package:guardianes_chacra/app/rive/rive_ui.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/simulation.dart';
import 'package:guardianes_chacra/features/battle/presentation/hud/battle_hud.dart';
import 'package:guardianes_chacra/features/battle/presentation/hud/battle_hud_state.dart';
import 'package:guardianes_chacra/features/battle/presentation/menus/battle_menus.dart';
import 'package:guardianes_chacra/features/battle/presentation/overlays/battle_overlays.dart';
import 'package:guardianes_chacra/features/bestiary/presentation/bestiary_screen.dart';
import 'package:guardianes_chacra/features/content/domain/content_texts.dart';
import 'package:guardianes_chacra/features/level_select/presentation/level_preview_screen.dart';
import 'package:guardianes_chacra/features/level_select/presentation/level_select_screen.dart';
import 'package:guardianes_chacra/features/menu/presentation/title_screen.dart';
import 'package:guardianes_chacra/features/progress/domain/progress.dart';
import 'package:guardianes_chacra/features/progress/domain/progress_repository.dart';
import 'package:guardianes_chacra/features/progress/presentation/save_providers.dart';
import 'package:guardianes_chacra/features/settings/presentation/settings_screen.dart';
import 'package:rive/rive.dart' as rive;

import '../helpers/battle_game_helpers.dart';
import '../helpers/fake_ads_service.dart';
import '../helpers/fake_guardian.dart';
import '../helpers/real_content.dart';
import '../helpers/test_app.dart';

/// La accesibilidad de cada pantalla, dibujada con el archivo real de Rive
/// y las letras del juego (Fase 8 de la interfaz):
/// - todo lo que se toca tiene etiqueta para TalkBack y mide al menos
///   48 × 48 dp, y el texto de Flutter cumple el contraste AA (las guías de
///   accesibilidad de Flutter);
/// - con la letra grande del teléfono no se desborda nada: hasta 2× en los
///   menús y hasta 1,3× en la partida (`TextScaleLimits`);
/// - con "menos movimiento" todo se dibuja igual.
///
/// Usa las librerías nativas de rive_native (ver `rive_contract_test.dart`).
void main() {
  final content = useRealContent();
  late rive.File file;

  setUpAll(() async {
    for (final (family, path) in [
      ('Fredoka', 'assets/fonts/Fredoka-Variable.ttf'),
      ('LilitaOne', 'assets/fonts/LilitaOne-Regular.ttf'),
    ]) {
      final bytes = io.File(path).readAsBytes().then(ByteData.sublistView);
      await (FontLoader(family)..addFont(bytes)).load();
    }
    final bytes = await io.File(RiveUi.asset).readAsBytes();
    file = (await rive.File.decode(bytes, riveFactory: rive.Factory.flutter))!;
  });

  tearDownAll(() => file.dispose());

  // Con todo descubierto y desbloqueado, cada pantalla muestra lo máximo.
  Progress everything() => Progress(
    stars: {for (final level in content().levels) level.id: 3},
    discoveredPests: content().pests.keys.toSet(),
    seenPests: content().pests.keys.toSet(),
    discoveredGuardians: content().guardians.keys.toSet(),
    seenGuardians: content().guardians.keys.toSet(),
    unlockedLevels: {for (final level in content().levels) level.id},
    unlockedGuardians: content().guardians.keys.toSet(),
  );

  /// Las pantallas de menú y los overlays de la partida (letra hasta 2×),
  /// con lo que tardan en terminar de entrar.
  final menus = <String, (Widget Function(), Duration)>{
    'título': (() => const TitleScreen(), const Duration(milliseconds: 1600)),
    'valle': (
      () => const LevelSelectScreen(),
      const Duration(milliseconds: 1000),
    ),
    'bestiario': (
      () => const BestiaryScreen(),
      const Duration(milliseconds: 800),
    ),
    'ajustes': (
      () => const SettingsScreen(),
      const Duration(milliseconds: 800),
    ),
    for (final level in ['chacra_del_valle', 'andenes', 'orilla_del_lago'])
      'preparación de $level': (
        () => LevelPreviewScreen(levelId: level),
        const Duration(milliseconds: 1600),
      ),
    'pausa': (
      () => Scaffold(
        body: PauseOverlay(onResume: () {}, onRetry: () {}, onExit: () {}),
      ),
      const Duration(milliseconds: 800),
    ),
    'victoria': (
      () => Scaffold(
        body: VictoryOverlay(
          stars: 3,
          potatoes: 20,
          maxPotatoes: 20,
          cornHarvested: 1234,
          unlocked: const [
            UnlockedItem.level(
              levelId: 'orilla_del_lago',
              name: 'Orilla del Lago',
              color: Colors.teal,
            ),
            UnlockedItem.guardian(
              guardianId: 'condor',
              name: 'Cóndor',
              color: Colors.brown,
            ),
          ],
          onNext: () {},
          onRetry: () {},
          onExit: () {},
        ),
      ),
      const Duration(milliseconds: 3600),
    ),
    'derrota': (
      () => Scaffold(
        body: DefeatOverlay(
          potatoes: 0,
          maxPotatoes: 20,
          onRetry: () {},
          onExit: () {},
          onRevive: () {},
          revivePotatoes: 5,
        ),
      ),
      const Duration(milliseconds: 1200),
    ),
  };

  /// Lo de la partida (letra hasta 1,3×), en los lugares que les da
  /// `BattleScreen`.
  final battle = <String, Widget Function()>{
    'HUD': () => Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 4,
            left: 6,
            right: 6,
            child: BattleHud(onToggleSpeed: () {}, onPause: () {}),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: BattleNextWave(onNextWave: () {}),
          ),
        ],
      ),
    ),
    'menú de construcción': () {
      final guardians = content().guardians;
      return Scaffold(
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
          canAfford: (cost) => cost <= 100,
          onChoose: (_) {},
        ),
      );
    },
    'ficha del guardián': () => Scaffold(
      body: GuardianCard(
        guardian: FakeGuardian(content().guardians['hondero']!),
        center: const Offset(200, 190),
        bounds: const Size(853, 384),
        sellValue: 42,
        canAfford: (cost) => cost <= 1000,
        nameOf: (type) =>
            content().texts.text('guardian.$type.name', language: 'es'),
        branchNameOf: (branch) => branch,
        locale: 'es',
        onChoose: (_) {},
        onCommand: (_) {},
        onSpecialize: () {},
        onClose: () {},
      ),
    ),
    'especialización': () {
      final hondero = content().guardians['hondero']!;
      return Scaffold(
        body: SpecializationWindow(
          guardian: FakeGuardian(hondero, level: hondero.levels.length),
          canAfford: (cost) => cost <= 1000,
          branchNameOf: (branch) => content().texts.text(
            ContentTexts.branchName('hondero', branch),
            language: 'es',
          ),
          branchDescriptionOf: (branch) => content().texts.text(
            ContentTexts.branchDescription('hondero', branch),
            language: 'es',
          ),
          onChoose: (_) {},
          onClose: () {},
        ),
      );
    },
  };

  const hud = BattleHudState(
    corn: 1220,
    potatoes: 20,
    wave: 10,
    totalWaves: 10,
    status: BattleStatus.playing,
    nextWaveSeconds: 12,
    earlyCallBonus: 18,
  );

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    Duration wait = const Duration(milliseconds: 800),
    double scale = 1,
    bool calm = false,
  }) async {
    usePhoneLandscape(tester);
    // Un desborde llega al test sin decir dónde fue: se imprime el detalle
    // completo (qué widget y en qué línea).
    final onError = FlutterError.onError;
    FlutterError.onError = (details) {
      debugPrint(details.toString());
      onError?.call(details);
    };
    addTearDown(() => FlutterError.onError = onError);
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    if (calm) {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
    }
    await tester.pumpWidget(
      testApp(
        screen,
        overrides: <Override>[
          riveFileProvider.overrideWithValue(file),
          contentOverride(content()),
          adsServiceProvider.overrideWithValue(FakeAdsService()),
          savedGameProvider.overrideWithValue(SaveData(progress: everything())),
        ],
      ),
    );
    final hudFinder = find.byType(BattleHud);
    if (hudFinder.evaluate().isNotEmpty) {
      containerOf(tester, Scaffold).read(battleHudProvider.notifier).hud = hud;
    }
    for (
      var t = Duration.zero;
      t < wait;
      t += const Duration(milliseconds: 100)
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Sin errores de Flutter (un desborde es uno); si hay, con su detalle
  /// (qué widget y dónde).
  void expectNoErrors(WidgetTester tester) {
    final error = tester.takeException();
    if (error is FlutterError) fail(error.toStringDeep());
    expect(error, isNull);
  }

  /// Con `--dart-define=SEMANTICS_DIR=<carpeta>`, guarda lo que leería
  /// TalkBack en cada pantalla (`<carpeta>/<pantalla>.txt`, en el orden de
  /// lectura) para revisar las etiquetas.
  const semanticsDir = String.fromEnvironment('SEMANTICS_DIR');

  Future<void> expectGuidelines(WidgetTester tester, String name) async {
    if (semanticsDir.isNotEmpty) {
      final root = tester
          .binding
          .renderViews
          .first
          .owner!
          .semanticsOwner!
          .rootSemanticsNode!;
      io.File('$semanticsDir/$name.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync(root.toStringDeep());
    }
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }

  group('menús y overlays', () {
    for (final MapEntry(key: name, value: (screen, wait)) in menus.entries) {
      testWidgets('$name: etiquetas, tamaño de los toques y contraste', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await pumpScreen(tester, screen(), wait: wait);
        await expectGuidelines(tester, name);
        semantics.dispose();
      });

      testWidgets('$name: con la letra a ×2 no se desborda', (tester) async {
        await pumpScreen(tester, screen(), wait: wait, scale: 2);
        expectNoErrors(tester);
      });

      testWidgets('$name: con menos movimiento', (tester) async {
        await pumpScreen(tester, screen(), wait: wait, calm: true);
        expectNoErrors(tester);
      });
    }
  });

  group('partida', () {
    for (final MapEntry(key: name, value: screen) in battle.entries) {
      testWidgets('$name: etiquetas, tamaño de los toques y contraste', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await pumpScreen(tester, screen());
        await expectGuidelines(tester, name);
        semantics.dispose();
      });

      testWidgets('$name: con la letra a ×1,3 no se desborda', (tester) async {
        await pumpScreen(tester, screen(), scale: 1.3);
        expectNoErrors(tester);
      });

      testWidgets('$name: con menos movimiento', (tester) async {
        await pumpScreen(tester, screen(), calm: true);
        expectNoErrors(tester);
      });
    }
  });
}
