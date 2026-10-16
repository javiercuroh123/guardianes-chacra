import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Protege la regla 1 de la arquitectura: todo lo que vive en una carpeta
/// `domain/` es Dart puro, para poder testearlo y ejecutar la simulación sin
/// gráficos (por ejemplo, en el simulador de balance).
void main() {
  const forbiddenPrefixes = [
    'dart:ui',
    'package:flutter/',
    'package:flutter_',
    'package:flame',
    'package:riverpod',
  ];
  final directive = RegExp(
    r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
    multiLine: true,
  );

  final domainFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => file.uri.pathSegments.contains('domain'))
      .toList();

  List<String> importsOf(File file) => directive
      .allMatches(file.readAsStringSync())
      .map((match) => match.group(1)!)
      .toList();

  test('hay archivos de domain que revisar', () {
    expect(domainFiles, isNotEmpty);
  });

  test('domain no importa Flutter, Flame ni Riverpod', () {
    final violations = [
      for (final file in domainFiles)
        for (final uri in importsOf(file))
          if (forbiddenPrefixes.any(uri.startsWith)) '${file.path} → $uri',
    ];

    expect(violations, isEmpty);
  });

  test('domain no depende de las capas data ni presentation', () {
    final violations = [
      for (final file in domainFiles)
        for (final uri in importsOf(file))
          if (uri.split('/').any(['data', 'presentation'].contains))
            '${file.path} → $uri',
    ];

    expect(violations, isEmpty);
  });
}
