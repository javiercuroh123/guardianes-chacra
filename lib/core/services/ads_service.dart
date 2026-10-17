import 'package:flutter/foundation.dart';

/// Qué ofrece hoy el servicio de anuncios.
@immutable
class AdsStatus {
  const new({this.rewardedReady = false, this.privacyOptionsRequired = false});

  /// Hay un anuncio recompensado cargado: se pueden mostrar sus botones.
  final bool rewardedReady;

  /// La ley pide ofrecer "Opciones de privacidad" (por ejemplo, en
  /// Europa): Ajustes muestra el botón.
  final bool privacyOptionsRequired;

  AdsStatus copyWith({bool? rewardedReady, bool? privacyOptionsRequired}) =>
      AdsStatus(
        rewardedReady: rewardedReady ?? this.rewardedReady,
        privacyOptionsRequired:
            privacyOptionsRequired ?? this.privacyOptionsRequired,
      );

  @override
  bool operator ==(Object other) =>
      other is AdsStatus &&
      other.rewardedReady == rewardedReady &&
      other.privacyOptionsRequired == privacyOptionsRequired;

  @override
  int get hashCode => Object.hash(rewardedReady, privacyOptionsRequired);
}

/// Los anuncios, detrás de una interfaz (como el audio): el juego pide "un
/// anuncio recompensado" y no sabe qué SDK hay detrás. La app usa
/// `GoogleAdsService`; los tests y cualquier compilación sin IDs de
/// anuncios, [NoAdsService].
///
/// Cuándo mostrar cada anuncio no lo decide el servicio sino `AdPolicy` y
/// las pantallas.
abstract interface class AdsService {
  /// Cambia cuando se carga un anuncio o se sabe si hacen falta las
  /// opciones de privacidad. Las pantallas lo escuchan con un
  /// `ValueListenableBuilder`.
  ValueListenable<AdsStatus> get status;

  /// Pide el consentimiento donde la ley lo exige y, si se puede, empieza a
  /// cargar anuncios. Se llama una vez al arrancar la app.
  Future<void> initialize();

  /// Muestra el anuncio recompensado. Devuelve `true` si el jugador lo vio
  /// hasta ganarse la recompensa (cerrarlo antes no la da).
  Future<bool> showRewarded();

  /// Muestra un intersticial si hay uno cargado; si no, no hace nada.
  Future<void> showInterstitial();

  /// Abre el formulario de privacidad para cambiar el consentimiento.
  Future<void> showPrivacyOptions();
}

/// Sin anuncios. Es la implementación por defecto.
class NoAdsService implements AdsService {
  @override
  final ValueListenable<AdsStatus> status = ValueNotifier(const AdsStatus());

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> showRewarded() async => false;

  @override
  Future<void> showInterstitial() async {}

  @override
  Future<void> showPrivacyOptions() async {}
}
