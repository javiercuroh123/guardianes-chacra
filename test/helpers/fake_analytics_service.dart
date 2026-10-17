import 'package:guardianes_chacra/core/services/analytics_service.dart';

/// Anota los eventos, para comprobarlos en los tests.
class FakeAnalyticsService implements AnalyticsService {
  final List<(String, Map<String, Object>)> events = [];

  List<String> get names => [for (final (name, _) in events) name];

  Map<String, Object> last(String name) =>
      events.lastWhere((event) => event.$1 == name).$2;

  @override
  void log(String event, Map<String, Object> parameters) =>
      events.add((event, parameters));
}
