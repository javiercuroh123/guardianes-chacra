import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/app.dart';
import 'package:guardianes_chacra/features/progress/data/local_progress_repository.dart';
import 'package:guardianes_chacra/features/progress/presentation/save_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(
    ProviderScope(
      overrides: [
        progressRepositoryProvider.overrideWithValue(repository),
        savedGameProvider.overrideWithValue(saved),
      ],
      child: const GuardianesApp(),
    ),
  );
}
