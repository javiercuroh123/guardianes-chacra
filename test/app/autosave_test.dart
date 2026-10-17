import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/app/app.dart';
import 'package:guardianes_chacra/features/menu/presentation/title_screen.dart';
import 'package:guardianes_chacra/features/progress/data/memory_progress_repository.dart';
import 'package:guardianes_chacra/features/progress/domain/progress.dart';
import 'package:guardianes_chacra/features/progress/domain/progress_repository.dart';
import 'package:guardianes_chacra/features/progress/presentation/progress_providers.dart';
import 'package:guardianes_chacra/features/progress/presentation/save_providers.dart';
import 'package:guardianes_chacra/features/settings/domain/settings.dart';
import 'package:guardianes_chacra/features/settings/presentation/settings_providers.dart';

import '../helpers/test_app.dart';

/// Cuenta cuántas veces se guardó.
class _CountingRepository extends MemoryProgressRepository {
  new(super.saved);

  int saves = 0;

  @override
  Future<void> save(SaveData data) {
    saves++;
    return super.save(data);
  }
}

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    required MemoryProgressRepository repository,
  }) async {
    tester.platformDispatcher.localesTestValue = [const Locale('es', 'PE')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          progressRepositoryProvider.overrideWithValue(repository),
          // Como main.dart: lo guardado se lee antes de mostrar la app.
          savedGameProvider.overrideWithValue(await repository.load()),
        ],
        child: const GuardianesApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('el avance y los ajustes se guardan al cambiar', (tester) async {
    final repository = MemoryProgressRepository();
    await pumpApp(tester, repository: repository);
    final container = containerOf(tester, TitleScreen);

    container.read(progressProvider.notifier).discoverPest('gorgojo');
    container.read(settingsProvider.notifier).language = AppLanguage.en;
    await tester.pumpAndSettle();

    expect(repository.saved.progress.discoveredPests, {'gorgojo'});
    expect(repository.saved.settings.language, AppLanguage.en);
  });

  testWidgets('al abrir la app se sigue desde lo guardado', (tester) async {
    final repository = _CountingRepository(
      SaveData(
        progress: const Progress().withResult('chacra_del_valle', stars: 3),
        settings: const Settings(language: AppLanguage.en),
      ),
    );
    await pumpApp(tester, repository: repository);
    final container = containerOf(tester, TitleScreen);

    // El idioma guardado manda sobre el del teléfono (español).
    expect(find.text('Guardians of the Chacra'), findsOneWidget);
    expect(container.read(progressProvider).starsOf('chacra_del_valle'), 3);
    // Abrir la app no reescribe el guardado: solo se guarda al cambiar algo.
    expect(repository.saves, 0);
  });
}
