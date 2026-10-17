import 'package:guardianes_chacra/features/progress/domain/progress.dart';
import 'package:guardianes_chacra/features/settings/domain/settings.dart';
import 'package:meta/meta.dart';

/// Lo que se guarda en el teléfono: el avance y los ajustes. Se guarda
/// junto, como un solo documento.
@immutable
class SaveData {
  const new({
    this.progress = const Progress(),
    this.settings = const Settings(),
  });

  final Progress progress;
  final Settings settings;

  @override
  bool operator ==(Object other) =>
      other is SaveData &&
      other.progress == progress &&
      other.settings == settings;

  @override
  int get hashCode => Object.hash(progress, settings);
}

/// Dónde se guarda el avance. La app usa la implementación local
/// (`LocalProgressRepository`); los tests, una en memoria.
abstract interface class ProgressRepository {
  /// El guardado, o uno nuevo si no hay (o si no se pudo leer).
  Future<SaveData> load();

  Future<void> save(SaveData data);
}
