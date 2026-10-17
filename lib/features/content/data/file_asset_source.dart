import 'dart:io';

import 'package:guardianes_chacra/features/content/data/asset_source.dart';
import 'package:guardianes_chacra/features/content/data/json_reader.dart';

/// Lee el contenido desde el disco: para los tests y las herramientas de
/// línea de comandos (como el simulador de balance de la Fase 9).
///
/// Usa `dart:io`, que no existe en la web: la app no debe importarla.
class FileAssetSource implements AssetSource {
  new({this.root = '.'});

  /// Carpeta desde la que se resuelven las rutas (la raíz del proyecto).
  final String root;

  @override
  Future<String> readText(String path) async {
    final file = File('$root/$path');
    if (!file.existsSync()) {
      throw ContentError('No se encontró el archivo "$path"');
    }
    return await file.readAsString();
  }
}
