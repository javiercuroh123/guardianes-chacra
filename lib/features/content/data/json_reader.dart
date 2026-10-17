import 'dart:convert';

/// Error en los archivos de contenido. El mensaje dice el archivo y, si
/// aplica, la ruta dentro del JSON: `levels/andenes.json → waves[3].reward:
/// debe ser un entero`.
class ContentError implements Exception {
  new(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Un valor dentro de un JSON que recuerda dónde está (archivo y ruta),
/// para que cada error de lectura diga exactamente qué hay que corregir.
class JsonNode {
  new _(this.file, this.path, this.value);

  factory parse(String text, {required String file}) {
    try {
      return JsonNode._(file, '', jsonDecode(text));
    } on FormatException catch (error) {
      throw ContentError('$file: el JSON no es válido (${error.message})');
    }
  }

  final String file;

  /// Ruta dentro del JSON, por ejemplo `waves[3].groups[0].pest`.
  final String path;

  final Object? value;

  /// El campo [key] de este objeto (puede faltar: el error llega al leerlo).
  JsonNode operator [](String key) =>
      JsonNode._(file, path.isEmpty ? key : '$path.$key', _object[key]);

  bool has(String key) => _object[key] != null;

  String string(String key) => this[key].asString();

  int integer(String key, {int? min}) => this[key].asInt(min: min);

  double number(String key, {double? min, double? max}) =>
      this[key].asNumber(min: min, max: max);

  double numberOr(String key, double fallback, {double? min, double? max}) =>
      has(key) ? number(key, min: min, max: max) : fallback;

  bool boolOr(String key, {required bool fallback}) =>
      has(key) ? this[key].asBool() : fallback;

  List<JsonNode> list(String key) => this[key].asList();

  List<JsonNode> listOr(String key) => has(key) ? list(key) : const [];

  String asString() {
    final value = _present;
    if (value is! String) throw error('debe ser un texto');
    return value;
  }

  int asInt({int? min}) {
    final value = _present;
    if (value is! int) throw error('debe ser un entero');
    if (min != null && value < min) throw error('debe ser al menos $min');
    return value;
  }

  double asNumber({double? min, double? max}) {
    final value = _present;
    if (value is! num) throw error('debe ser un número');
    final number = value.toDouble();
    if (min != null && max != null && (number < min || number > max)) {
      throw error('debe estar entre ${_format(min)} y ${_format(max)}');
    }
    if (min != null && number < min) {
      throw error('debe ser al menos ${_format(min)}');
    }
    if (max != null && number > max) {
      throw error('debe ser como máximo ${_format(max)}');
    }
    return number;
  }

  bool asBool() {
    final value = _present;
    if (value is! bool) throw error('debe ser true o false');
    return value;
  }

  List<JsonNode> asList() {
    final value = _present;
    if (value is! List) throw error('debe ser una lista');
    return [
      for (final (index, item) in value.indexed)
        JsonNode._(file, '$path[$index]', item),
    ];
  }

  /// Los campos de este objeto, en el orden del archivo.
  Map<String, JsonNode> asObject() => {
    for (final key in _object.keys) key: this[key],
  };

  /// El objeto tal cual (por ejemplo, los parámetros de un comportamiento,
  /// que valida el registro de la simulación).
  Map<String, Object?> asRawObject() => Map.of(_object);

  ContentError error(String detail) =>
      ContentError(path.isEmpty ? '$file: $detail' : '$file → $path: $detail');

  Object get _present => value ?? (throw error('falta este campo'));

  Map<String, Object?> get _object {
    final value = _present;
    if (value is! Map<String, Object?>) throw error('debe ser un objeto');
    return value;
  }

  static String _format(double value) => value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toString();
}
