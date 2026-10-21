import 'dart:io' as io;

import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/app/rive/rive_badge.dart';
import 'package:guardianes_chacra/app/rive/rive_banner.dart';
import 'package:guardianes_chacra/app/rive/rive_bestiary_grid.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';
import 'package:guardianes_chacra/app/rive/rive_branch_card.dart';
import 'package:guardianes_chacra/app/rive/rive_build_option.dart';
import 'package:guardianes_chacra/app/rive/rive_button.dart';
import 'package:guardianes_chacra/app/rive/rive_collca.dart';
import 'package:guardianes_chacra/app/rive/rive_corn_rain.dart';
import 'package:guardianes_chacra/app/rive/rive_counter.dart';
import 'package:guardianes_chacra/app/rive/rive_guardian_info.dart';
import 'package:guardianes_chacra/app/rive/rive_icons.dart';
import 'package:guardianes_chacra/app/rive/rive_level_node.dart';
import 'package:guardianes_chacra/app/rive/rive_level_scene.dart';
import 'package:guardianes_chacra/app/rive/rive_llama.dart';
import 'package:guardianes_chacra/app/rive/rive_logo.dart';
import 'package:guardianes_chacra/app/rive/rive_mascots.dart';
import 'package:guardianes_chacra/app/rive/rive_next_wave.dart';
import 'package:guardianes_chacra/app/rive/rive_panel.dart';
import 'package:guardianes_chacra/app/rive/rive_pest_card.dart';
import 'package:guardianes_chacra/app/rive/rive_portrait.dart';
import 'package:guardianes_chacra/app/rive/rive_scene_sign.dart';
import 'package:guardianes_chacra/app/rive/rive_segmented.dart';
import 'package:guardianes_chacra/app/rive/rive_speed_button.dart';
import 'package:guardianes_chacra/app/rive/rive_star.dart';
import 'package:guardianes_chacra/app/rive/rive_stat_pill.dart';
import 'package:guardianes_chacra/app/rive/rive_tab.dart';
import 'package:guardianes_chacra/app/rive/rive_title_sign.dart';
import 'package:guardianes_chacra/app/rive/rive_toggle.dart';
import 'package:guardianes_chacra/app/rive/rive_tooltip.dart';
import 'package:guardianes_chacra/app/rive/rive_ui.dart';
import 'package:guardianes_chacra/app/rive/rive_unlock_card.dart';
import 'package:guardianes_chacra/app/rive/rive_valley.dart';
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
      TitleSignRive.artboard,
      viewModel: TitleSignRive.viewModel,
      properties: {TitleSignRive.title: rive.DataType.string},
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
        TooltipRive.arrow: rive.DataType.boolean,
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

  test('Portrait: un enum elige el guardián, el primero es el respaldo', () {
    expectArtboard(
      PortraitRive.artboard,
      viewModel: PortraitRive.viewModel,
      properties: {PortraitRive.guardian: rive.DataType.enumType},
    );
    final ids = file.enums.where((e) => e.name == PortraitRive.enumName);
    expect(ids, hasLength(1), reason: 'falta el enum ${PortraitRive.enumName}');
    expect(ids.single.values, PortraitRive.ids);
  });

  test('SpeedButton: x1/x2, presionado y velocidad', () {
    expectArtboard(
      SpeedButtonRive.artboard,
      viewModel: SpeedButtonRive.viewModel,
      properties: {
        SpeedButtonRive.label: rive.DataType.string,
        SpeedButtonRive.fast: rive.DataType.boolean,
        SpeedButtonRive.pressed: rive.DataType.boolean,
        SpeedButtonRive.enabled: rive.DataType.boolean,
        SpeedButtonRive.deny: rive.DataType.trigger,
        ...reduceMotion,
      },
    );
  });

  test('NextWave: segundos, bono, anillo y llamada', () {
    expectArtboard(
      NextWaveRive.artboard,
      viewModel: NextWaveRive.viewModel,
      properties: {
        NextWaveRive.label: rive.DataType.string,
        NextWaveRive.bonus: rive.DataType.string,
        NextWaveRive.progress: rive.DataType.number,
        NextWaveRive.pressed: rive.DataType.boolean,
        NextWaveRive.called: rive.DataType.trigger,
        NextWaveRive.icon: rive.DataType.viewModel,
        NextWaveRive.enabled: rive.DataType.boolean,
        NextWaveRive.deny: rive.DataType.trigger,
        ...reduceMotion,
      },
    );
  });

  test('Banner: título, aviso del jefe y "mostrar"', () {
    expectArtboard(
      BannerRive.artboard,
      viewModel: BannerRive.viewModel,
      properties: {
        BannerRive.title: rive.DataType.string,
        BannerRive.subtitle: rive.DataType.string,
        BannerRive.boss: rive.DataType.boolean,
        BannerRive.show: rive.DataType.trigger,
        ...reduceMotion,
      },
    );
  });

  test('BuildOption: retrato, nombre, costo y sus estados', () {
    expectArtboard(
      BuildOptionRive.artboard,
      viewModel: BuildOptionRive.viewModel,
      properties: {
        BuildOptionRive.name: rive.DataType.string,
        BuildOptionRive.cost: rive.DataType.string,
        BuildOptionRive.portrait: rive.DataType.viewModel,
        BuildOptionRive.selected: rive.DataType.boolean,
        BuildOptionRive.affordable: rive.DataType.boolean,
        BuildOptionRive.locked: rive.DataType.boolean,
        BuildOptionRive.confirm: rive.DataType.trigger,
        BuildOptionRive.deny: rive.DataType.trigger,
        ...reduceMotion,
      },
    );
  });

  test('GuardianInfo: título, ataque, retrato y dos estadísticas', () {
    expectArtboard(
      GuardianInfoRive.artboard,
      viewModel: GuardianInfoRive.viewModel,
      properties: {
        GuardianInfoRive.title: rive.DataType.string,
        GuardianInfoRive.attacks: rive.DataType.string,
        GuardianInfoRive.attackIcon: rive.DataType.viewModel,
        GuardianInfoRive.portrait: rive.DataType.viewModel,
        for (var row = 1; row <= GuardianInfoRive.rows; row++) ...{
          GuardianInfoRive.statLabel(row): rive.DataType.string,
          GuardianInfoRive.statCurrent(row): rive.DataType.string,
          GuardianInfoRive.statNext(row): rive.DataType.string,
          GuardianInfoRive.statIcon(row): rive.DataType.viewModel,
        },
        GuardianInfoRive.hasNext: rive.DataType.boolean,
        ...reduceMotion,
      },
    );
  });

  test('BranchCard: rama, color, retrato, costo y estallido', () {
    expectArtboard(
      BranchCardRive.artboard,
      viewModel: BranchCardRive.viewModel,
      properties: {
        BranchCardRive.name: rive.DataType.string,
        BranchCardRive.description: rive.DataType.string,
        BranchCardRive.cost: rive.DataType.string,
        BranchCardRive.color: rive.DataType.color,
        BranchCardRive.portrait: rive.DataType.viewModel,
        BranchCardRive.selected: rive.DataType.boolean,
        BranchCardRive.affordable: rive.DataType.boolean,
        BranchCardRive.enter: rive.DataType.trigger,
        BranchCardRive.choose: rive.DataType.trigger,
        ...reduceMotion,
      },
    );
  });

  test('SceneSign: título y adorno (pausa, victoria o derrota)', () {
    expectArtboard(
      SceneSignRive.artboard,
      viewModel: SceneSignRive.viewModel,
      properties: {
        SceneSignRive.title: rive.DataType.string,
        SceneSignRive.variant: rive.DataType.enumType,
        ...reduceMotion,
      },
    );
    final variants = file.enums.where((e) => e.name == SceneSignRive.enumName);
    expect(variants, hasLength(1));
    expect(variants.single.values, [
      for (final variant in SceneSignVariant.values) variant.name,
    ]);
  });

  test('Llama: cara feliz o triste y salto de festejo', () {
    expectArtboard(
      LlamaRive.artboard,
      viewModel: LlamaRive.viewModel,
      properties: {
        LlamaRive.mood: rive.DataType.enumType,
        LlamaRive.celebrate: rive.DataType.trigger,
        LlamaRive.chewing: rive.DataType.boolean,
        ...reduceMotion,
      },
    );
    final moods = file.enums.where((e) => e.name == LlamaRive.enumName);
    expect(moods, hasLength(1));
    expect(moods.single.values, [
      for (final mood in LlamaMood.values) mood.name,
    ]);
  });

  test('StatPill: ícono, etiqueta, número y "pop"', () {
    expectArtboard(
      StatPillRive.artboard,
      viewModel: StatPillRive.viewModel,
      properties: {
        StatPillRive.label: rive.DataType.string,
        StatPillRive.value: rive.DataType.string,
        StatPillRive.icon: rive.DataType.viewModel,
        StatPillRive.pop: rive.DataType.trigger,
        ...reduceMotion,
      },
    );
  });

  test('UnlockCard: retrato o escena del nivel, nombre y entrada', () {
    expectArtboard(
      UnlockCardRive.artboard,
      viewModel: UnlockCardRive.viewModel,
      properties: {
        UnlockCardRive.label: rive.DataType.string,
        UnlockCardRive.name: rive.DataType.string,
        UnlockCardRive.portrait: rive.DataType.viewModel,
        UnlockCardRive.scene: rive.DataType.viewModel,
        UnlockCardRive.isLevel: rive.DataType.boolean,
        UnlockCardRive.enter: rive.DataType.trigger,
        ...reduceMotion,
      },
    );
  });

  test('CornRain: la lluvia de maíz', () {
    expectArtboard(
      CornRainRive.artboard,
      viewModel: CornRainRive.viewModel,
      properties: {CornRainRive.rain: rive.DataType.trigger, ...reduceMotion},
    );
  });

  test('Collca: llena o vacía', () {
    expectArtboard(
      CollcaRive.artboard,
      viewModel: CollcaRive.viewModel,
      properties: {CollcaRive.full: rive.DataType.boolean, ...reduceMotion},
    );
  });

  test('Valley: el paisaje, con su collca anidada', () {
    expectArtboard(
      ValleyRive.artboard,
      viewModel: ValleyRive.viewModel,
      properties: {ValleyRive.collca: rive.DataType.viewModel, ...reduceMotion},
    );
  });

  test('LevelNode: número, nombre, estrellas, estado y sus dos triggers', () {
    expectArtboard(
      LevelNodeRive.artboard,
      viewModel: LevelNodeRive.viewModel,
      properties: {
        LevelNodeRive.number: rive.DataType.string,
        LevelNodeRive.name: rive.DataType.string,
        LevelNodeRive.stars: rive.DataType.number,
        LevelNodeRive.state: rive.DataType.enumType,
        LevelNodeRive.shake: rive.DataType.trigger,
        LevelNodeRive.unlock: rive.DataType.trigger,
        ...reduceMotion,
      },
    );
    final states = file.enums.where((e) => e.name == LevelNodeRive.enumName);
    expect(states, hasLength(1));
    expect(states.single.values, [
      for (final state in LevelNodeState.values) state.name,
    ]);
  });

  test('LevelScene: el valle encuadrado en cada nivel, con su collca', () {
    expectArtboard(
      LevelSceneRive.artboard,
      viewModel: LevelSceneRive.viewModel,
      properties: {
        LevelSceneRive.level: rive.DataType.enumType,
        LevelSceneRive.collca: rive.DataType.viewModel,
      },
    );
    final ids = file.enums.where((e) => e.name == LevelSceneRive.enumName);
    expect(ids, hasLength(1));
    expect(ids.single.values, containsAll(LevelSceneRive.levels.values));
  });

  test('PestPortrait: un enum elige la plaga, en el orden de los ids', () {
    expectArtboard(
      PestPortraitRive.artboard,
      viewModel: PestPortraitRive.viewModel,
      properties: {PestPortraitRive.pest: rive.DataType.enumType},
    );
    final ids = file.enums.where((e) => e.name == PestPortraitRive.enumName);
    expect(ids, hasLength(1));
    expect(ids.single.values, PestPortraitRive.ids);
  });

  test('PestCard: nombre, insignias, color, retrato y entrada', () {
    expectArtboard(
      PestCardRive.artboard,
      viewModel: PestCardRive.viewModel,
      properties: {
        PestCardRive.name: rive.DataType.string,
        PestCardRive.isNew: rive.DataType.boolean,
        PestCardRive.newLabel: rive.DataType.string,
        PestCardRive.boss: rive.DataType.boolean,
        PestCardRive.bossLabel: rive.DataType.string,
        PestCardRive.color: rive.DataType.color,
        PestCardRive.portrait: rive.DataType.viewModel,
        PestCardRive.enter: rive.DataType.trigger,
        ...reduceMotion,
      },
    );
  });

  test('BestiaryGrid: la lista del Component List', () {
    expectArtboard(
      BestiaryGridRive.artboard,
      viewModel: BestiaryGridRive.viewModel,
      properties: {BestiaryGridRive.entries: rive.DataType.list},
    );
  });

  test('BestiaryEntry: nombre, color, retratos, marco, "¡Nuevo!" y vuelta', () {
    expectArtboard(
      BestiaryGridRive.entryArtboard,
      viewModel: BestiaryGridRive.entryViewModel,
      properties: {
        BestiaryGridRive.name: rive.DataType.string,
        BestiaryGridRive.color: rive.DataType.color,
        BestiaryGridRive.isGuardian: rive.DataType.boolean,
        BestiaryGridRive.pest: rive.DataType.viewModel,
        BestiaryGridRive.guardian: rive.DataType.viewModel,
        BestiaryGridRive.selected: rive.DataType.boolean,
        BestiaryGridRive.isNew: rive.DataType.boolean,
        BestiaryGridRive.newLabel: rive.DataType.string,
        BestiaryGridRive.faceDown: rive.DataType.boolean,
        BestiaryGridRive.reveal: rive.DataType.trigger,
        ...reduceMotion,
      },
    );
  });

  test('Logo: tres líneas del nombre y el lema', () {
    expectArtboard(
      LogoRive.artboard,
      viewModel: LogoRive.viewModel,
      properties: {
        LogoRive.line1: rive.DataType.string,
        LogoRive.line2: rive.DataType.string,
        LogoRive.line3: rive.DataType.string,
        LogoRive.tagline: rive.DataType.string,
        ...reduceMotion,
      },
    );
  });

  for (final (artboard, viewModel) in [
    (MascotsRive.hondero, 'Hondero'),
    (MascotsRive.gorgojoPeek, 'GorgojoPeek'),
  ]) {
    test('$artboard: solo menos movimiento', () {
      expectArtboard(artboard, viewModel: viewModel, properties: reduceMotion);
    });
  }

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
