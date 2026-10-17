/// De dónde se leen los archivos de contenido. El cargador no sabe si
/// vienen del paquete de la app (`rootBundle`), del disco (tests y
/// herramientas) o de la memoria (tests): así puede ser Dart puro.
abstract interface class AssetSource {
  /// El texto de [path] (relativo a la raíz del proyecto, por ejemplo
  /// `assets/content/index.json`). Lanza un `ContentError` si no existe.
  Future<String> readText(String path);
}
