import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/app/rive/rive_button.dart';
import 'package:guardianes_chacra/app/rive/rive_collca.dart';
import 'package:guardianes_chacra/app/rive/rive_corn_rain.dart';
import 'package:guardianes_chacra/app/rive/rive_icons.dart';
import 'package:guardianes_chacra/app/rive/rive_llama.dart';
import 'package:guardianes_chacra/app/rive/rive_panel.dart';
import 'package:guardianes_chacra/app/rive/rive_scene_sign.dart';
import 'package:guardianes_chacra/app/rive/rive_star.dart';
import 'package:guardianes_chacra/app/rive/rive_stat_pill.dart';
import 'package:guardianes_chacra/app/rive/rive_unlock_card.dart';
import 'package:guardianes_chacra/app/ui_feedback.dart';
import 'package:guardianes_chacra/l10n/app_localizations.dart';

/// Nombres de los overlays de Flame de la partida (ver
/// `GameWidget.overlayBuilderMap` en `BattleScreen`).
abstract final class BattleOverlays {
  static const pause = 'pause';
  static const won = 'won';
  static const lost = 'lost';
}

/// Cuándo se pueden tocar los botones de una escena: al terminar de caer
/// el panel, nunca después de 300 ms.
const _buttonsAfter = Duration(milliseconds: 280);

class PauseOverlay extends StatelessWidget {
  const new({
    required this.onResume,
    required this.onRetry,
    required this.onExit,
    super.key,
  });

  final VoidCallback onResume;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SceneFrame(
      child: _Scene(
        title: l10n.hudPause,
        variant: SceneSignVariant.pause,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Subtitle(l10n.pauseSubtitle),
            const SizedBox(height: 12),
            _DelayedButtons(
              // Continuar ocupa el ancho de los otros dos juntos.
              child: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RiveButton(
                      key: const ValueKey('pause-resume'),
                      label: l10n.pauseResume,
                      icon: RiveIcon.play,
                      onPressed: onResume,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RiveButton(
                          key: const ValueKey('battle-retry'),
                          kind: RiveButtonKind.secondary,
                          label: l10n.battleRetry,
                          icon: RiveIcon.retry,
                          onPressed: onRetry,
                        ),
                        const SizedBox(width: 10),
                        RiveButton(
                          key: const ValueKey('battle-exit'),
                          kind: RiveButtonKind.secondary,
                          danger: true,
                          label: l10n.pauseExit,
                          icon: RiveIcon.home,
                          onPressed: onExit,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Algo que abrió una victoria: un nivel o un guardián.
class UnlockedItem {
  const new level({
    required String this.levelId,
    required this.name,
    required this.color,
  }) : guardianId = null;

  const new guardian({
    required String this.guardianId,
    required this.name,
    required this.color,
  }) : levelId = null;

  final String name;

  /// `null` si es un nivel.
  final String? guardianId;

  /// `null` si es un guardián.
  final String? levelId;

  /// Para el respaldo sin Rive.
  final Color color;
}

/// Los momentos de la coreografía de la victoria, en milisegundos desde
/// que aparece: el cartel cae, se llenan las estrellas una a una, cuentan
/// las papas y el maíz, entran los desbloqueos y al final llueve maíz y la
/// llama festeja. Los botones se pueden tocar desde [buttonsAt].
class VictoryTimeline {
  const new({required this.stars, required this.unlocks});

  final int stars;

  /// Cuántas tarjetas de desbloqueo se muestran (hasta dos).
  final int unlocks;

  static const buttonsAt = 280;

  /// La primera estrella, con el panel ya abajo.
  static const firstStarAt = 520;
  static const starGap = 380;
  static const countDuration = 700;
  static const unlockGap = 260;

  int starAt(int index) => firstStarAt + index * starGap;

  /// El conteo empieza un poco después de la última estrella.
  int get countAt => (stars == 0 ? firstStarAt : starAt(stars - 1)) + 460;
  int get countEnd => countAt + countDuration;
  int unlockAt(int index) => countEnd + 200 + index * unlockGap;

  /// La lluvia y el salto de la llama.
  int get finaleAt =>
      unlocks == 0 ? countEnd + 150 : unlockAt(unlocks - 1) + 300;

  int get total => finaleAt;

  int starsAt(int ms) => [
    for (var i = 0; i < stars; i++)
      if (ms >= starAt(i)) i,
  ].length;

  double countProgressAt(int ms) =>
      ((ms - countAt) / countDuration).clamp(0, 1);

  int unlocksAt(int ms) => [
    for (var i = 0; i < unlocks; i++)
      if (ms >= unlockAt(i)) i,
  ].length;
}

class VictoryOverlay extends ConsumerStatefulWidget {
  const new({
    required this.stars,
    required this.potatoes,
    required this.maxPotatoes,
    required this.cornHarvested,
    required this.onRetry,
    required this.onExit,
    this.unlocked = const [],
    this.onNext,
    super.key,
  });

  /// Lo que abrió esta victoria (se muestran los dos primeros).
  final List<UnlockedItem> unlocked;

  final int stars;
  final int potatoes;
  final int maxPotatoes;
  final int cornHarvested;

  /// `null` en el último nivel.
  final VoidCallback? onNext;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  @override
  ConsumerState<VictoryOverlay> createState() => _VictoryOverlayState();
}

class _VictoryOverlayState extends ConsumerState<VictoryOverlay>
    with SingleTickerProviderStateMixin {
  late final VictoryTimeline _timeline = VictoryTimeline(
    stars: widget.stars,
    unlocks: math.min(widget.unlocked.length, 2),
  );
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _timeline.total),
  )..addListener(_tick);

  /// Lo que se ve ahora. Solo cambia cuando cambia algo visible.
  int _stars = 0;
  double _count = 0;
  int _unlocks = 0;
  bool _buttons = false;
  bool _finale = false;

  /// Se saltó la coreografía (un toque, o menos movimiento): lo que falta
  /// aparece de golpe y sin sonido.
  bool _skipped = false;

  @override
  void initState() {
    super.initState();
    _clock.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _skip();
  }

  void _tick() {
    final ms = (_clock.value * _timeline.total).round();
    final stars = _timeline.starsAt(ms);
    final count = _timeline.countProgressAt(ms);
    final unlocks = _timeline.unlocksAt(ms);
    final buttons = _skipped || ms >= VictoryTimeline.buttonsAt;
    final finale = ms >= _timeline.finaleAt;
    if (!_skipped) {
      // Una estrella nueva suena y vibra (dos en el mismo cuadro, una vez).
      if (stars > _stars) ref.read(uiFeedbackProvider).star();
    }
    if (stars == _stars &&
        count == _count &&
        unlocks == _unlocks &&
        buttons == _buttons &&
        finale == _finale) {
      return;
    }
    setState(() {
      _stars = stars;
      _count = count;
      _unlocks = unlocks;
      _buttons = buttons;
      _finale = finale;
    });
  }

  void _skip() {
    if (_skipped || _clock.isCompleted) return;
    _skipped = true;
    _clock.value = 1;
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onNext = widget.onNext;
    final potatoes = (widget.potatoes * _count).round();
    final corn = (widget.cornHarvested * _count).round();
    final pops = _count == 1 ? 1 : 0;
    final unlocked = widget.unlocked.take(2).toList();
    // Con menos movimiento la llama no salta (la lluvia ya no cae en Rive).
    final celebrate = _finale && !MediaQuery.disableAnimationsOf(context);
    return _SceneFrame(
      // Un toque en cualquier parte (menos en un botón) lleva al final.
      onTap: _skip,
      child: _WithLlama(
        llama: RiveLlama(
          mood: LlamaMood.happy,
          celebrations: celebrate ? 1 : 0,
          height: _WithLlama.llamaHeight,
        ),
        // Dos mitades (la segunda, espejada): una sola estirada a todo el
        // ancho dejaría los granos enormes.
        rain: Row(
          children: [
            Expanded(child: RiveCornRain(showers: _finale ? 1 : 0)),
            Expanded(
              child: Transform.flip(
                flipX: true,
                child: RiveCornRain(showers: _finale ? 1 : 0),
              ),
            ),
          ],
        ),
        child: _Scene(
          title: l10n.battleWon,
          variant: SceneSignVariant.victory,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: l10n.starsSemantics(widget.stars),
                excludeSemantics: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: RiveStar(filled: i < _stars, size: 64),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RiveStatPill(
                    icon: RiveIcon.potato,
                    label: l10n.resultPotatoes,
                    value: '$potatoes/${widget.maxPotatoes}',
                    pops: pops,
                  ),
                  const SizedBox(width: 12),
                  RiveStatPill(
                    icon: RiveIcon.corn,
                    label: l10n.resultCorn,
                    value: '$corn',
                    pops: pops,
                  ),
                ],
              ),
              if (unlocked.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  key: const ValueKey('victory-unlocked'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (index, item) in unlocked.indexed) ...[
                      if (index > 0) const SizedBox(width: 12),
                      RiveUnlockCard(
                        label: l10n.unlockedLabel,
                        name: item.name,
                        guardianId: item.guardianId,
                        levelId: item.levelId,
                        color: item.color,
                        shown: index < _unlocks,
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 6),
              _DelayedButtons(
                ready: _buttons,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // En el último nivel, volver al valle es la principal.
                    RiveButton(
                      key: const ValueKey('battle-exit'),
                      kind: onNext == null
                          ? RiveButtonKind.primary
                          : RiveButtonKind.secondary,
                      label: l10n.toValley,
                      icon: RiveIcon.home,
                      tapPadding: _resultTapPadding,
                      onPressed: widget.onExit,
                    ),
                    const SizedBox(width: 10),
                    RiveButton(
                      key: const ValueKey('battle-retry'),
                      kind: RiveButtonKind.secondary,
                      label: l10n.battleRetry,
                      icon: RiveIcon.retry,
                      tapPadding: _resultTapPadding,
                      onPressed: widget.onRetry,
                    ),
                    if (onNext != null) ...[
                      const SizedBox(width: 10),
                      RiveButton(
                        key: const ValueKey('victory-next'),
                        label: l10n.victoryNext,
                        icon: RiveIcon.play,
                        tapPadding: _resultTapPadding,
                        onPressed: onNext,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DefeatOverlay extends StatelessWidget {
  const new({
    required this.onRetry,
    required this.onExit,
    required this.potatoes,
    required this.maxPotatoes,
    this.onRevive,
    this.revivePotatoes = 0,
    super.key,
  });

  final VoidCallback onRetry;
  final VoidCallback onExit;

  /// Las papas que quedaron (en una derrota, 0) y las del comienzo.
  final int potatoes;
  final int maxPotatoes;

  /// Ver un anuncio para seguir con [revivePotatoes] papas. Sin él (no hay
  /// anuncio cargado o ya se revivió), no hay botón.
  final VoidCallback? onRevive;
  final int revivePotatoes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onRevive = this.onRevive;
    return _SceneFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Shake(
            child: _Scene(
              title: l10n.battleLost,
              variant: SceneSignVariant.defeat,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // La llama triste junto a la collca vacía.
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const RiveLlama(mood: LlamaMood.sad, height: 180),
                      Transform.translate(
                        offset: const Offset(-32, 0),
                        child: const RiveCollca(size: 120),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  _DelayedButtons(
                    child: IntrinsicWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: RiveStatPill(
                              icon: RiveIcon.potato,
                              label: l10n.resultPotatoes,
                              value: '$potatoes/$maxPotatoes',
                              scale: 0.85,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 240,
                            child: _Subtitle(l10n.defeatHint),
                          ),
                          const SizedBox(height: 4),
                          RiveButton(
                            key: const ValueKey('battle-retry'),
                            label: l10n.battleRetry,
                            icon: RiveIcon.retry,
                            tapPadding: _resultTapPadding,
                            onPressed: onRetry,
                          ),
                          RiveButton(
                            key: const ValueKey('battle-exit'),
                            kind: RiveButtonKind.secondary,
                            label: l10n.toValley,
                            icon: RiveIcon.home,
                            tapPadding: _resultTapPadding,
                            onPressed: onExit,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (onRevive != null)
            // Apoyado sobre el borde de abajo del panel.
            Transform.translate(
              offset: const Offset(0, -20),
              child: _DelayedButtons(
                child: RiveButton(
                  key: const ValueKey('battle-revive'),
                  kind: RiveButtonKind.secondary,
                  label: l10n.adRevive(revivePotatoes),
                  icon: RiveIcon.ad,
                  tapPadding: _resultTapPadding,
                  onPressed: onRevive,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// El velo sobre la partida, que se oscurece en 250 ms, con [child] al
/// centro. Si no entra en la pantalla (letra grande, teléfonos bajos), se
/// achica entero en vez de cortarse. [onTap] recibe los toques fuera de
/// los botones.
class _SceneFrame extends StatelessWidget {
  const new({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scrim = GameColors.of(context).overlayScrim;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 250),
        builder: (context, value, child) => ColoredBox(
          color: scrim.withValues(alpha: scrim.a * value),
          child: child,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: FittedBox(fit: BoxFit.scaleDown, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// El panel que cae con el cartel de [title] apoyado en su borde de
/// arriba.
class _Scene extends StatelessWidget {
  const new({required this.title, required this.variant, required this.child});

  final String title;
  final SceneSignVariant variant;
  final Widget child;

  /// Ancho del cartel a escala de letra 1.
  static const double signWidth = 340;

  @override
  Widget build(BuildContext context) {
    final signHeight =
        MediaQuery.textScalerOf(context).scale(signWidth) *
        RiveSceneSign.aspect;
    final above = signHeight * RiveSceneSign.panelTop;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: EdgeInsets.only(top: above),
          child: RivePanel(
            padding: EdgeInsets.fromLTRB(26, signHeight - above + 8, 26, 22),
            child: child,
          ),
        ),
        RiveSceneSign(title: title, variant: variant, width: signWidth),
      ],
    );
  }
}

/// La llama de la victoria parada a la izquierda del panel, tapando su
/// borde, y la lluvia de maíz encima de todo.
class _WithLlama extends StatelessWidget {
  const new({required this.llama, required this.rain, required this.child});

  final Widget llama;
  final Widget rain;
  final Widget child;

  /// Alto de la llama y lo que se mete sobre el panel.
  static const double llamaHeight = 220;
  static const double overlap = 64;

  @override
  Widget build(BuildContext context) {
    final llamaWidth =
        MediaQuery.textScalerOf(context).scale(llamaHeight) * RiveLlama.aspect;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(left: llamaWidth - overlap),
          child: child,
        ),
        Positioned(left: 0, bottom: 4, child: llama),
        Positioned.fill(child: rain),
      ],
    );
  }
}

class _Subtitle extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: Theme.of(context).textTheme.titleMedium
        ?.copyWith(fontWeight: FontWeight.w700),
  );
}

/// Los botones de una escena: aparecen cuando el panel termina de caer
/// ([_buttonsAfter]) o cuando [ready] pasa a `true`, lo que llegue
/// primero. Antes no reciben toques.
class _DelayedButtons extends StatelessWidget {
  const new({required this.child, this.ready = false});

  final Widget child;
  final bool ready;

  static const _fade = Duration(milliseconds: 140);

  @override
  Widget build(BuildContext context) {
    final total = _buttonsAfter + _fade;
    final start = _buttonsAfter.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      builder: (context, value, child) {
        final shown = ready || value >= start;
        final opacity = ready ? 1.0 : ((value - start) / (1 - start));
        return IgnorePointer(
          ignoring: !shown,
          child: Opacity(opacity: opacity.clamp(0, 1), child: child),
        );
      },
      child: child,
    );
  }
}

/// La derrota entra temblando: una sacudida de lado a lado que se apaga
/// en 600 ms. Con menos movimiento, quieta.
class _Shake extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) => Transform.translate(
        offset: Offset(10 * math.sin(value * math.pi * 8) * (1 - value), 0),
        child: child,
      ),
      child: child,
    );
  }
}

/// La zona de toque de más de los botones de la victoria y la derrota: el
/// panel se achica para entrar en el teléfono (a ~0,77) y los botones de
/// 56 dp quedarían en 43; con 6 arriba y abajo, 68 × 0,77 = 52 dp.
const _resultTapPadding = EdgeInsets.symmetric(vertical: 6);
