import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/ads.dart';
import 'package:guardianes_chacra/app/analytics.dart';
import 'package:guardianes_chacra/app/app.dart';
import 'package:guardianes_chacra/app/audio.dart';
import 'package:guardianes_chacra/app/haptics.dart';
import 'package:guardianes_chacra/app/rive/rive_ui.dart';
import 'package:guardianes_chacra/core/services/ad_unit_ids.dart';
import 'package:guardianes_chacra/core/services/ads_service.dart';
import 'package:guardianes_chacra/core/services/analytics_service.dart';
import 'package:guardianes_chacra/core/services/flame_audio_service.dart';
import 'package:guardianes_chacra/core/services/google_ads_service.dart';
import 'package:guardianes_chacra/core/services/system_haptics_service.dart';
import 'package:guardianes_chacra/features/progress/data/local_progress_repository.dart';
import 'package:guardianes_chacra/features/progress/presentation/save_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Las fuentes (OFL) piden viajar con su licencia: aparecen en la
  // pantalla de licencias junto a las de los paquetes.
  LicenseRegistry.addLicense(() async* {
    for (final (font, file) in [
      ('Lilita One', 'LilitaOne-OFL.txt'),
      ('Fredoka', 'Fredoka-OFL.txt'),
    ]) {
      yield LicenseEntryWithLineBreaks([
        font,
      ], await rootBundle.loadString('assets/fonts/$file'));
    }
  });

  // Juego horizontal: se puede girar el teléfono entre las dos posiciones
  // horizontales, nunca a vertical. AndroidManifest.xml pide lo mismo para
  // que la app arranque ya en horizontal. En la web no tiene efecto.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Pantalla completa: las barras del sistema se ocultan y reaparecen un
  // momento al deslizar desde el borde, sin sacar al jugador del juego.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // El guardado se lee antes de mostrar nada (es un texto pequeño): así el
  // idioma, las estrellas y los desbloqueos están listos desde el primer
  // cuadro, sin pantallas de carga.
  final repository = LocalProgressRepository(SharedPreferencesAsync());
  final saved = await repository.load();

  // La interfaz de Rive (16 KB) también se carga antes del primer cuadro.
  // Si falla, cada pantalla usa su aspecto de Flutter.
  final riveFile = await RiveUi.load();

  // Anuncios: los de prueba fuera de release; en release, solo si se
  // compiló con los IDs reales (ver docs/MONETIZACION.md).
  final adUnits = AdUnitIds.forThisBuild();
  final ads = adUnits == null
      ? NoAdsService()
      : GoogleAdsService(
          ids: adUnits,
          consentDebug: GoogleAdsService.consentDebugFromEnvironment(),
        );

  runApp(
    ProviderScope(
      overrides: [
        progressRepositoryProvider.overrideWithValue(repository),
        savedGameProvider.overrideWithValue(saved),
        audioServiceProvider.overrideWithValue(FlameAudioService()),
        hapticsServiceProvider.overrideWithValue(SystemHapticsService()),
        adsServiceProvider.overrideWithValue(ads),
        riveFileProvider.overrideWithValue(riveFile),
        // Hasta conectar Firebase (Fase 11), los eventos solo se ven en la
        // consola.
        analyticsServiceProvider.overrideWithValue(
          kReleaseMode ? NoAnalyticsService() : DebugAnalyticsService(),
        ),
      ],
      child: const GuardianesApp(),
    ),
  );

  // Con la app ya en pantalla: el formulario de consentimiento (donde la ley
  // lo exige) necesita una pantalla sobre la que mostrarse.
  unawaited(ads.initialize());
}
