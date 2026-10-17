import 'package:guardianes_chacra/features/content/data/asset_source.dart';
import 'package:guardianes_chacra/features/content/data/json_reader.dart';
import 'package:guardianes_chacra/features/content/data/tiled_map_reader.dart';
import 'package:guardianes_chacra/features/content/domain/battle_rules.dart';
import 'package:guardianes_chacra/features/content/domain/behavior_spec.dart';
import 'package:guardianes_chacra/features/content/domain/content_texts.dart';
import 'package:guardianes_chacra/features/content/domain/game_content.dart';
import 'package:guardianes_chacra/features/content/domain/guardian_def.dart';
import 'package:guardianes_chacra/features/content/domain/level_def.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';

/// Convierte los JSON de `assets/content/` y los mapas de `assets/tiles/`
/// en objetos del dominio, validando todo lo que entiende: tipos, rangos,
/// etiquetas, referencias a plagas y caminos, ramas y textos.
///
/// Los parámetros de cada comportamiento ("damage", "factor"…) los valida
/// el registro de la simulación al crear la partida (ver
/// `real_content_test.dart`, que crea una partida con cada nivel).
///
/// El esquema de cada archivo está documentado en `docs/CONTENIDO.md`.
class ContentLoader {
  new(this._source);

  static const contentDir = 'assets/content';
  static const tilesDir = 'assets/tiles';

  final AssetSource _source;

  Future<GameContent> load() async {
    final index = await _json('index.json');
    final languages = _ids(index, 'languages');
    final rules = _rules(await _json('rules.json'));

    final pests = <String, PestDef>{
      for (final id in _ids(index, 'pests'))
        id: _pest(id, await _json('pests/$id.json')),
    };
    final guardians = <String, GuardianDef>{
      for (final id in _ids(index, 'guardians'))
        id: _guardian(id, await _json('guardians/$id.json')),
    };
    final levels = <LevelDef>[
      for (final id in _ids(index, 'levels'))
        await _level(id, await _json('levels/$id.json'), pests),
    ];
    final texts = ContentTexts({
      for (final language in languages)
        language: _texts(
          await _json('i18n/$language.json'),
          required: _requiredTextKeys(pests, guardians, levels),
        ),
    });

    return GameContent(
      rules: rules,
      pests: pests,
      guardians: guardians,
      levels: levels,
      texts: texts,
    );
  }

  Future<JsonNode> _json(String relativePath) async => JsonNode.parse(
    await _source.readText('$contentDir/$relativePath'),
    file: relativePath,
  );

  // --- index.json

  static final _idPattern = RegExp(r'^[a-z0-9_]+$');

  List<String> _ids(JsonNode index, String key) {
    final nodes = index.list(key);
    if (nodes.isEmpty) throw index[key].error('no puede estar vacía');
    final ids = <String>[];
    for (final node in nodes) {
      final id = node.asString();
      if (!_idPattern.hasMatch(id)) {
        throw node.error('"$id" solo puede tener minúsculas, números y _');
      }
      if (ids.contains(id)) throw index[key].error('"$id" está repetido');
      ids.add(id);
    }
    return ids;
  }

  // --- rules.json

  BattleRules _rules(JsonNode node) {
    final twoStars = node.number('twoStarsFraction', min: 0, max: 1);
    final threeStars = node.number('threeStarsFraction', min: 0, max: 1);
    if (threeStars < twoStars) {
      throw node['threeStarsFraction'].error(
        'debe ser mayor o igual que twoStarsFraction',
      );
    }
    return BattleRules(
      sellRefundRate: node.number('sellRefundRate', min: 0, max: 1),
      minDamageFraction: node.number('minDamageFraction', min: 0, max: 1),
      twoStarsFraction: twoStars,
      threeStarsFraction: threeStars,
    );
  }

  // --- pests/<id>.json

  PestDef _pest(String id, JsonNode node) {
    final tags = _tags(node.list('tags'));
    if (tags.isEmpty) {
      throw node['tags'].error('necesita al menos una etiqueta');
    }
    return PestDef(
      id: id,
      maxHealth: node.number('maxHealth', min: 1),
      speed: node.number('speed', min: 0),
      armor: node.numberOr('armor', 0, min: 0),
      resistances: _resistances(node),
      cornReward: node.integer('cornReward', min: 0),
      potatoDamage: node.integer('potatoDamage', min: 0),
      tags: tags,
      immunities: {
        for (final immunity in node.listOr('immunities')) immunity.asString(),
      },
      abilities: [for (final spec in node.listOr('abilities')) _spec(spec)],
      boss: node.boolOr('boss', fallback: false),
      color: _color(node),
    );
  }

  static final _colorPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');

  /// `"color": "#RRGGBB"` (opcional) → ARGB opaco.
  int? _color(JsonNode def) {
    if (!def.has('color')) return null;
    final node = def['color'];
    final text = node.asString();
    if (!_colorPattern.hasMatch(text)) {
      throw node.error('debe ser un color #RRGGBB');
    }
    return 0xFF000000 | int.parse(text.substring(1), radix: 16);
  }

  Map<DamageType, double> _resistances(JsonNode pest) {
    if (!pest.has('resistances')) return const {};
    return {
      for (final MapEntry(:key, :value)
          in pest['resistances'].asObject().entries)
        _damageType(key, value): value.asNumber(min: 0),
    };
  }

  DamageType _damageType(String name, JsonNode at) =>
      DamageType.values.where((type) => type.name == name).firstOrNull ??
      (throw at.error(
        'tipo de daño desconocido (válidos: ${_names(DamageType.values)})',
      ));

  Set<PestTag> _tags(List<JsonNode> nodes) => {
    for (final node in nodes)
      PestTag.values.where((tag) => tag.name == node.asString()).firstOrNull ??
          (throw node.error(
            'etiqueta desconocida "${node.asString()}" '
            '(válidas: ${_names(PestTag.values)})',
          )),
  };

  /// `{"type": "projectile", ...parámetros}` → [BehaviorSpec].
  BehaviorSpec _spec(JsonNode node) {
    final type = node.string('type');
    final params = node.asRawObject()..remove('type');
    return BehaviorSpec(type, params);
  }

  // --- guardians/<id>.json

  GuardianDef _guardian(String id, JsonNode node) {
    final levels = node.list('levels');
    if (levels.isEmpty) {
      throw node['levels'].error('necesita al menos un nivel');
    }

    final branches = node.listOr('branches');
    if (branches.length == 1) {
      throw node['branches'].error('debe tener al menos 2 ramas (o ninguna)');
    }
    final branchIds = <String>{};
    for (final branch in branches) {
      final branchId = branch.string('id');
      if (!branchIds.add(branchId)) {
        throw branch['id'].error('la rama "$branchId" está repetida');
      }
    }

    return GuardianDef(
      id: id,
      defaultTargeting: node.has('defaultTargeting')
          ? node.string('defaultTargeting')
          : 'first',
      color: _color(node),
      levels: [for (final level in levels) _guardianLevel(level)],
      branches: [
        for (final branch in branches)
          GuardianBranchDef(
            id: branch.string('id'),
            level: _guardianLevel(branch),
          ),
      ],
    );
  }

  GuardianLevelDef _guardianLevel(JsonNode node) => GuardianLevelDef(
    cost: node.integer('cost', min: 0),
    range: node.number('range', min: 0),
    targets: _tags(node.listOr('targets')),
    behaviors: [for (final spec in node.listOr('behaviors')) _spec(spec)],
  );

  // --- levels/<id>.json + tiles/<mapa>.tmx

  Future<LevelDef> _level(
    String id,
    JsonNode node,
    Map<String, PestDef> pests,
  ) async {
    final mapFile = node.string('map');
    final map = readTiledMap(
      await _source.readText('$tilesDir/$mapFile'),
      file: 'tiles/$mapFile',
    );

    final waves = node.list('waves');
    if (waves.isEmpty) {
      throw node['waves'].error('necesita al menos una oleada');
    }

    return LevelDef(
      id: id,
      mapFile: mapFile,
      map: map,
      startingCorn: node.integer('startingCorn', min: 0),
      startingPotatoes: node.integer('startingPotatoes', min: 1),
      earlyCallCornPerSecond: node.number('earlyCallCornPerSecond', min: 0),
      waves: [
        for (final wave in waves)
          _wave(wave, pests: pests, map: map, mapFile: mapFile),
      ],
    );
  }

  WaveDef _wave(
    JsonNode node, {
    required Map<String, PestDef> pests,
    required MapDef map,
    required String mapFile,
  }) {
    final groups = node.list('groups');
    if (groups.isEmpty) {
      throw node['groups'].error('necesita al menos un grupo');
    }

    return WaveDef(
      prepTime: node.number('prepTime', min: 0),
      reward: node.integer('reward', min: 0),
      groups: [
        for (final group in groups)
          SpawnGroupDef(
            pestId: _reference(
              group['pest'],
              exists: pests.containsKey,
              missing: (id) => 'la plaga "$id" no existe',
            ),
            pathId: _reference(
              group['path'],
              exists: (id) => map.paths.any((path) => path.id == id),
              missing: (id) => 'el camino "$id" no existe en tiles/$mapFile',
            ),
            count: group.integer('count', min: 1),
            delay: group.numberOr('delay', 0, min: 0),
            interval: group.numberOr('interval', 0, min: 0),
          ),
      ],
    );
  }

  String _reference(
    JsonNode node, {
    required bool Function(String id) exists,
    required String Function(String id) missing,
  }) {
    final id = node.asString();
    if (!exists(id)) throw node.error(missing(id));
    return id;
  }

  // --- i18n/<idioma>.json

  Map<String, String> _texts(JsonNode node, {required List<String> required}) {
    final texts = <String, String>{
      for (final MapEntry(:key, :value) in node.asObject().entries)
        // Las claves con @ son notas para quien traduce o revisa.
        if (!key.startsWith('@')) key: value.asString(),
    };
    for (final key in required) {
      if (!texts.containsKey(key)) {
        throw node.error('falta el texto "$key"');
      }
    }
    return texts;
  }

  List<String> _requiredTextKeys(
    Map<String, PestDef> pests,
    Map<String, GuardianDef> guardians,
    List<LevelDef> levels,
  ) => [
    for (final id in pests.keys) ...[
      ContentTexts.pestName(id),
      ContentTexts.pestDescription(id),
    ],
    for (final guardian in guardians.values) ...[
      ContentTexts.guardianName(guardian.id),
      ContentTexts.guardianDescription(guardian.id),
      for (final branch in guardian.branches) ...[
        ContentTexts.branchName(guardian.id, branch.id),
        ContentTexts.branchDescription(guardian.id, branch.id),
      ],
    ],
    for (final level in levels) ContentTexts.levelName(level.id),
  ];

  static String _names(List<Enum> values) =>
      values.map((value) => value.name).join(', ');
}
