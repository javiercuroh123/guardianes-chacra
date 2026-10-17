import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/features/progress/data/memory_progress_repository.dart';
import 'package:guardianes_chacra/features/progress/domain/progress_repository.dart';

/// Dónde se guarda el avance. Por defecto, en memoria; `main.dart` pone el
/// local (`LocalProgressRepository`).
final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => MemoryProgressRepository(),
);

/// Lo que se leyó del teléfono al abrir la app. `main.dart` lo carga antes
/// de mostrar nada, así las pantallas nunca esperan al guardado.
final savedGameProvider = Provider<SaveData>((ref) => const SaveData());
