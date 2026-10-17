import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/features/content/data/asset_source.dart';
import 'package:guardianes_chacra/features/content/data/bundle_asset_source.dart';
import 'package:guardianes_chacra/features/content/data/content_loader.dart';
import 'package:guardianes_chacra/features/content/domain/game_content.dart';

/// De dónde se lee el contenido: los assets empaquetados en la app.
final assetSourceProvider = Provider<AssetSource>(
  (ref) => BundleAssetSource(rootBundle),
);

/// El contenido completo del juego, cargado y validado una sola vez.
///
/// Sin reintentos: un error de contenido (un JSON mal escrito) no se
/// arregla solo, y Riverpod 3 reintenta las excepciones por defecto.
final gameContentProvider = FutureProvider<GameContent>(
  (ref) => ContentLoader(ref.watch(assetSourceProvider)).load(),
  retry: (_, _) => null,
);
