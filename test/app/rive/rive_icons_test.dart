import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/app/rive/rive_icons.dart';
import 'package:guardianes_chacra/app/rive/rive_ui.dart';
import 'package:rive/rive.dart' as rive;

/// Cada ícono del `IconSet` se ve cuando se lo elige. En Rive cada ícono es
/// un grupo cuya opacidad sale del enum con un convertidor: si falta uno o
/// quedó mal ligado, aquí se nota.
///
/// Usa las librerías nativas de rive_native (ver `rive_contract_test.dart`).
void main() {
  late rive.File file;

  setUpAll(() async {
    final bytes = await io.File(RiveUi.asset).readAsBytes();
    file = (await rive.File.decode(bytes, riveFactory: rive.Factory.flutter))!;
  });

  tearDownAll(() => file.dispose());

  /// Cuántos píxeles dibuja el `IconSet` con `icon` = [value].
  Future<int> paintedPixels(WidgetTester tester, String value) async {
    final controller = rive.RiveWidgetController(
      file,
      artboardSelector: rive.ArtboardSelector.byName(IconSetRive.artboard),
      stateMachineSelector: rive.StateMachineSelector.byName(
        RiveUi.stateMachine,
      ),
    );
    final viewModel = controller.dataBind(rive.DataBind.auto());
    viewModel.enumerator(IconSetRive.icon)!.value = value;
    final boundary = GlobalKey();
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          key: boundary,
          child: SizedBox.square(
            dimension: 48,
            child: rive.RiveWidget(controller: controller),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    final count = await tester.runAsync(() async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage();
      final bytes = (await image.toByteData())!;
      var painted = 0;
      for (var i = 3; i < bytes.lengthInBytes; i += 4) {
        if (bytes.getUint8(i) > 128) painted++;
      }
      return painted;
    });
    viewModel.dispose();
    controller.dispose();
    return count!;
  }

  testWidgets('cada ícono dibuja algo', (tester) async {
    for (final icon in RiveIcon.values) {
      expect(
        await paintedPixels(tester, icon.name),
        greaterThan(80),
        reason: icon.name,
      );
    }
  });

  // Rive no acepta un valor que no está en el enum: deja el que tenía (el
  // primero, el maíz). Por eso un ícono nuevo hay que agregarlo también en
  // el editor antes de usarlo.
  testWidgets('un valor que no existe deja el primero', (tester) async {
    expect(
      await paintedPixels(tester, 'noExiste'),
      await paintedPixels(tester, RiveIcon.values.first.name),
    );
  });
}
