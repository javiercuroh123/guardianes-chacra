import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/app.dart';

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

  runApp(const ProviderScope(child: GuardianesApp()));
}
