import 'dart:io' as io;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/app/rive/rive_banner.dart';
import 'package:guardianes_chacra/app/rive/rive_branch_card.dart';
import 'package:guardianes_chacra/app/rive/rive_build_option.dart';
import 'package:guardianes_chacra/app/rive/rive_button.dart';
import 'package:guardianes_chacra/app/rive/rive_counter.dart';
import 'package:guardianes_chacra/app/rive/rive_guardian_info.dart';
import 'package:guardianes_chacra/app/rive/rive_icons.dart';
import 'package:guardianes_chacra/app/rive/rive_next_wave.dart';
import 'package:guardianes_chacra/app/rive/rive_portrait.dart';
import 'package:guardianes_chacra/app/rive/rive_speed_button.dart';
import 'package:guardianes_chacra/app/rive/rive_title_sign.dart';
import 'package:guardianes_chacra/app/rive/rive_tooltip.dart';
import 'package:guardianes_chacra/app/rive/rive_ui.dart';
import 'package:rive/rive.dart' as rive;

import '../../helpers/test_app.dart';

/// Dibuja con el archivo real las piezas de batalla de la Fase 4 (HUD,
/// menú de construcción, ficha y especialización): si a un artboard le
/// falta algo que el envoltorio busca, ese envoltorio cae a su respaldo de
/// Flutter y este test lo nota.
///
/// Para ver la imagen:
/// `flutter test test/app/rive/rive_battle_ui_test.dart
/// --dart-define=BATTLE_UI_PNG=build/battle_ui.png`.
///
/// Usa las librerías nativas de rive_native (ver `rive_contract_test.dart`).
void main() {
  testWidgets('las piezas de batalla se dibujan con Rive, sin respaldos', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1400, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late rive.File file;
    await tester.runAsync(() async {
      final bytes = await io.File(RiveUi.asset).readAsBytes();
      file = (await rive.File.decode(
        bytes,
        riveFactory: rive.Factory.flutter,
      ))!;
    });
    final boundary = GlobalKey();
    const stats = [
      GuardianStat(
        icon: RiveIcon.damage,
        label: 'Daño',
        current: '8',
        next: '12',
      ),
      GuardianStat(
        icon: RiveIcon.target,
        label: 'Alcance',
        current: '2,5',
        next: '2,8',
      ),
    ];

    Widget scene(int banners) => RepaintBoundary(
      key: boundary,
      child: ColoredBox(
        color: const Color(0xFF3E7D3A),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final id in PortraitRive.ids)
                RivePortrait(
                  guardianId: id,
                  name: id,
                  color: Colors.brown,
                  size: 64,
                ),
              RiveSpeedButton(
                fast: false,
                semanticsLabel: 'x1',
                onPressed: () {},
              ),
              RiveSpeedButton(
                fast: true,
                semanticsLabel: 'x2',
                onPressed: () {},
              ),
              const RiveCounter(
                value: 3,
                max: 10,
                icon: RiveIcon.potato,
                danger: true,
                semanticsLabel: 'papas',
                fallback: Text('respaldo'),
              ),
              RiveNextWaveButton(
                seconds: 8,
                totalSeconds: 15,
                bonusLabel: '+12',
                semanticsLabel: 'siguiente',
                onPressed: () {},
              ),
              RiveButton.round(
                label: 'Pausa',
                icon: RiveIcon.pause,
                onPressed: () {},
              ),
              RiveButton(
                label: 'Vender +42',
                icon: RiveIcon.sell,
                kind: RiveButtonKind.secondary,
                danger: true,
                onPressed: () {},
              ),
              const RiveTooltip(
                text: 'Hondero · tierra y aire\nToca otra vez para confirmar',
                visible: true,
                arrow: false,
                maxWidth: 360,
              ),
              for (final (selected, affordable, locked) in [
                (false, true, false),
                (true, true, false),
                (false, false, false),
                (false, true, true),
              ])
                RiveBuildOption(
                  guardianId: 'llama',
                  name: 'Llama',
                  cost: 80,
                  color: Colors.teal,
                  semanticsLabel: 'Llama',
                  selected: selected,
                  affordable: affordable,
                  locked: locked,
                  onTap: () {},
                  onDenied: () {},
                ),
              const RiveGuardianInfo(
                guardianId: 'tullpa',
                title: 'Tullpa · Nivel 2',
                attacks: 'Ataca: plagas de tierra',
                attackIcon: RiveIcon.ground,
                stats: stats,
                color: Colors.red,
                nextWord: 'luego',
              ),
              RiveBranchCard(
                guardianId: 'condor',
                name: 'Vuelo rasante',
                description: 'Se lanza en picada sobre los voladores.',
                cost: 150,
                color: const Color(0xFF37474F),
                selected: true,
                onTap: () {},
                onDenied: () {},
              ),
              RiveBranchCard(
                guardianId: 'pututu',
                name: 'Toque de guerra',
                description: 'Menos alcance, mucho más brío.',
                cost: 140,
                color: const Color(0xFF7B1FA2),
                affordable: false,
                onTap: () {},
                onDenied: () {},
              ),
              const RiveTitleSign(title: 'Elige una especialización'),
              RiveWaveBanner(
                title: 'Oleada 10',
                subtitle: '¡Llega el jefe!',
                boss: true,
                showCount: banners,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      testApp(
        Scaffold(body: scene(0)),
        overrides: [riveFileProvider.overrideWithValue(file)],
      ),
    );
    await tester.pumpWidget(
      testApp(
        Scaffold(body: scene(1)),
        overrides: [riveFileProvider.overrideWithValue(file)],
      ),
    );
    // Las entradas terminan (tarjetas que giran, el cartel que cae).
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(tester.takeException(), isNull);
    // Los respaldos usan estos widgets; con Rive no hay ninguno.
    expect(find.byType(CircleAvatar), findsNothing);
    expect(find.byType(Card), findsNothing);
    expect(find.text('respaldo'), findsNothing);
    expect(find.byType(IconButton), findsNothing);

    const path = String.fromEnvironment('BATTLE_UI_PNG');
    if (path.isNotEmpty) {
      await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage();
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await io.File(path).writeAsBytes(png!.buffer.asUint8List());
      });
    }

    await tester.pumpWidget(const SizedBox());
    file.dispose();
  });
}
