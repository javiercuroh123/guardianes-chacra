import 'dart:convert';

import 'package:guardianes_chacra/features/progress/domain/progress.dart';
import 'package:guardianes_chacra/features/progress/domain/progress_repository.dart';
import 'package:guardianes_chacra/features/settings/domain/settings.dart';

/// Convierte un guardado de una versión en el de la siguiente.
typedef SaveMigration = Map<String, Object?> Function(Map<String, Object?> old);

/// Las migraciones del formato del guardado, en orden: la primera convierte
/// la versión 1 en la 2, la segunda la 2 en la 3, etc.
///
/// La versión 1 es el primer formato, así que todavía no hay ninguna. Para
/// cambiar el formato: se agrega aquí la función que convierte el anterior
/// en el nuevo (con su test) y la versión actual sube sola.
const List<SaveMigration> saveMigrations = [];

/// El guardado no se puede leer: JSON roto, un tipo inesperado o una
/// versión más nueva que esta app (por ejemplo, tras instalar una versión
/// anterior del juego).
class SaveFormatException implements Exception {
  new(this.message);

  final String message;

  @override
  String toString() => 'SaveFormatException: $message';
}

/// El guardado en JSON, con un número de versión:
///
/// ```json
/// {"version": 1, "progress": {...}, "settings": {...}}
/// ```
///
/// Al leer, primero se aplican las migraciones desde la versión guardada
/// hasta la actual; después se leen los campos. Un campo que falta toma su
/// valor por defecto, así que agregar un campo opcional no necesita
/// migración.
class SaveCodec {
  const new({this.migrations = saveMigrations});

  final List<SaveMigration> migrations;

  int get currentVersion => migrations.length + 1;

  String encode(SaveData data) => jsonEncode({
    'version': currentVersion,
    'progress': {
      'stars': data.progress.stars,
      'discoveredPests': _sorted(data.progress.discoveredPests),
      'discoveredGuardians': _sorted(data.progress.discoveredGuardians),
      'unlockedLevels': _sorted(data.progress.unlockedLevels),
      'unlockedGuardians': _sorted(data.progress.unlockedGuardians),
    },
    'settings': {
      'music': data.settings.music,
      'effects': data.settings.effects,
      'vibration': data.settings.vibration,
      'damageNumbers': data.settings.damageNumbers,
      'language': data.settings.language.name,
    },
  });

  SaveData decode(String text) {
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException catch (error) {
      throw SaveFormatException('JSON roto: ${error.message}');
    }
    final json = migrate(_object(decoded, 'el guardado'));
    final progress = _object(json['progress'] ?? _empty, 'progress');
    final settings = _object(json['settings'] ?? _empty, 'settings');
    return SaveData(
      progress: Progress(
        stars: {
          for (final MapEntry(:key, :value) in _object(
            progress['stars'] ?? _empty,
            'stars',
          ).entries)
            key: _int(value, 'stars.$key').clamp(0, 3),
        },
        discoveredPests: _ids(progress, 'discoveredPests'),
        discoveredGuardians: _ids(progress, 'discoveredGuardians'),
        unlockedLevels: _ids(progress, 'unlockedLevels'),
        unlockedGuardians: _ids(progress, 'unlockedGuardians'),
      ),
      settings: Settings(
        music: _bool(settings, 'music'),
        effects: _bool(settings, 'effects'),
        vibration: _bool(settings, 'vibration'),
        // Agregado en la Fase 8: un guardado anterior no lo tiene y queda
        // apagado, su valor por defecto (no hace falta migración).
        damageNumbers: _bool(settings, 'damageNumbers', fallback: false),
        language:
            AppLanguage.values.asNameMap()[settings['language']] ??
            AppLanguage.system,
      ),
    );
  }

  /// Lleva [json] (de cualquier versión anterior) a la versión actual.
  Map<String, Object?> migrate(Map<String, Object?> json) {
    final version = _int(json['version'], 'version');
    if (version < 1) throw SaveFormatException('versión $version inválida');
    if (version > currentVersion) {
      throw SaveFormatException(
        'versión $version, más nueva que la de esta app ($currentVersion)',
      );
    }
    var migrated = json;
    for (var from = version; from < currentVersion; from++) {
      migrated = {...migrations[from - 1](migrated), 'version': from + 1};
    }
    return migrated;
  }

  /// Un objeto vacío del tipo que da `jsonDecode` (un `const {}` sin tipo
  /// sería `Map<dynamic, dynamic>` y no pasaría la comprobación).
  static const _empty = <String, Object?>{};

  static List<String> _sorted(Set<String> ids) => [...ids]..sort();

  static Map<String, Object?> _object(Object? value, String what) {
    if (value is Map<String, Object?>) return value;
    throw SaveFormatException('$what debe ser un objeto');
  }

  static int _int(Object? value, String what) {
    if (value is int) return value;
    throw SaveFormatException('$what debe ser un entero');
  }

  static Set<String> _ids(Map<String, Object?> json, String key) {
    final value = json[key] ?? const <Object?>[];
    if (value is List<Object?> && value.every((id) => id is String)) {
      return {...value.cast<String>()};
    }
    throw SaveFormatException('$key debe ser una lista de textos');
  }

  /// Un ajuste que falta toma su valor por defecto ([fallback]).
  static bool _bool(
    Map<String, Object?> json,
    String key, {
    bool fallback = true,
  }) {
    final value = json[key] ?? fallback;
    if (value is bool) return value;
    throw SaveFormatException('$key debe ser true o false');
  }
}
