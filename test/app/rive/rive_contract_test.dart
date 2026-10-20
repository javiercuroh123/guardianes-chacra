import 'dart:io' as io;

import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/app/rive/rive_badge.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';
import 'package:guardianes_chacra/app/rive/rive_button.dart';
import 'package:guardianes_chacra/app/rive/rive_counter.dart';
import 'package:guardianes_chacra/app/rive/rive_icons.dart';
import 'package:guardianes_chacra/app/rive/rive_panel.dart';
import 'package:guardianes_chacra/app/rive/rive_segmented.dart';
import 'package:guardianes_chacra/app/rive/rive_star.dart';
import 'package:guardianes_chacra/app/rive/rive_tab.dart';
import 'package:guardianes_chacra/app/rive/rive_toggle.dart';
import 'package:guardianes_chacra/app/rive/rive_tooltip.dart';
import 'package:guardianes_chacra/app/rive/rive_ui.dart';
import 'package:guardianes_chacra/app/rive/rive_wave_bar.dart';
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

  const reduceMotion = {RiveBinding.reduceMotion: rive.DataType.boolean};

  test('Counter: número, ícono, "+N", peligro y triggers', () {
    expectArtboard(
      CounterRive.artboard,
      viewModel: CounterRive.viewModel,
      properties: {
        CounterRive.value: rive.DataType.string,
        CounterRive.gain: rive.DataType.trigger,
        CounterRive.loss: rive.DataType.trigger,
        CounterRive.icon: rive.DataType.viewModel,
        CounterRive.delta: rive.DataType.string,
        CounterRive.danger: rive.DataType.boolean,
        ...reduceMotion,
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

  // Los tres botones comparten el view model.
  for (final artboard in [
    ButtonRive.primary,
    ButtonRive.secondary,
    ButtonRive.round,
  ]) {
    test('$artboard: texto, ícono, presionado, habilitado y "no se puede"', () {
      expectArtboard(
        artboard,
        viewModel: ButtonRive.viewModel,
        properties: {
          ButtonRive.label: rive.DataType.string,
          ButtonRive.pressed: rive.DataType.boolean,
          ButtonRive.enabled: rive.DataType.boolean,
          ButtonRive.icon: rive.DataType.viewModel,
          ButtonRive.hasIcon: rive.DataType.boolean,
          ButtonRive.deny: rive.DataType.trigger,
          ButtonRive.danger: rive.DataType.boolean,
          ...reduceMotion,
        },
      );
    });
  }

  test('WaveBar: texto, avance, jefe e inicio de oleada', () {
    expectArtboard(
      WaveBarRive.artboard,
      viewModel: WaveBarRive.viewModel,
      properties: {
        WaveBarRive.label: rive.DataType.string,
        WaveBarRive.progress: rive.DataType.number,
        WaveBarRive.boss: rive.DataType.boolean,
        WaveBarRive.waveStarted: rive.DataType.trigger,
        WaveBarRive.icon: rive.DataType.viewModel,
        ...reduceMotion,
      },
    );
  });

  test('Star: llena o vacía', () {
    expectArtboard(
      StarRive.artboard,
      viewModel: StarRive.viewModel,
      properties: {StarRive.filled: rive.DataType.boolean, ...reduceMotion},
    );
  });

  test('Toggle: encendido y habilitado', () {
    expectArtboard(
      ToggleRive.artboard,
      viewModel: ToggleRive.viewModel,
      properties: {
        ToggleRive.on: rive.DataType.boolean,
        ToggleRive.enabled: rive.DataType.boolean,
        ...reduceMotion,
      },
    );
  });

  test('Segmented: tres textos y la opción elegida', () {
    expectArtboard(
      SegmentedRive.artboard,
      viewModel: SegmentedRive.viewModel,
      properties: {
        for (var i = 0; i < SegmentedRive.options; i++)
          SegmentedRive.label(i): rive.DataType.string,
        SegmentedRive.selected: rive.DataType.number,
      },
    );
  });

  test('Tab: texto, elegida e ícono', () {
    expectArtboard(
      TabRive.artboard,
      viewModel: TabRive.viewModel,
      properties: {
        TabRive.label: rive.DataType.string,
        TabRive.selected: rive.DataType.boolean,
        TabRive.hasIcon: rive.DataType.boolean,
        TabRive.icon: rive.DataType.viewModel,
      },
    );
  });

  test('Tooltip: texto y visible', () {
    expectArtboard(
      TooltipRive.artboard,
      viewModel: TooltipRive.viewModel,
      properties: {
        TooltipRive.text: rive.DataType.string,
        TooltipRive.visible: rive.DataType.boolean,
        ...reduceMotion,
      },
    );
  });

  test('Badge: el texto', () {
    expectArtboard(
      BadgeRive.artboard,
      viewModel: BadgeRive.viewModel,
      properties: {BadgeRive.label: rive.DataType.string, ...reduceMotion},
    );
  });

  test('Panel: entra y sale', () {
    expectArtboard(
      PanelRive.artboard,
      viewModel: PanelRive.viewModel,
      properties: {PanelRive.visible: rive.DataType.boolean, ...reduceMotion},
    );
  });

  // Sin datos propios: solo tienen que existir con su state machine. El
  // Catalog muestra todos los componentes en todos sus estados (sus datos
  // están en el archivo) y lo dibuja `rive_catalog_test.dart`.
  for (final name in ['PortraitHondero', 'Catalog']) {
    test('$name existe', () {
      final artboard = file.artboard(name);
      expect(artboard, isNotNull, reason: 'falta el artboard $name');
      expect(artboard!.stateMachine(RiveUi.stateMachine), isNotNull);
      artboard.dispose();
    });
  }
}
