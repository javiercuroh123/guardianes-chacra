import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/content/domain/content_texts.dart';

void main() {
  final texts = ContentTexts({
    'es': {'pest.gorgojo.name': 'Gorgojo', 'level.valle.name': 'Valle'},
    'en': {'pest.gorgojo.name': 'Weevil'},
  });

  test('devuelve el texto en el idioma pedido', () {
    expect(texts.text('pest.gorgojo.name', language: 'en'), 'Weevil');
    expect(texts.text('pest.gorgojo.name', language: 'es'), 'Gorgojo');
  });

  test('si falta en ese idioma, usa el primero cargado', () {
    expect(texts.text('level.valle.name', language: 'en'), 'Valle');
    expect(texts.text('level.valle.name', language: 'fr'), 'Valle');
  });

  test('si no existe en ningún idioma, devuelve la clave', () {
    expect(texts.text('pest.x.name', language: 'es'), 'pest.x.name');
  });

  test('has dice si un idioma tiene la clave', () {
    expect(texts.has('level.valle.name', 'es'), isTrue);
    expect(texts.has('level.valle.name', 'en'), isFalse);
  });
}
