import 'package:guardianes_chacra/features/progress/data/save_codec.dart';
import 'package:guardianes_chacra/features/progress/domain/progress_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guarda el avance en el teléfono con `shared_preferences`: un solo texto
/// JSON (ver [SaveCodec]) en la clave [key].
///
/// Un solo documento y no una clave por dato: se escribe de una vez (o todo
/// o nada) y se versiona y migra entero.
class LocalProgressRepository implements ProgressRepository {
  new(this._preferences, {this._codec = const SaveCodec()});

  static const key = 'guardianes.save';

  /// Copia de un guardado que no se pudo leer, para no perderlo.
  static const backupKey = 'guardianes.save.backup';

  final SharedPreferencesAsync _preferences;
  final SaveCodec _codec;

  /// La última escritura: cada una espera a la anterior, para que un
  /// guardado viejo nunca pise a uno más nuevo.
  Future<void> _lastWrite = Future.value();

  @override
  Future<SaveData> load() async {
    final text = await _preferences.getString(key);
    if (text == null) return const SaveData();
    try {
      return _codec.decode(text);
    } on SaveFormatException {
      // Se empieza de cero, pero el texto original queda aparte: si era de
      // una versión más nueva del juego, vuelve a servir al actualizar.
      await _preferences.setString(backupKey, text);
      return const SaveData();
    }
  }

  @override
  Future<void> save(SaveData data) {
    final text = _codec.encode(data);
    final write = _lastWrite.then((_) => _preferences.setString(key, text));
    // Si una escritura falla, las siguientes igual se intentan.
    _lastWrite = write.catchError((Object _) {});
    return write;
  }
}
