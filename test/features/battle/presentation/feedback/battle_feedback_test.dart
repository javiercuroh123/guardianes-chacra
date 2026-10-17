import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/core/events/event_bus.dart';
import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:guardianes_chacra/core/services/audio_service.dart';
import 'package:guardianes_chacra/features/battle/domain/events/sim_events.dart';
import 'package:guardianes_chacra/features/battle/presentation/feedback/battle_feedback.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';

import '../../../../helpers/fake_audio_service.dart';

void main() {
  const rey = PestDef(
    id: 'rey',
    maxHealth: 600,
    speed: 0.5,
    cornReward: 50,
    potatoDamage: 8,
    tags: {PestTag.ground},
    boss: true,
  );
  const gorgojo = PestDef(
    id: 'gorgojo',
    maxHealth: 30,
    speed: 1,
    cornReward: 4,
    potatoDamage: 1,
    tags: {PestTag.ground},
  );

  late EventBus<SimEvent> events;
  late FakeAudioService audio;
  late List<Haptic> vibrations;
  var vibration = true;
  var now = Duration.zero;

  setUp(() {
    events = EventBus();
    audio = FakeAudioService();
    vibrations = [];
    vibration = true;
    now = Duration.zero;
    BattleFeedback(
      events: events,
      audio: audio,
      pests: {'rey': rey, 'gorgojo': gorgojo},
      vibrationEnabled: () => vibration,
      vibrate: vibrations.add,
      music: 'music/valle.wav',
      now: () => now,
    );
  });

  void fired(int tick) => events.publish(
    GuardianFired(tick, guardianId: 1, pestId: 1, projectileId: tick),
  );

  test('empieza la música del nivel', () {
    expect(audio.music, ['music/valle.wav']);
  });

  test('cada evento suena con su efecto', () {
    events
      ..publish(const AreaPulsed(1, guardianId: 1))
      ..publish(
        const ProjectileImpacted(1, projectileId: 1, position: Vec2(0, 0)),
      )
      ..publish(
        const PestDefeated(1, pestId: 1, pestType: 'gorgojo', reward: 4),
      )
      ..publish(
        const CollcaDamaged(1, pestId: 2, potatoesLost: 1, potatoesLeft: 19),
      );

    expect(audio.sfx, [
      Sfx.shot,
      Sfx.impact,
      Sfx.pestDefeated,
      Sfx.collcaDamaged,
    ]);
  });

  test('una ráfaga de disparos suena una vez cada 70 ms', () {
    for (var tick = 0; tick < 10; tick++) {
      fired(tick);
    }
    expect(audio.sfx, [Sfx.shot]);

    now = const Duration(milliseconds: 70);
    fired(11);
    expect(audio.sfx, [Sfx.shot, Sfx.shot]);
  });

  test('el jefe suena y vibra siempre; una plaga común, no', () {
    events
      ..publish(
        const PestSpawned(1, pestId: 1, pestType: 'gorgojo', pathId: 'a'),
      )
      ..publish(const PestSpawned(1, pestId: 2, pestType: 'rey', pathId: 'a'));

    expect(audio.sfx, [Sfx.boss]);
    expect(vibrations, [Haptic.boss]);
  });

  test('al ganar o perder se corta la música y suena el final', () {
    events.publish(const LevelWon(100, potatoesLeft: 20));

    expect(audio.music, ['music/valle.wav', null]);
    expect(audio.sfx, [Sfx.victory]);
  });

  test('la collca vibra solo con la vibración encendida', () {
    events.publish(
      const CollcaDamaged(1, pestId: 1, potatoesLost: 1, potatoesLeft: 19),
    );
    expect(vibrations, [Haptic.collcaDamaged]);

    vibration = false;
    now = const Duration(seconds: 1);
    events.publish(
      const CollcaDamaged(2, pestId: 2, potatoesLost: 1, potatoesLeft: 18),
    );
    expect(vibrations, [Haptic.collcaDamaged]);
  });
}
