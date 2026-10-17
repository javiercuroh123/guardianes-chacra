import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:guardianes_chacra/features/content/data/asset_source.dart';
import 'package:guardianes_chacra/features/content/data/json_reader.dart';

/// Lee el contenido empaquetado en la app (los assets de `pubspec.yaml`).
/// Funciona en Android, iOS y web.
class BundleAssetSource implements AssetSource {
  new(this._bundle);

  final AssetBundle _bundle;

  @override
  Future<String> readText(String path) async {
    try {
      return await _bundle.loadString(path);
    }
    // Flutter avisa que un asset no está empaquetado con un FlutterError
    // (un Error, no una Exception): es la única forma de saberlo.
    // ignore: avoid_catching_errors
    on FlutterError {
      throw ContentError('No se encontró el archivo "$path"');
    }
  }
}
