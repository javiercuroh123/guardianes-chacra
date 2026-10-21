import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/app/curtain_route.dart';
import 'package:guardianes_chacra/app/rive/rive_button.dart';
import 'package:guardianes_chacra/app/rive/rive_counter.dart';
import 'package:guardianes_chacra/app/rive/rive_icons.dart';
import 'package:guardianes_chacra/app/rive/rive_level_node.dart';
import 'package:guardianes_chacra/app/rive/rive_level_scene.dart';
import 'package:guardianes_chacra/app/rive/rive_panel.dart';
import 'package:guardianes_chacra/app/rive/rive_star.dart';
import 'package:guardianes_chacra/app/rive/rive_title_sign.dart';
import 'package:guardianes_chacra/app/rive/rive_tooltip.dart';
import 'package:guardianes_chacra/app/rive/rive_valley.dart';
import 'package:guardianes_chacra/app/ui_feedback.dart';
import 'package:guardianes_chacra/dev/dev_options.dart';
import 'package:guardianes_chacra/features/content/domain/content_texts.dart';
import 'package:guardianes_chacra/features/content/domain/game_content.dart';
import 'package:guardianes_chacra/features/content/domain/level_def.dart';
import 'package:guardianes_chacra/features/content/presentation/content_providers.dart';
import 'package:guardianes_chacra/features/level_select/presentation/level_preview_screen.dart';
import 'package:guardianes_chacra/features/level_select/presentation/valley_layout.dart';
import 'package:guardianes_chacra/features/level_select/presentation/valley_reveal.dart';
import 'package:guardianes_chacra/features/progress/domain/progress.dart';
import 'package:guardianes_chacra/features/progress/domain/progression.dart';
import 'package:guardianes_chacra/features/progress/presentation/progress_providers.dart';
import 'package:guardianes_chacra/l10n/app_localizations.dart';
import 'package:rive/rive.dart' as rive;

/// Selección de nivel como un mapa del valle: cada nivel es un nodo sobre
/// el dibujo del título, con sus mejores estrellas o un candado, unidos
/// por un camino de piedritas. Abajo, el nivel sugerido y Jugar.
class LevelSelectScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: RiveValley.sky,
      body: switch (ref.watch(gameContentProvider)) {
        AsyncData(:final value) => _Valley(
          content: value,
          progress: ref.watch(progressProvider),
          unlockAll:
              devToolsEnabled &&
              ref.watch(devOptionsProvider.select((dev) => dev.unlockAll)),
        ),
        AsyncError(:final error) => Stack(
          children: [
            Center(child: Text(l10n.contentLoadError('$error'))),
            const SafeArea(minimum: EdgeInsets.all(8), child: _BackButton()),
          ],
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Valley extends ConsumerStatefulWidget {
  const new({
    required this.content,
    required this.progress,
    this.unlockAll = false,
  });

  final GameContent content;
  final Progress progress;

  /// Opción de desarrollo: todos los niveles abiertos.
  final bool unlockAll;

  @override
  ConsumerState<_Valley> createState() => _ValleyState();
}

class _ValleyState extends ConsumerState<_Valley>
    with SingleTickerProviderStateMixin {
  /// El camino hasta un nivel recién abierto se dibuja en este tiempo y
  /// después el candado salta.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..addStatusListener(_onRevealStatus);

  /// Los niveles cuyo camino se está dibujando (siguen con candado).
  Set<String> _revealing = const {};

  /// Cuántas veces se sacudió o se abrió cada nodo (cada aumento dispara
  /// la animación).
  final _shakes = <String, int>{};
  final _unlocks = <String, int>{};

  /// El globo con la regla de un nivel cerrado.
  String? _bubbleLevel;
  bool _bubbleVisible = false;
  Timer? _bubbleTimer;

  @override
  void dispose() {
    _reveal.dispose();
    _bubbleTimer?.cancel();
    super.dispose();
  }

  /// Si el valle está a la vista y hay niveles recién abiertos, dibuja el
  /// camino hasta ellos (después del cuadro: no se cambia un provider
  /// mientras se construye).
  void _maybeReveal({required bool visible}) {
    if (!visible || _revealing.isNotEmpty) return;
    if (ref.read(valleyRevealProvider).isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _revealing.isNotEmpty) return;
      final pending = ref.read(valleyRevealProvider);
      if (pending.isEmpty) return;
      ref.read(valleyRevealProvider.notifier).clear();
      // Con menos movimiento, el camino ya aparece hecho.
      if (MediaQuery.disableAnimationsOf(context)) return;
      final known = {for (final level in widget.content.levels) level.id};
      final reveal = pending.where(known.contains).toSet();
      if (reveal.isEmpty) return;
      setState(() => _revealing = reveal);
      _reveal.forward(from: 0);
    });
  }

  void _onRevealStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    setState(() {
      for (final id in _revealing) {
        _unlocks[id] = (_unlocks[id] ?? 0) + 1;
      }
      _revealing = const {};
    });
    ref.read(uiFeedbackProvider).star();
  }

  void _showBubble(String levelId) {
    _bubbleTimer?.cancel();
    ref.read(uiFeedbackProvider).deny();
    setState(() {
      _bubbleLevel = levelId;
      _bubbleVisible = true;
      _shakes[levelId] = (_shakes[levelId] ?? 0) + 1;
    });
    _bubbleTimer = Timer(const Duration(seconds: 3), _hideBubble);
  }

  void _hideBubble() {
    _bubbleTimer?.cancel();
    if (!_bubbleVisible) return;
    setState(() => _bubbleVisible = false);
    // Lo saca del todo cuando termina de desvanecerse.
    _bubbleTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _bubbleLevel = null);
    });
  }

  void _open(String levelId) {
    _bubbleTimer?.cancel();
    setState(() {
      _bubbleLevel = null;
      _bubbleVisible = false;
    });
    Navigator.of(context).push(
      CurtainRoute<void>(builder: (_) => LevelPreviewScreen(levelId: levelId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final content = widget.content;
    final progress = widget.progress;
    final levels = content.levels;
    final progression = Progression.of(content);
    ref.watch(valleyRevealProvider);
    _maybeReveal(visible: ModalRoute.of(context)?.isCurrent ?? true);

    String levelName(String id) =>
        content.texts.text(ContentTexts.levelName(id), language: language);
    bool canPlay(LevelDef level) =>
        widget.unlockAll || progression.canPlay(progress, level.id);
    final suggested = progression.suggested(
      progress,
      unlockAll: widget.unlockAll,
    );

    /// Qué le falta a un nivel cerrado, según su regla.
    String lockedMessage(LevelDef level) {
      final after = level.unlock.afterLevel;
      final stars = level.unlock.totalStars;
      final have = progress.totalStars;
      return switch ((after, stars)) {
        (final after?, 0) => l10n.valleyLockedLevel(levelName(after)),
        (null, _) => l10n.valleyLockedStars(stars, have),
        (final after?, _) => l10n.valleyLockedBoth(
          levelName(after),
          stars,
          have,
        ),
      };
    }

    LevelNodeState stateOf(LevelDef level) {
      if (!canPlay(level) || _revealing.contains(level.id)) {
        return LevelNodeState.locked;
      }
      return level.id == suggested
          ? LevelNodeState.chosen
          : LevelNodeState.available;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final frame = ValleyFrame.of(size);
        final centers = [
          for (final anchor in valleyAnchorsFor([
            for (final level in levels) level.id,
          ]))
            frame.toScreen(anchor),
        ];
        final nodeWidth = (size.width * 0.155).clamp(112.0, 150.0);
        final nodeHeight = nodeWidth * LevelNodeRive.aspect;
        final circleTop = nodeWidth * 0.26;

        return GestureDetector(
          // Tocar el mapa fuera de un nivel cierra el globo.
          behavior: HitTestBehavior.translucent,
          // No es un control: TalkBack no lo ve.
          excludeFromSemantics: true,
          onTap: _hideBubble,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RiveValley(
                fit: frame.cover ? rive.Fit.cover : rive.Fit.fitWidth,
                alignment: frame.cover
                    ? Alignment.center
                    : Alignment.bottomCenter,
              ),
              AnimatedBuilder(
                animation: _reveal,
                builder: (context, _) => CustomPaint(
                  painter: _TrailPainter(
                    scale: frame.scale,
                    segments: [
                      for (var i = 1; i < levels.length; i++)
                        if (canPlay(levels[i]))
                          (
                            from: centers[i - 1],
                            to: centers[i],
                            progress: _revealing.contains(levels[i].id)
                                ? _reveal.value
                                : 1.0,
                          ),
                    ],
                  ),
                ),
              ),
              for (final (index, level) in levels.indexed)
                Positioned(
                  left: centers[index].dx - nodeWidth / 2,
                  top:
                      centers[index].dy -
                      nodeHeight * LevelNodeRive.circleCenter.dy,
                  child: _NodeButton(
                    key: ValueKey('level-${level.id}'),
                    semanticsLabel: canPlay(level)
                        ? l10n.valleyLevelSemantics(
                            levelName(level.id),
                            progress.starsOf(level.id),
                          )
                        : l10n.valleyLockedSemantics(levelName(level.id)),
                    unlocked: canPlay(level),
                    onTap: canPlay(level)
                        ? () => _open(level.id)
                        : () => _showBubble(level.id),
                    child: RiveLevelNode(
                      number: index + 1,
                      name: levelName(level.id),
                      stars: progress.starsOf(level.id),
                      state: stateOf(level),
                      shakes: _shakes[level.id] ?? 0,
                      unlocks: _unlocks[level.id] ?? 0,
                      width: nodeWidth,
                    ),
                  ),
                ),
              if (_bubbleLevel case final id?)
                if (levels.indexWhere((level) => level.id == id)
                    case final index when index >= 0)
                  _bubble(
                    text: lockedMessage(levels[index]),
                    anchor: centers[index] - Offset(0, circleTop),
                    screen: size,
                  ),
              SafeArea(
                minimum: const EdgeInsets.all(8),
                child: _TopBar(
                  stars: progress.totalStars,
                  maxStars: 3 * levels.length,
                ),
              ),
              if (suggested != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    top: false,
                    minimum: const EdgeInsets.only(bottom: 6),
                    // Con letra grande se achica en vez de tapar los niveles.
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: size.width - 16,
                        maxHeight: size.height * 0.27,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _SuggestedBar(
                          levelId: suggested,
                          name: levelName(suggested),
                          stars: progress.starsOf(suggested),
                          onPlay: () => _open(suggested),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// El globo sobre el círculo de un nivel cerrado ([anchor], la punta de
  /// la flecha), sin salirse de la pantalla.
  Widget _bubble({
    required String text,
    required Offset anchor,
    required Size screen,
  }) {
    const maxWidth = 220.0;
    final bubble =
        RiveTooltip.sizeFor(text, maxWidth) *
        MediaQuery.textScalerOf(context).scale(1);
    final left = (anchor.dx - bubble.width / 2).clamp(
      8.0,
      screen.width - bubble.width - 8,
    );
    return Positioned(
      left: left,
      top: anchor.dy - bubble.height,
      child: RiveTooltip(
        text: text,
        visible: _bubbleVisible,
        maxWidth: maxWidth,
      ),
    );
  }
}

/// Un nivel tocable: lleva a su vista previa o, cerrado, muestra la regla.
class _NodeButton extends StatelessWidget {
  const new({
    required this.semanticsLabel,
    required this.unlocked,
    required this.onTap,
    required this.child,
    super.key,
  });

  final String semanticsLabel;
  final bool unlocked;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: unlocked,
    label: semanticsLabel,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    ),
  );
}

/// Volver (redondo, de madera), el cartel "El valle" y las estrellas
/// juntadas.
class _TopBar extends StatelessWidget {
  const new({required this.stars, required this.maxStars});

  final int stars;
  final int maxStars;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = GameColors.of(context);
    return Stack(
      children: [
        const Align(alignment: Alignment.topLeft, child: _BackButton()),
        Align(
          alignment: Alignment.topCenter,
          child: RiveTitleSign(title: l10n.valleyTitle, width: 220),
        ),
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            // Su propio nodo para TalkBack (si no, se mezcla con el cartel).
            child: Semantics(
              container: true,
              child: RiveCounter(
                key: const ValueKey('valley-stars'),
                value: stars,
                max: maxStars,
                icon: RiveIcon.star,
                semanticsLabel: l10n.valleyStarsSemantics(stars, maxStars),
                fallback: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.hud,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Text(
                      '⭐ $stars/$maxStars',
                      style: TextStyle(
                        color: colors.onHud,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => RiveButton.round(
    key: const ValueKey('valley-back'),
    label: AppLocalizations.of(context).back,
    icon: RiveIcon.back,
    onPressed: () => Navigator.of(context).maybePop(),
  );
}

/// La barra de abajo: la ilustración, el nombre y las estrellas del nivel
/// sugerido (el del anillo) y Jugar, que lleva a su vista previa.
class _SuggestedBar extends StatelessWidget {
  const new({
    required this.levelId,
    required this.name,
    required this.stars,
    required this.onPlay,
  });

  final String levelId;
  final String name;
  final int stars;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = GameColors.of(context);
    return RivePanel(
      padding: const EdgeInsets.fromLTRB(26, 18, 26, 18),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RiveLevelScene(levelId: levelId, width: 88),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.onHud,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Semantics(
                  label: l10n.starsSemantics(stars),
                  excludeSemantics: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 3; i++)
                        RiveStar(filled: i < stars, size: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          RiveButton(
            key: const ValueKey('valley-play'),
            label: l10n.titlePlay,
            icon: RiveIcon.play,
            onPressed: onPlay,
          ),
        ],
      ),
    );
  }
}

/// El camino de piedritas entre los niveles abiertos: una curva que baja
/// un poco entre cada par de círculos, con una piedra cada tanto. Con
/// `progress` menor que 1 se ven solo las primeras (el camino se está
/// dibujando) y la de la punta crece con un rebote.
class _TrailPainter extends CustomPainter {
  new({required this.segments, required this.scale});

  final List<({Offset from, Offset to, double progress})> segments;

  /// La escala del valle (las piedras crecen con el dibujo).
  final double scale;

  static const _fill = Color(0xFFF3E0B5);
  static const _edge = Color(0xFF4A1302);
  static const _shadow = Color(0x33000000);

  @override
  void paint(Canvas canvas, Size size) {
    final spacing = 15 * scale;
    final stone = const Size(11, 7) * scale;
    // Bajo el círculo no se verían: empiezan y terminan a un radio.
    final margin = 40 * scale;
    final fill = Paint()..color = _fill;
    final shadow = Paint()..color = _shadow;
    final edge = Paint()
      ..color = _edge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (final segment in segments) {
      if (segment.progress <= 0) continue;
      final (:from, :to, :progress) = segment;
      final dip = (to - from).distance * 0.12;
      final control = (from + to) / 2 + Offset(0, dip);
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);
      final metric = path.computeMetrics().first;
      final usable = metric.length - 2 * margin;
      if (usable <= 0) continue;
      final count = math.max(1, (usable / spacing).floor());
      final front = margin + usable * progress;
      for (var i = 0; i <= count; i++) {
        final at = margin + usable * i / count;
        if (at > front + 0.01) break;
        final grow = progress >= 1
            ? 1.0
            : Curves.easeOutBack.transform(
                ((front - at) / (spacing * 2)).clamp(0.0, 1.0),
              );
        final tangent = metric.getTangentForOffset(at)!;
        final rect = Rect.fromCenter(
          center: Offset.zero,
          width: stone.width * grow,
          height: stone.height * grow,
        );
        canvas
          ..save()
          ..translate(tangent.position.dx, tangent.position.dy)
          ..rotate(-tangent.angle)
          ..drawOval(rect.shift(Offset(0, 1.5 * scale)), shadow)
          ..drawOval(rect, fill)
          ..drawOval(rect, edge)
          ..restore();
      }
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.scale != scale ||
      old.segments.length != segments.length ||
      !_same(old.segments, segments);

  static bool _same(
    List<({Offset from, Offset to, double progress})> a,
    List<({Offset from, Offset to, double progress})> b,
  ) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
