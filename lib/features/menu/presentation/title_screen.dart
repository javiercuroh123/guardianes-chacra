import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/app/rive/rive_button.dart';
import 'package:guardianes_chacra/app/rive/rive_icons.dart';
import 'package:guardianes_chacra/app/rive/rive_llama.dart';
import 'package:guardianes_chacra/app/rive/rive_logo.dart';
import 'package:guardianes_chacra/app/rive/rive_mascots.dart';
import 'package:guardianes_chacra/app/rive/rive_ui.dart';
import 'package:guardianes_chacra/app/rive/rive_valley.dart';
import 'package:guardianes_chacra/features/bestiary/presentation/bestiary_screen.dart';
import 'package:guardianes_chacra/features/level_select/presentation/level_select_screen.dart';
import 'package:guardianes_chacra/features/settings/presentation/settings_screen.dart';
import 'package:guardianes_chacra/l10n/app_localizations.dart';

/// Menú principal: el valle de fondo, el hondero y la llama a los lados,
/// el logo y los caminos a Jugar, Bestiario y Ajustes.
///
/// Sin el archivo de Rive, el título de siempre sobre el verde de la chacra
/// (las mascotas solo existen en Rive).
class TitleScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final withRive = ref.watch(riveFileProvider) != null;

    void open(Widget screen) =>
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => screen));

    return Scaffold(
      backgroundColor: AppTheme.chacra,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          // Las mascotas crecen con el alto, sin pasar del 30 % del ancho
          // (en tabletas 4:3 tocarían el logo).
          final mascot = math.min(height * 0.68, width * 0.3);
          final logoWidth = math.min(width * 0.42, height * 1.1);
          return Stack(
            children: [
              const Positioned.fill(child: RiveValley()),
              if (withRive) ...[
                Positioned(
                  left: width * 0.01,
                  bottom: height * 0.02,
                  child: RiveHondero(height: mascot),
                ),
                Positioned(
                  right: width * 0.01,
                  bottom: height * 0.02,
                  child: RiveLlama(
                    mood: LlamaMood.happy,
                    chewing: true,
                    height: mascot,
                  ),
                ),
                Positioned(
                  left: mascot * MascotsRive.honderoAspect * 0.85,
                  bottom: -height * 0.03,
                  child: RiveGorgojoPeek(width: width * 0.12),
                ),
                Positioned(
                  right: mascot * RiveLlama.aspect * 0.85,
                  bottom: -height * 0.03,
                  child: RiveGorgojoPeek(width: width * 0.11, mirrored: true),
                ),
              ],
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    // Con letra grande se achica entero en vez de cortarse.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RiveLogo(
                            title: l10n.appTitle,
                            lines: (
                              l10n.logoLine1,
                              l10n.logoLine2,
                              l10n.logoLine3,
                            ),
                            tagline: l10n.tagline,
                            width: logoWidth,
                          ),
                          SizedBox(height: withRive ? 6 : 28),
                          // Jugar ocupa el ancho de los otros dos juntos.
                          IntrinsicWidth(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _Breathing(
                                  enabled: withRive,
                                  child: RiveButton(
                                    key: const ValueKey('menu-play'),
                                    label: l10n.titlePlay,
                                    icon: RiveIcon.play,
                                    onPressed: () =>
                                        open(const LevelSelectScreen()),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    RiveButton(
                                      key: const ValueKey('menu-bestiary'),
                                      kind: RiveButtonKind.secondary,
                                      label: l10n.menuBestiary,
                                      icon: RiveIcon.book,
                                      onPressed: () =>
                                          open(const BestiaryScreen()),
                                    ),
                                    const SizedBox(width: 12),
                                    RiveButton(
                                      key: const ValueKey('menu-settings'),
                                      kind: RiveButtonKind.secondary,
                                      label: l10n.menuSettings,
                                      icon: RiveIcon.gear,
                                      onPressed: () =>
                                          open(const SettingsScreen()),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Jugar "respira": crece y vuelve un 4 % cada 1,4 s. Solo con el archivo
/// de Rive y sin "menos movimiento" (el respaldo queda quieto, así los
/// tests de siempre pueden esperar a que la pantalla se asiente).
class _Breathing extends StatefulWidget {
  const new({required this.child, required this.enabled});

  final Widget child;
  final bool enabled;

  @override
  State<_Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<_Breathing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1,
    end: 1.04,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _update();
  }

  @override
  void didUpdateWidget(_Breathing oldWidget) {
    super.didUpdateWidget(oldWidget);
    _update();
  }

  void _update() {
    final on = widget.enabled && !MediaQuery.disableAnimationsOf(context);
    if (on && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!on) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}
