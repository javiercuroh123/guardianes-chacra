import 'package:guardianes_chacra/core/services/haptics_service.dart';

/// Anota las vibraciones pedidas, para comprobarlas en los tests.
class FakeHapticsService implements HapticsService {
  final List<Haptic> vibrations = [];

  @override
  void vibrate(Haptic haptic) => vibrations.add(haptic);
}
