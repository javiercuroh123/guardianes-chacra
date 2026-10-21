import 'dart:io' as io;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/app/ads.dart';
import 'package:guardianes_chacra/app/rive/rive_curtain.dart';
import 'package:guardianes_chacra/app/rive/rive_ui.dart';
import 'package:guardianes_chacra/core/services/ads_service.dart';
import 'package:guardianes_chacra/features/battle/presentation/overlays/battle_overlays.dart';
import 'package:guardianes_chacra/features/bestiary/presentation/bestiary_screen.dart';
import 'package:guardianes_chacra/features/level_select/presentation/level_preview_screen.dart';
import 'package:guardianes_chacra/features/level_select/presentation/level_select_screen.dart';
import 'package:guardianes_chacra/features/menu/presentation/title_screen.dart';
import 'package:guardianes_chacra/features/progress/domain/progress.dart';
import 'package:guardianes_chacra/features/progress/domain/progress_repository.dart';
import 'package:guardianes_chacra/features/progress/presentation/save_providers.dart';
import 'package:guardianes_chacra/features/settings/presentation/settings_screen.dart';
import 'package:rive/rive.dart' as rive;

import '../../helpers/fake_ads_service.dart';
import '../../helpers/real_content.dart';
import '../../helpers/test_app.dart';

/// Dibuja con el archivo real la pausa, la victoria y la derrota (Fase 5)
/// en un teléfono apaisado: si a un artboard le falta algo que el
/// envoltorio busca, ese envoltorio cae a su respaldo de Flutter y este
/// test lo nota.
///
/// Para ver las imágenes (`build/scene_pausa.png`, etc.):
/// `flutter test test/app/rive/rive_scenes_test.dart
/// --dart-define=SCENES_PNG=build/scene`.
///
/// Usa las librerías nativas de rive_native (ver `rive_contract_test.dart`).
void main() {
  final content = useRealContent();
  late rive.File file;

  setUpAll(() async {
    // Las letras del juego: con la de prueba de Flutter (cuadrados) los
    // botones medirían de más.
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

  final scenes = <String, (Widget, Duration)>{
    // El logo termina de armarse al segundo.
    'titulo': (const TitleScreen(), const Duration(milliseconds: 1500)),
    // La cortina entre pantallas, cerrándose y cerrada (Fase 8).
    'cortina_cerrandose': (
      const RiveCurtain(progress: AlwaysStoppedAnimation(0.15)),
      const Duration(milliseconds: 100),
    ),
    'cortina_cerrada': (
      const RiveCurtain(progress: AlwaysStoppedAnimation(0.5)),
      const Duration(milliseconds: 100),
    ),
    'pausa': (
      PauseOverlay(onResume: () {}, onRetry: () {}, onExit: () {}),
      const Duration(seconds: 1),
    ),
    // A media lluvia: la coreografía termina a los 3,2 s.
    'victoria': (
      VictoryOverlay(
        stars: 2,
        potatoes: 14,
        maxPotatoes: 20,
        cornHarvested: 480,
        unlocked: const [
          UnlockedItem.level(
            levelId: 'andenes',
            name: 'Andenes',
            color: Colors.teal,
          ),
          UnlockedItem.guardian(
            guardianId: 'pututu',
            name: 'Pututu',
            color: Colors.orange,
          ),
        ],
        onNext: () {},
        onRetry: () {},
        onExit: () {},
      ),
      const Duration(milliseconds: 4000),
    ),
    'derrota': (
      DefeatOverlay(
        potatoes: 0,
        maxPotatoes: 20,
        onRetry: () {},
        onExit: () {},
        onRevive: () {},
        revivePotatoes: 5,
      ),
      const Duration(seconds: 1),
    ),
  };

  /// Dibuja [overlay] durante [wait] y revisa que no haya respaldos.
  Future<void> drawScene(
    WidgetTester tester,
    String name,
    Widget overlay,
    Duration wait, {
    List<Override> overrides = const [],
  }) async {
    // Un teléfono apaisado de 873 × 393 dp.
    tester.view
      ..physicalSize = const Size(1746, 786)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final boundary = GlobalKey();

    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: RepaintBoundary(
            key: boundary,
            child: ColoredBox(
              // El pasto del mapa, de fondo.
              color: const Color(0xFF4F8A3C),
              child: SizedBox.expand(child: overlay),
            ),
          ),
        ),
        overrides: [riveFileProvider.overrideWithValue(file), ...overrides],
      ),
    );
    for (
      var t = Duration.zero;
      t < wait;
      t += const Duration(milliseconds: 50)
    ) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(tester.takeException(), isNull);
    // Los respaldos usan estos widgets; con Rive no hay ninguno.
    expect(find.byType(Card), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.textContaining('🦙'), findsNothing);
    expect(find.byIcon(Icons.warehouse_outlined), findsNothing);

    const prefix = String.fromEnvironment('SCENES_PNG');
    if (prefix.isNotEmpty) {
      await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await io.File('${prefix}_$name.png')
            .writeAsBytes(png!.buffer.asUint8List());
      });
    }

    await tester.pumpWidget(const SizedBox());
  }

  for (final MapEntry(key: name, value: (overlay, wait)) in scenes.entries) {
    testWidgets(
      '$name se dibuja con Rive, sin respaldos',
      (tester) => drawScene(tester, name, overlay, wait),
    );
  }

  // Andenes con el gorgojo ya visto: las demás llevan "Nueva" y el jefe su
  // cinta; las tarjetas terminan de entrar a los 0,8 s.
  testWidgets('preparacion se dibuja con Rive, sin respaldos', (tester) async {
    await drawScene(
      tester,
      'preparacion',
      const LevelPreviewScreen(levelId: 'andenes'),
      const Duration(milliseconds: 1500),
      overrides: [
        contentOverride(content()),
        adsServiceProvider.overrideWithValue(FakeAdsService()),
        savedGameProvider.overrideWithValue(
          const SaveData(progress: Progress(discoveredPests: {'gorgojo'})),
        ),
      ],
    );
  });

  // Cuatro plagas vistas (el gorgojo, la elegida), una recién descubierta
  // boca abajo y el resto sin descubrir.
  testWidgets('bestiario se dibuja con Rive, sin respaldos', (tester) async {
    await drawScene(
      tester,
      'bestiario',
      const BestiaryScreen(),
      const Duration(milliseconds: 1000),
      overrides: [
        contentOverride(content()),
        savedGameProvider.overrideWithValue(
          const SaveData(
            progress: Progress(
              discoveredPests: {
                'gorgojo',
                'polilla',
                'langosta',
                'escarabajo',
                'granizo',
              },
              seenPests: {'gorgojo', 'polilla', 'langosta', 'escarabajo'},
              discoveredGuardians: {'hondero', 'llama'},
              seenGuardians: {'hondero', 'llama'},
            ),
          ),
        ),
      ],
    );
  });

  testWidgets('ajustes se dibuja con Rive, sin respaldos', (tester) async {
    await drawScene(
      tester,
      'ajustes',
      const SettingsScreen(),
      const Duration(milliseconds: 1000),
      overrides: [
        // Con las opciones de privacidad (donde la ley las pide).
        adsServiceProvider.overrideWithValue(
          FakeAdsService()
            ..status.value = const AdsStatus(privacyOptionsRequired: true),
        ),
      ],
    );
  });

  // El primero ganado con 2 estrellas: Andenes sugerido y el lago cerrado.
  testWidgets('valle se dibuja con Rive, sin respaldos', (tester) async {
    await drawScene(
      tester,
      'valle',
      const LevelSelectScreen(),
      const Duration(milliseconds: 1500),
      overrides: [
        contentOverride(content()),
        savedGameProvider.overrideWithValue(
          const SaveData(
            progress: Progress(
              stars: {'chacra_del_valle': 2},
              unlockedLevels: {'chacra_del_valle', 'andenes'},
            ),
          ),
        ),
      ],
    );
  });
}
