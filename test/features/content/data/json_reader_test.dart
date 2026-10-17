import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/content/data/json_reader.dart';

void main() {
  const file = 'levels/prueba.json';

  JsonNode parse(String text) => JsonNode.parse(text, file: file);

  String errorOf(void Function() action) {
    try {
      action();
    } on ContentError catch (error) {
      return error.message;
    }
    fail('No lanzó ContentError');
  }

  final level = parse('''
{
  "startingCorn": 200,
  "rate": 1.5,
  "boss": true,
  "waves": [
    {"groups": [{"pest": "gorgojo", "count": 3}]},
    {"groups": [{"pest": "polilla", "count": 2.5, "path": 7}]}
  ]
}
''');

  JsonNode group(int wave) => level.list('waves')[wave].list('groups').single;

  test('lee valores anidados', () {
    expect(level.integer('startingCorn'), 200);
    expect(level.number('rate'), 1.5);
    expect(level.boolOr('boss', fallback: false), isTrue);
    expect(group(0).string('pest'), 'gorgojo');
    expect(group(0).integer('count', min: 1), 3);
  });

  test('un campo que falta dice su ruta completa', () {
    expect(
      errorOf(() => group(0).string('path')),
      'levels/prueba.json → waves[0].groups[0].path: falta este campo',
    );
  });

  test('un tipo incorrecto dice qué se esperaba', () {
    expect(
      errorOf(() => group(1).integer('count')),
      'levels/prueba.json → waves[1].groups[0].count: debe ser un entero',
    );
    expect(
      errorOf(() => group(1).string('path')),
      'levels/prueba.json → waves[1].groups[0].path: debe ser un texto',
    );
    expect(
      errorOf(() => level.list('rate')),
      'levels/prueba.json → rate: debe ser una lista',
    );
    expect(
      errorOf(() => level.list('waves')[0].string('groups')),
      'levels/prueba.json → waves[0].groups: debe ser un texto',
    );
  });

  test('valida mínimos y máximos', () {
    final node = parse('{"count": 0, "factor": 1.5}');

    expect(
      errorOf(() => node.integer('count', min: 1)),
      'levels/prueba.json → count: debe ser al menos 1',
    );
    expect(
      errorOf(() => node.number('factor', min: 0, max: 1)),
      'levels/prueba.json → factor: debe estar entre 0 y 1',
    );
  });

  test('los campos opcionales usan su valor por defecto', () {
    expect(level.numberOr('delay', 0), 0);
    expect(level.boolOr('hidden', fallback: false), isFalse);
    expect(level.listOr('unlocks'), isEmpty);
    expect(level.has('waves'), isTrue);
    expect(level.has('delay'), isFalse);
  });

  test('pedir un campo a algo que no es un objeto falla con su ruta', () {
    expect(
      errorOf(() => level['rate'].string('x')),
      'levels/prueba.json → rate: debe ser un objeto',
    );
  });

  test('asObject y asRawObject recorren las claves', () {
    final node = parse('{"tags": {"fire": 1.5, "physical": 0.5}}');

    expect(node['tags'].asObject().keys, ['fire', 'physical']);
    expect(node['tags'].asObject()['fire']!.asNumber(), 1.5);
    expect(node['tags'].asRawObject(), {'fire': 1.5, 'physical': 0.5});
  });

  test('un JSON mal escrito dice en qué archivo está', () {
    expect(
      errorOf(() => parse('{"count": 3,}')),
      startsWith('levels/prueba.json: el JSON no es válido'),
    );
  });

  test('un error del archivo completo no lleva ruta', () {
    expect(
      errorOf(() => parse('[1, 2]').string('id')),
      'levels/prueba.json: debe ser un objeto',
    );
  });
}
