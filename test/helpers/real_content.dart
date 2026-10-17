import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/content/data/content_loader.dart';
import 'package:guardianes_chacra/features/content/data/file_asset_source.dart';
import 'package:guardianes_chacra/features/content/domain/game_content.dart';
import 'package:guardianes_chacra/features/content/presentation/content_providers.dart';

/// Carga el contenido real de `assets/` una vez por archivo de tests.
GameContent Function() useRealContent() {
  late GameContent content;
  setUpAll(() async {
    content = await ContentLoader(FileAssetSource()).load();
  });
  return () => content;
}

/// Reemplaza la carga del contenido (que en los tests de widgets no
/// termina con el reloj falso) por [content] ya cargado.
Override contentOverride(GameContent content) =>
    gameContentProvider.overrideWith((ref) => content);
