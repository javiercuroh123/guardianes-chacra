import 'dart:convert';

import 'package:guardianes_chacra/features/content/data/asset_source.dart';
import 'package:guardianes_chacra/features/content/data/json_reader.dart';

import 'tmx_builder.dart';

/// Lee archivos desde un mapa en memoria.
class MemoryAssetSource implements AssetSource {
  new(this.files);

  final Map<String, String> files;

  @override
  Future<String> readText(String path) async =>
      files[path] ?? (throw ContentError('No se encontró el archivo "$path"'));
}

/// Un contenido mínimo y válido (una plaga, un guardián y un nivel) que cada
/// test puede modificar para provocar un error concreto.
class ContentFixture {
  Map<String, Object?> index = {
    'languages': ['es', 'en'],
    'guardians': ['hondero'],
    'pests': ['gorgojo'],
    'levels': ['prueba'],
  };

  Map<String, Object?> rules = {
    'sellRefundRate': 0.7,
    'minDamageFraction': 0.2,
    'twoStarsFraction': 0.5,
    'threeStarsFraction': 0.9,
  };

  Map<String, Object?> audio = {
    'menuMusic': 'music/menu.wav',
    'sfx': {'shot': 'sfx/shot.wav'},
  };

  Map<String, Map<String, Object?>> pests = {'gorgojo': gorgojoJson()};
  Map<String, Map<String, Object?>> guardians = {'hondero': honderoJson()};
  Map<String, Map<String, Object?>> levels = {'prueba': levelJson()};
  Map<String, String> maps = {'prueba.tmx': buildTmx()};
  Map<String, Map<String, Object?>> texts = {
    'es': textsJson('Gorgojo'),
    'en': textsJson('Weevil'),
  };

  /// Archivos que se quitan antes de leer (para probar uno que falta).
  Set<String> missing = {};

  /// Agrega otro nivel (con el mismo mapa) y su nombre en cada idioma.
  void addLevel(String id, {Map<String, Object?>? unlock}) {
    index['levels'] = [...index['levels']! as List<Object?>, id];
    levels[id] = {...levelJson(), 'unlock': ?unlock};
    for (final language in texts.values) {
      language['level.$id.name'] = id;
    }
  }

  /// Agrega otro guardián (igual al Hondero) y sus textos en cada idioma.
  void addGuardian(String id, {Map<String, Object?>? unlock}) {
    index['guardians'] = [...index['guardians']! as List<Object?>, id];
    guardians[id] = {...honderoJson(), 'unlock': ?unlock};
    for (final language in texts.values) {
      language['guardian.$id.name'] = id;
      language['guardian.$id.description'] = '…';
      for (final branch in ['piedra', 'rapida']) {
        language['guardian.$id.branch.$branch.name'] = branch;
        language['guardian.$id.branch.$branch.description'] = '…';
      }
    }
  }

  AssetSource toSource() => MemoryAssetSource(
    {
      'assets/content/index.json': jsonEncode(index),
      'assets/content/rules.json': jsonEncode(rules),
      'assets/content/audio.json': jsonEncode(audio),
      for (final MapEntry(:key, :value) in pests.entries)
        'assets/content/pests/$key.json': jsonEncode(value),
      for (final MapEntry(:key, :value) in guardians.entries)
        'assets/content/guardians/$key.json': jsonEncode(value),
      for (final MapEntry(:key, :value) in levels.entries)
        'assets/content/levels/$key.json': jsonEncode(value),
      for (final MapEntry(:key, :value) in maps.entries)
        'assets/tiles/$key': value,
      for (final MapEntry(:key, :value) in texts.entries)
        'assets/content/i18n/$key.json': jsonEncode(value),
    }..removeWhere((path, _) => missing.contains(path)),
  );
}

Map<String, Object?> gorgojoJson({
  Map<String, Object?> resistances = const {'fire': 1.5},
}) => {
  'maxHealth': 30,
  'speed': 1,
  'armor': 2,
  'resistances': resistances,
  'cornReward': 4,
  'potatoDamage': 1,
  'tags': ['ground'],
  'immunities': ['slow'],
  'abilities': [
    {'type': 'split_on_death', 'pest': 'gorgojo', 'count': 2},
  ],
};

Map<String, Object?> _level({
  required int cost,
  required double range,
  List<String> targets = const ['ground', 'flying'],
  Map<String, Object?>? behavior,
}) => {
  'cost': cost,
  'range': range,
  'targets': targets,
  'behaviors': [
    behavior ??
        {
          'type': 'projectile',
          'damage': 8,
          'damageType': 'physical',
          'cooldown': 0.8,
          'projectileSpeed': 12,
        },
  ],
};

Map<String, Object?> honderoJson({
  List<String> targets = const ['ground', 'flying'],
  Map<String, Object?>? behavior,
  int branchCount = 2,
}) => {
  'defaultTargeting': 'first',
  'levels': [
    _level(cost: 60, range: 3, targets: targets, behavior: behavior),
    _level(cost: 45, range: 3.2),
  ],
  'branches': [
    for (final id in ['piedra', 'rapida'].take(branchCount))
      {'id': id, ..._level(cost: 120, range: 3.5)},
  ],
};

Map<String, Object?> levelJson({
  String pest = 'gorgojo',
  String path = 'norte',
}) => {
  'map': 'prueba.tmx',
  'startingCorn': 200,
  'startingPotatoes': 20,
  'earlyCallCornPerSecond': 1,
  'waves': [
    {
      'prepTime': 10,
      'reward': 20,
      'groups': [
        {'pest': pest, 'count': 3, 'interval': 1.5, 'path': path},
      ],
    },
  ],
};

Map<String, Object?> textsJson(String pestName) => {
  'pest.gorgojo.name': pestName,
  'pest.gorgojo.description': '…',
  '@pest.gorgojo.description': {'revisar': 'nota para quien revisa'},
  'guardian.hondero.name': 'Hondero',
  'guardian.hondero.description': '…',
  'guardian.hondero.branch.piedra.name': 'Piedra',
  'guardian.hondero.branch.piedra.description': '…',
  'guardian.hondero.branch.rapida.name': 'Rápida',
  'guardian.hondero.branch.rapida.description': '…',
  'level.prueba.name': 'Prueba',
};
