import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/core/services/ads_service.dart';
import 'package:guardianes_chacra/features/ads/domain/ad_policy.dart';

/// Los anuncios de la app. Por defecto, ninguno; `main.dart` pone los reales
/// (`GoogleAdsService`) si esta compilación tiene IDs de anuncios.
final adsServiceProvider = Provider<AdsService>((ref) => NoAdsService());

/// Cuenta las partidas terminadas para decidir los intersticiales. Vive
/// mientras la app está abierta (no se guarda: al volver a abrirla, la
/// cuenta empieza de nuevo).
final adPolicyProvider = Provider<AdPolicy>((ref) => AdPolicy());
