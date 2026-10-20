import 'dart:async';

import 'package:flutter/services.dart';
import 'package:guardianes_chacra/core/services/haptics_service.dart';

/// La vibración real, con `HapticFeedback` de Flutter: un golpe medio
/// cuando una plaga llega a la collca, uno fuerte cuando aparece el jefe y
/// toques leves para los botones. En teléfonos sin vibrador (o con la
/// vibración del sistema apagada) no hace nada.
class SystemHapticsService implements HapticsService {
  @override
  void vibrate(Haptic haptic) => unawaited(switch (haptic) {
    Haptic.collcaDamaged => HapticFeedback.mediumImpact(),
    Haptic.boss => HapticFeedback.heavyImpact(),
    Haptic.tap => HapticFeedback.selectionClick(),
    Haptic.deny => HapticFeedback.lightImpact(),
  });
}
