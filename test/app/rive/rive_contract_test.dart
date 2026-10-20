import 'dart:io' as io;

import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/app/rive/rive_counter.dart';
import 'package:guardianes_chacra/app/rive/rive_icons.dart';
import 'package:guardianes_chacra/app/rive/rive_ui.dart';
import 'package:rive/rive.dart' as rive;

/// Revisa el archivo real de Rive: que tenga cada artboard, state machine,
/// view model y propiedad que el código busca por nombre (el contrato de
/// `docs/UI_RIVE.md`). Si alguien renombra algo en el editor, este test lo
/// dice antes de abrir el juego.
///
/// Usa las librerías nativas de rive_native: en una PC nueva, antes de
/// `flutter test`, correr `dart run tool/setup_rive_native.dart` (el CI
/// también lo corre).
void main() {
  late rive.File file;

  setUpAll(() async {
    final bytes = await io.File(RiveUi.asset).readAsBytes();
    file = (await rive.File.decode(bytes, riveFactory: rive.Factory.flutter))!;
  });

  tearDownAll(() => file.dispose());

  /// El artboard existe, tiene la state machine `Main` y su view model
  /// tiene exactamente estas propiedades (nombre → tipo).
  void expectArtboard(
    String artboardName, {
    required String viewModel,
    required Map<String, rive.DataType> properties,
  }) {
    final artboard = file.artboard(artboardName);
    expect(artboard, isNotNull, reason: 'falta el artboard $artboardName');
    expect(
      artboard!.stateMachine(RiveUi.stateMachine),
      isNotNull,
      reason: '$artboardName no tiene la state machine ${RiveUi.stateMachine}',
    );
    final model = file.defaultArtboardViewModel(artboard);
    expect(model?.name, viewModel, reason: 'view model de $artboardName');
    expect(
      {for (final property in model!.properties) property.name: property.type},
      properties,
      reason: 'propiedades de $viewModel',
    );
    artboard.dispose();
  }

  test('Counter: número y triggers para subir y bajar', () {
    expectArtboard(
      CounterRive.artboard,
      viewModel: CounterRive.viewModel,
      properties: {
        CounterRive.value: rive.DataType.string,
        CounterRive.gain: rive.DataType.trigger,
        CounterRive.loss: rive.DataType.trigger,
      },
    );
  });

  test('IconSet: un enum elige el ícono, en el orden de RiveIcon', () {
    expectArtboard(
      IconSetRive.artboard,
      viewModel: IconSetRive.viewModel,
      properties: {IconSetRive.icon: rive.DataType.enumType},
    );
    final icons = file.enums.where((e) => e.name == IconSetRive.enumName);
    expect(
      icons,
      hasLength(1),
      reason: 'falta el enum ${IconSetRive.enumName}',
    );
    // Cada ícono se elige por su posición: mismo orden, no solo los mismos.
    expect(icons.single.values, [
      for (final icon in RiveIcon.values) icon.name,
    ]);
  });

  test('TitleSign: el texto del cartel', () {
    expectArtboard(
      'TitleSign',
      viewModel: 'TitleSign',
      properties: {'title': rive.DataType.string},
    );
  });

  // Sin datos: solo tienen que existir con su state machine.
  for (final name in ['Panel', 'PortraitHondero']) {
    test('$name existe', () {
      final artboard = file.artboard(name);
      expect(artboard, isNotNull, reason: 'falta el artboard $name');
      expect(artboard!.stateMachine(RiveUi.stateMachine), isNotNull);
      artboard.dispose();
    });
  }

  // El botón todavía no se usa en el juego (llega en la Fase 3), pero ya
  // está en el archivo: se revisa desde ahora.
  test('Button: etiqueta, presionado y habilitado', () {
    expectArtboard(
      'Button',
      viewModel: 'Button',
      properties: {
        'label': rive.DataType.string,
        'pressed': rive.DataType.boolean,
        'enabled': rive.DataType.boolean,
      },
    );
  });
}
