import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/progress/data/local_progress_repository.dart';
import 'package:guardianes_chacra/features/progress/domain/progress.dart';
import 'package:guardianes_chacra/features/progress/domain/progress_repository.dart';
import 'package:guardianes_chacra/features/settings/domain/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Un almacén en memoria donde la primera escritura tarda más que las
/// demás: sin la cola del repositorio, terminaría última y pisaría a la
/// más nueva.
base class _SlowFirstWrite extends InMemorySharedPreferencesAsync {
  new() : super.empty();

  var _writes = 0;

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) async {
    if (_writes++ == 0) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    }
    return await super.setString(key, value, options);
  }
}

void main() {
  late SharedPreferencesAsync preferences;

  void useStore(SharedPreferencesAsyncPlatform store) {
    SharedPreferencesAsyncPlatform.instance = store;
    preferences = SharedPreferencesAsync();
  }

  setUp(() => useStore(InMemorySharedPreferencesAsync.empty()));

  final saved = SaveData(
    progress: const Progress().withResult('valle', stars: 2),
    settings: const Settings(language: AppLanguage.en),
  );

  test('sin guardado, empieza de cero', () async {
    expect(await LocalProgressRepository(preferences).load(), const SaveData());
  });

  test('lo guardado se lee al volver a abrir la app', () async {
    await LocalProgressRepository(preferences).save(saved);

    // Otro repositorio sobre el mismo almacén: como al reiniciar la app.
    expect(await LocalProgressRepository(preferences).load(), saved);
  });

  test('un guardado ilegible se aparta y se empieza de cero', () async {
    const unreadable = '{"version": 99}';
    await preferences.setString(LocalProgressRepository.key, unreadable);

    expect(await LocalProgressRepository(preferences).load(), const SaveData());
    expect(
      await preferences.getString(LocalProgressRepository.backupKey),
      unreadable,
    );
  });

  test('las escrituras se hacen en orden: gana la última', () async {
    useStore(_SlowFirstWrite());
    final repository = LocalProgressRepository(preferences);

    // Sin esperar entre una y otra, como el autoguardado.
    final first = repository.save(const SaveData());
    final second = repository.save(saved);
    await Future.wait([first, second]);

    expect(await repository.load(), saved);
  });
}
