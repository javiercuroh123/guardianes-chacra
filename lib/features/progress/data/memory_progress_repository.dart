import 'package:guardianes_chacra/features/progress/domain/progress_repository.dart';

/// Guarda el avance solo en memoria (se pierde al cerrar la app). Es la
/// implementación por defecto: la usan los tests y cualquier arranque que
/// no pase la local (ver `main.dart`).
class MemoryProgressRepository implements ProgressRepository {
  new([this.saved = const SaveData()]);

  /// Lo último que se guardó.
  SaveData saved;

  @override
  Future<SaveData> load() async => saved;

  @override
  Future<void> save(SaveData data) async => saved = data;
}
