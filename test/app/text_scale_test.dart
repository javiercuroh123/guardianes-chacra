import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/app/ads.dart';
import 'package:guardianes_chacra/app/text_scale.dart';
import 'package:guardianes_chacra/features/battle/presentation/overlays/battle_overlays.dart';
import 'package:guardianes_chacra/features/bestiary/presentation/bestiary_screen.dart';
import 'package:guardianes_chacra/features/level_select/presentation/level_preview_screen.dart';
import 'package:guardianes_chacra/features/level_select/presentation/level_select_screen.dart';
import 'package:guardianes_chacra/features/menu/presentation/title_screen.dart';
import 'package:guardianes_chacra/features/progress/domain/progress.dart';
import 'package:guardianes_chacra/features/progress/domain/progress_repository.dart';
import 'package:guardianes_chacra/features/progress/presentation/save_providers.dart';
import 'package:guardianes_chacra/features/settings/presentation/settings_screen.dart';

import '../helpers/battle_game_helpers.dart';
import '../helpers/fake_ads_service.dart';
import '../helpers/real_content.dart';
import '../helpers/test_app.dart';

/// Con la letra grande del teléfono, ninguna pantalla debe desbordarse
/// (Flutter avisa cada desborde como un error, que hace fallar el test).
void main() {
  final content = useRealContent();

  /// El teléfono con su letra a [scale] veces el tamaño normal.
  void useTextScale(WidgetTester tester, double scale) {
    usePhoneLandscape(tester);
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  // Con todo descubierto y desbloqueado, cada pantalla muestra lo máximo.
  Progress everything() => Progress(
    stars: {for (final level in content().levels) level.id: 3},
    discoveredPests: content().pests.keys.toSet(),
    discoveredGuardians: content().guardians.keys.toSet(),
    unlockedLevels: {for (final level in content().levels) level.id},
    unlockedGuardians: content().guardians.keys.toSet(),
  );

  Future<void> pump(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(
      testApp(
        screen,
        overrides: [
          contentOverride(content()),
          // Con un anuncio cargado: así aparecen también sus botones.
          adsServiceProvider.overrideWithValue(FakeAdsService()),
          savedGameProvider.overrideWithValue(SaveData(progress: everything())),
        ],
      ),
    );
    await tester.pump();
  }

  testWidgets('la letra de la app crece hasta el doble, no más', (
    tester,
  ) async {
    useTextScale(tester, 3);
    await pump(tester, const TitleScreen());

    final context = tester.element(find.byType(TitleScreen));
    expect(
      MediaQuery.textScalerOf(context).scale(10),
      10 * TextScaleLimits.menus,
    );
  });

  for (final scale in [1.3, 2.0]) {
    group('con la letra a ×$scale', () {
      final screens = <String, Widget Function()>{
        'título': () => const TitleScreen(),
        'valle': () => const LevelSelectScreen(),
        'bestiario': () => const BestiaryScreen(),
        'ajustes': () => const SettingsScreen(),
        for (final level in ['chacra_del_valle', 'andenes', 'orilla_del_lago'])
          'vista previa de $level': () => LevelPreviewScreen(levelId: level),
        // Los overlays de la partida van sobre el juego, dentro de su
        // Scaffold.
        'pausa': () => Scaffold(
          body: PauseOverlay(onResume: () {}, onRetry: () {}, onExit: () {}),
        ),
        'victoria': () => Scaffold(
          body: VictoryOverlay(
            stars: 3,
            potatoes: 20,
            cornHarvested: 1234,
            unlocked: const ['Orilla del Lago', 'Cóndor'],
            onNext: () {},
            onRetry: () {},
            onExit: () {},
          ),
        ),
        'derrota': () => Scaffold(
          body: DefeatOverlay(
            onRetry: () {},
            onExit: () {},
            onRevive: () {},
            revivePotatoes: 5,
          ),
        ),
      };

      for (final MapEntry(key: name, value: screen) in screens.entries) {
        testWidgets('$name no se desborda', (tester) async {
          useTextScale(tester, scale);
          await pump(tester, screen());

          expect(tester.takeException(), isNull);
        });
      }
    });
  }
}
