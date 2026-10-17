import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/core/services/analytics_service.dart';

/// La analítica de la app. Por defecto, ninguna; `main.dart` pone
/// `DebugAnalyticsService` fuera de release.
final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => NoAnalyticsService(),
);
