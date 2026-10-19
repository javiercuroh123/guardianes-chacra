import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/dev/dev_options.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/simulation_cheats.dart';

/// El panel de desarrollo de la partida (debug y profile, nunca en
/// release): trucos, superposición de depuración, saltar oleada y prueba
/// de estrés.
///
/// Sus textos no van en los ARB: son para quien desarrolla, no para el
/// jugador, y no existen en la versión publicada.
class DevPanel extends ConsumerStatefulWidget {
  const new({
    required this.cheats,
    required this.onSkipWave,
    required this.onStressTest,
    super.key,
  });

  final SimulationCheats cheats;
  final VoidCallback onSkipWave;
  final VoidCallback onStressTest;

  @override
  ConsumerState<DevPanel> createState() => _DevPanelState();
}

class _DevPanelState extends ConsumerState<DevPanel> {
  @override
  Widget build(BuildContext context) {
    final options = ref.watch(devOptionsProvider);
    final cheats = widget.cheats;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Desarrollo (no existe en release)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SwitchListTile(
              dense: true,
              key: const ValueKey('dev-infinite-corn'),
              title: const Text('Maíz infinito'),
              value: cheats.infiniteCorn,
              onChanged: (on) => setState(() => cheats.infiniteCorn = on),
            ),
            SwitchListTile(
              dense: true,
              key: const ValueKey('dev-invincible'),
              title: const Text('Invencible (la collca no pierde papas)'),
              value: cheats.invincible,
              onChanged: (on) => setState(() => cheats.invincible = on),
            ),
            SwitchListTile(
              dense: true,
              key: const ValueKey('dev-overlay'),
              title: const Text('Caminos, alcances, FPS y conteos'),
              value: options.debugOverlay,
              onChanged: (on) =>
                  ref.read(devOptionsProvider.notifier).debugOverlay = on,
            ),
            // Debajo de su etiqueta y no al lado: en pantallas angostas el
            // selector no cabe junto al texto.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Prueba de Rive: contadores animándose'),
                  const SizedBox(height: 6),
                  SegmentedButton<RiveBenchMode>(
                    key: const ValueKey('dev-rive-bench'),
                    segments: [
                      for (final mode in RiveBenchMode.values)
                        ButtonSegment(
                          value: mode,
                          label: Text(switch (mode) {
                            RiveBenchMode.off => 'No',
                            RiveBenchMode.all => '${mode.count}',
                            RiveBenchMode.hud =>
                              '${mode.count} (${mode.animated} cambian)',
                          }),
                        ),
                    ],
                    selected: {options.riveBench},
                    showSelectedIcon: false,
                    onSelectionChanged: (selected) =>
                        ref.read(devOptionsProvider.notifier).riveBench =
                            selected.single,
                  ),
                ],
              ),
            ),
            SwitchListTile(
              dense: true,
              key: const ValueKey('dev-rive-shared'),
              title: const Text(
                'Prueba de Rive en una sola textura (RivePanel)',
              ),
              value: options.riveSharedTexture,
              onChanged: (on) =>
                  ref.read(devOptionsProvider.notifier).riveSharedTexture = on,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  key: const ValueKey('dev-skip-wave'),
                  onPressed: widget.onSkipWave,
                  child: const Text('Saltar oleada'),
                ),
                OutlinedButton(
                  key: const ValueKey('dev-stress'),
                  onPressed: widget.onStressTest,
                  child: const Text('Prueba de estrés (150 plagas)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
