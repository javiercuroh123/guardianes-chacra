import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/app/app.dart';
import 'package:guardianes_chacra/app/audio.dart';
import 'package:guardianes_chacra/features/menu/presentation/title_screen.dart';
import 'package:guardianes_chacra/features/settings/presentation/settings_providers.dart';

import '../helpers/fake_audio_service.dart';
import '../helpers/real_content.dart';
import '../helpers/test_app.dart';

void main() {
  final content = useRealContent();

  Future<FakeAudioService> pumpApp(WidgetTester tester) async {
    final audio = FakeAudioService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioServiceProvider.overrideWithValue(audio),
          contentOverride(content()),
        ],
        child: const GuardianesApp(),
      ),
    );
    await tester.pumpAndSettle();
    return audio;
  }

  testWidgets('con el contenido cargado, prepara los sonidos y toca la '
      'música del menú', (tester) async {
    final audio = await pumpApp(tester);

    expect(audio.preloadedSfx, content().audio.sfx);
    expect(audio.preloadedMusic, ['music/menu.wav', 'music/batalla.wav']);
    expect(audio.music, ['music/menu.wav']);
  });

  testWidgets('los interruptores de Ajustes encienden y apagan el audio', (
    tester,
  ) async {
    final audio = await pumpApp(tester);
    expect((audio.musicOn, audio.effectsOn), (true, true));

    containerOf(tester, TitleScreen).read(settingsProvider.notifier)
      ..music = false
      ..effects = false;
    await tester.pump();

    expect((audio.musicOn, audio.effectsOn), (false, false));
  });
}
