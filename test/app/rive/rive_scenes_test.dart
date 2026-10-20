import 'dart:io' as io;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/app/rive/rive_ui.dart';
import 'package:guardianes_chacra/features/battle/presentation/overlays/battle_overlays.dart';
import 'package:rive/rive.dart' as rive;

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
          UnlockedItem.level(name: 'Andenes', color: Colors.teal),
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

  for (final MapEntry(key: name, value: (overlay, wait)) in scenes.entries) {
    testWidgets('$name se dibuja con Rive, sin respaldos', (tester) async {
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
          overrides: [riveFileProvider.overrideWithValue(file)],
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
    });
  }
}
