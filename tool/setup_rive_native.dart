// Deja listas las librerías nativas de Rive para `flutter test` (el test de
// contrato carga el .riv real). Para compilar la app no hace falta: el
// build las descarga solo.
//
// Uso (desde la raíz del proyecto, una vez por PC o al subir rive):
//
//     dart run tool/setup_rive_native.dart
//
// En Windows, los tests buscan la DLL de depuración, que necesita el runtime
// de depuración de C++ (MSVCP140D.dll y compañía): solo viene con Visual
// Studio. Sin él, la DLL no carga ("error code 126"). Como la de lanzamiento
// funciona igual para los tests y su runtime ya está en Windows, se copia
// encima.

import 'dart:io';

Future<void> main() async {
  final platform = switch (Platform.operatingSystem) {
    'windows' => 'windows',
    'linux' => 'linux',
    'macos' => 'macos',
    final other => throw UnsupportedError('rive_native no corre en $other'),
  };

  final setup = await Process.start(
    'dart',
    ['run', 'rive_native:setup', '--clean', '--platform', platform],
    runInShell: true,
    mode: ProcessStartMode.inheritStdio,
  );
  final exitCode = await setup.exitCode;
  if (exitCode != 0) {
    stderr.writeln('rive_native:setup terminó con el código $exitCode');
    exit(exitCode);
  }

  if (Platform.isWindows) {
    const lib = 'build/rive_native/native/build/windows/bin/lib';
    File('$lib/release/rive_native.dll').copySync('$lib/debug/rive_native.dll');
    stdout.writeln('Copié la DLL de lanzamiento de Rive para los tests.');
  }
}
