import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/features/progress/domain/progress_repository.dart';
import 'package:guardianes_chacra/features/progress/presentation/progress_providers.dart';
import 'package:guardianes_chacra/features/progress/presentation/save_providers.dart';
import 'package:guardianes_chacra/features/settings/presentation/settings_providers.dart';

/// Guarda el avance y los ajustes cada vez que cambian. Así los
/// controladores solo cambian su estado y no saben nada del disco.
///
/// Vive en `app/` porque une dos features (progreso y ajustes) que se
/// guardan en el mismo documento. `GuardianesApp` lo mantiene vivo.
final autosaveProvider = Provider<void>((ref) {
  final repository = ref.watch(progressRepositoryProvider);

  void save() {
    final data = SaveData(
      progress: ref.read(progressProvider),
      settings: ref.read(settingsProvider),
    );
    // Un fallo al escribir no debe cortar el juego: se avisa y la próxima
    // vez se vuelve a intentar con todo.
    unawaited(
      repository
          .save(data)
          .catchError(
            (Object error) => debugPrint('No se pudo guardar: $error'),
          ),
    );
  }

  ref
    ..listen(progressProvider, (_, _) => save())
    ..listen(settingsProvider, (_, _) => save());
});
