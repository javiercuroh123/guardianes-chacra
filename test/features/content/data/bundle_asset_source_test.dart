import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/content/data/bundle_asset_source.dart';
import 'package:guardianes_chacra/features/content/data/json_reader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final source = BundleAssetSource(rootBundle);

  test('lee un asset declarado en pubspec.yaml', () async {
    expect(
      await source.readText('assets/content/rules.json'),
      contains('sellRefundRate'),
    );
  });

  test('un asset que no existe lanza un ContentError claro', () async {
    await expectLater(
      source.readText('assets/content/no_existe.json'),
      throwsA(
        isA<ContentError>().having(
          (error) => error.message,
          'message',
          'No se encontró el archivo "assets/content/no_existe.json"',
        ),
      ),
    );
  });
}
