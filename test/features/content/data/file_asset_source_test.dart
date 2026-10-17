import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/content/data/file_asset_source.dart';
import 'package:guardianes_chacra/features/content/data/json_reader.dart';

void main() {
  // Los tests corren desde la raíz del proyecto.
  final source = FileAssetSource();

  test('lee un archivo relativo a la raíz del proyecto', () async {
    expect(
      await source.readText('assets/content/rules.json'),
      contains('sellRefundRate'),
    );
  });

  test('un archivo que no existe lanza un ContentError claro', () async {
    await expectLater(
      source.readText('assets/no_existe.json'),
      throwsA(
        isA<ContentError>().having(
          (error) => error.message,
          'message',
          'No se encontró el archivo "assets/no_existe.json"',
        ),
      ),
    );
  });
}
