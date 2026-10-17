/// Textos del contenido (nombres y fichas del Bestiario) por idioma.
///
/// Los textos de la interfaz van en los ARB, pero estos se buscan por clave
/// en tiempo de ejecución (gen-l10n no lo permite), así que viven en
/// `assets/content/i18n/<idioma>.json`. Las claves se arman con las
/// funciones de abajo para que el cargador y las pantallas coincidan.
class ContentTexts {
  new(Map<String, Map<String, String>> byLanguage)
    : _byLanguage = {
        for (final MapEntry(:key, :value) in byLanguage.entries)
          key: Map.unmodifiable(value),
      };

  final Map<String, Map<String, String>> _byLanguage;

  Iterable<String> get languages => _byLanguage.keys;

  static String pestName(String id) => 'pest.$id.name';
  static String pestDescription(String id) => 'pest.$id.description';
  static String guardianName(String id) => 'guardian.$id.name';
  static String guardianDescription(String id) => 'guardian.$id.description';
  static String branchName(String guardianId, String branchId) =>
      'guardian.$guardianId.branch.$branchId.name';
  static String branchDescription(String guardianId, String branchId) =>
      'guardian.$guardianId.branch.$branchId.description';
  static String levelName(String id) => 'level.$id.name';

  bool has(String key, String language) =>
      _byLanguage[language]?.containsKey(key) ?? false;

  /// El texto de [key] en [language]. Si falta, usa el primer idioma
  /// cargado y, si tampoco está, devuelve la clave (se nota en pantalla
  /// sin romper el juego).
  String text(String key, {required String language}) =>
      _byLanguage[language]?[key] ??
      _byLanguage.values.firstOrNull?[key] ??
      key;
}
