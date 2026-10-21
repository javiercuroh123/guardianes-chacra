import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/ads.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/app/curtain_route.dart';
import 'package:guardianes_chacra/app/rive/rive_button.dart';
import 'package:guardianes_chacra/app/rive/rive_icons.dart';
import 'package:guardianes_chacra/app/rive/rive_level_scene.dart';
import 'package:guardianes_chacra/app/rive/rive_panel.dart';
import 'package:guardianes_chacra/app/rive/rive_pest_card.dart';
import 'package:guardianes_chacra/app/rive/rive_stat_pill.dart';
import 'package:guardianes_chacra/app/rive/rive_title_sign.dart';
import 'package:guardianes_chacra/app/rive/rive_tooltip.dart';
import 'package:guardianes_chacra/app/rive/rive_valley.dart';
import 'package:guardianes_chacra/core/services/ads_service.dart';
import 'package:guardianes_chacra/features/battle/presentation/battle_assets.dart';
import 'package:guardianes_chacra/features/battle/presentation/battle_screen.dart';
import 'package:guardianes_chacra/features/battle/presentation/style/battle_palette.dart';
import 'package:guardianes_chacra/features/content/domain/content_texts.dart';
import 'package:guardianes_chacra/features/content/domain/game_content.dart';
import 'package:guardianes_chacra/features/content/domain/level_def.dart';
import 'package:guardianes_chacra/features/content/domain/level_pests.dart';
import 'package:guardianes_chacra/features/content/presentation/content_providers.dart';
import 'package:guardianes_chacra/features/level_select/presentation/valley_layout.dart';
import 'package:guardianes_chacra/features/progress/presentation/progress_providers.dart';
import 'package:guardianes_chacra/l10n/app_localizations.dart';
import 'package:rive/rive.dart' as rive;

/// Antes de jugar: el nombre del nivel, su ilustración, cuántas oleadas
/// tiene, con cuánto maíz y cuántas papas se empieza y las plagas que
/// vienen, en tarjetas que entran una tras otra (las que el jugador todavía
/// no vio llevan "Nueva"; el jefe, su cinta). Tocar una tarjeta muestra qué
/// hace esa plaga.
///
/// Si hay un anuncio recompensado cargado, ofrece verlo para empezar con
/// maíz extra (`rewardedStartCorn` de `ads.json`).
class LevelPreviewScreen extends ConsumerWidget {
  const new({required this.levelId, this.assets, super.key});

  final String levelId;

  /// Para los tests: se pasa a la partida (ver `BattleScreen.assets`).
  final BattleAssets? assets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: RiveValley.sky,
      body: switch (ref.watch(gameContentProvider)) {
        AsyncData(:final value) => _Preview(
          content: value,
          level: value.levels.firstWhere((level) => level.id == levelId),
          assets: assets,
        ),
        AsyncError(:final error) => Center(
          child: Text(l10n.contentLoadError('$error')),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Preview extends ConsumerStatefulWidget {
  const new({required this.content, required this.level, this.assets});

  final GameContent content;
  final LevelDef level;
  final BattleAssets? assets;

  @override
  ConsumerState<_Preview> createState() => _PreviewState();
}

class _PreviewState extends ConsumerState<_Preview>
    with SingleTickerProviderStateMixin {
  /// Entre tarjeta y tarjeta, al entrar.
  static const _cardGap = Duration(milliseconds: 90);

  late final List<String> _pests = pestsAppearingIn(widget.level);

  /// Las tarjetas entran una tras otra: este reloj dice cuántas ya.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: _cardGap * (_pests.length + 1),
  )..addListener(_onEntrance);
  int _shown = 0;

  final GlobalKey _stackKey = GlobalKey();
  late final Map<String, GlobalKey> _cardKeys = {
    for (final id in _pests) id: GlobalKey(),
  };

  /// El globo con la descripción de una plaga: su texto y la punta de la
  /// flecha (el centro de arriba de la tarjeta).
  ({String text, Offset anchor})? _bubble;
  bool _bubbleVisible = false;
  Timer? _bubbleTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else if (!_entrance.isAnimating && _entrance.value == 0) {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _bubbleTimer?.cancel();
    super.dispose();
  }

  void _onEntrance() {
    final shown = math.min(
      _pests.length,
      (_entrance.value * (_pests.length + 1)).floor(),
    );
    if (shown != _shown) setState(() => _shown = shown);
  }

  void _showBubble(String pestId, String text) {
    final card = _cardKeys[pestId]?.currentContext?.findRenderObject();
    final stack = _stackKey.currentContext?.findRenderObject();
    if (card is! RenderBox || stack is! RenderBox) return;
    final topLeft = card.localToGlobal(Offset.zero, ancestor: stack);
    _bubbleTimer?.cancel();
    setState(() {
      _bubble = (text: text, anchor: topLeft + Offset(card.size.width / 2, 2));
      _bubbleVisible = true;
    });
    _bubbleTimer = Timer(const Duration(seconds: 4), _hideBubble);
  }

  void _hideBubble() {
    _bubbleTimer?.cancel();
    if (!_bubbleVisible) return;
    setState(() => _bubbleVisible = false);
    // Lo saca del todo cuando termina de desvanecerse.
    _bubbleTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _bubble = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final content = widget.content;
    final level = widget.level;
    final discovered = ref.watch(
      progressProvider.select((progress) => progress.discoveredPests),
    );
    final ads = ref.watch(adsServiceProvider);
    final extraCorn = content.ads.rewardedStartCorn;
    String text(String key) => content.texts.text(key, language: language);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final frame = ValleyFrame.of(size);
        final sceneWidth = math.min<double>(size.width * 0.27, 240);
        return GestureDetector(
          // Tocar fuera de una tarjeta cierra el globo.
          behavior: HitTestBehavior.translucent,
          // No es un control: TalkBack no lo ve.
          excludeFromSemantics: true,
          onTap: _hideBubble,
          child: Stack(
            key: _stackKey,
            fit: StackFit.expand,
            children: [
              RiveValley(
                fit: frame.cover ? rive.Fit.cover : rive.Fit.fitWidth,
                alignment: frame.cover
                    ? Alignment.center
                    : Alignment.bottomCenter,
              ),
              SafeArea(
                minimum: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    _TopBar(
                      title: text(ContentTexts.levelName(level.id)),
                      waves: level.waves.length,
                      corn: level.startingCorn,
                      potatoes: level.startingPotatoes,
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Row(
                        children: [
                          SizedBox(
                            width: sceneWidth,
                            child: Center(
                              child: RiveLevelScene(
                                levelId: level.id,
                                width: sceneWidth,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: NotificationListener<ScrollNotification>(
                              onNotification: (_) {
                                _hideBubble();
                                return false;
                              },
                              child: _PestsPanel(
                                title: l10n.previewPests,
                                cards: [
                                  for (final (index, pestId) in _pests.indexed)
                                    _pestCard(
                                      pestId: pestId,
                                      name: text(ContentTexts.pestName(pestId)),
                                      description: text(
                                        ContentTexts.pestDescription(pestId),
                                      ),
                                      isNew: !discovered.contains(pestId),
                                      shown: index < _shown,
                                      l10n: l10n,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<AdsStatus>(
                      valueListenable: ads.status,
                      builder: (context, status, _) => _Buttons(
                        onBack: () => Navigator.of(context).maybePop(),
                        onStart: () => _start(context),
                        rewardedLabel: status.rewardedReady && extraCorn > 0
                            ? l10n.adStartCorn(extraCorn)
                            : null,
                        onRewarded: () => _startWithAd(context, ads, extraCorn),
                      ),
                    ),
                  ],
                ),
              ),
              if (_bubble case (:final text, :final anchor))
                _bubbleAt(text: text, anchor: anchor, screen: size),
            ],
          ),
        );
      },
    );
  }

  /// Una tarjeta tocable, para un ancho: su globo dice qué hace la plaga.
  Widget Function(double width) _pestCard({
    required String pestId,
    required String name,
    required String description,
    required bool isNew,
    required bool shown,
    required AppLocalizations l10n,
  }) {
    final def = widget.content.pests[pestId];
    final boss = def?.boss ?? false;
    return (width) => Semantics(
      key: ValueKey('preview-pest-$pestId'),
      container: true,
      button: true,
      label: [
        name,
        if (isNew) l10n.previewNew,
        if (boss) l10n.previewBoss,
      ].join(', '),
      excludeSemantics: true,
      child: GestureDetector(
        key: _cardKeys[pestId],
        behavior: HitTestBehavior.opaque,
        onTap: () => _showBubble(pestId, description),
        child: RivePestCard(
          pestId: pestId,
          name: name,
          color: colorFor(pestId, def?.color),
          newLabel: l10n.previewNew,
          bossLabel: l10n.previewBoss,
          isNew: isNew,
          boss: boss,
          shown: shown,
          width: width,
        ),
      ),
    );
  }

  /// El globo sobre una tarjeta ([anchor], la punta de la flecha), sin
  /// salirse de la pantalla.
  Widget _bubbleAt({
    required String text,
    required Offset anchor,
    required Size screen,
  }) {
    // El ancho máximo de siempre del globo (240).
    final bubble =
        RiveTooltip.sizeFor(text, 240) *
        MediaQuery.textScalerOf(context).scale(1);
    final left = (anchor.dx - bubble.width / 2).clamp(
      8.0,
      screen.width - bubble.width - 8,
    );
    return Positioned(
      left: left,
      top: math.max(4, anchor.dy - bubble.height),
      child: RiveTooltip(text: text, visible: _bubbleVisible),
    );
  }

  void _start(BuildContext context, {int extraCorn = 0}) =>
      Navigator.of(context).pushReplacement(
        CurtainRoute<void>(
          builder: (_) => BattleScreen(
            levelId: widget.level.id,
            assets: widget.assets,
            extraCorn: extraCorn,
          ),
        ),
      );

  /// Muestra el anuncio y, solo si se vio hasta el final, empieza con el
  /// maíz extra. Cerrado antes, avisa y se queda en la vista previa.
  Future<void> _startWithAd(
    BuildContext context,
    AdsService ads,
    int extraCorn,
  ) async {
    final earned = await ads.showRewarded();
    if (!context.mounted) return;
    if (earned) {
      _start(context, extraCorn: extraCorn);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).adNotCompleted)),
      );
    }
  }
}

/// El cartel con el nombre del nivel y, a los lados, las oleadas, el maíz
/// inicial y las papas. Con letra grande se achica entera.
class _TopBar extends StatelessWidget {
  const new({
    required this.title,
    required this.waves,
    required this.corn,
    required this.potatoes,
  });

  final String title;
  final int waves;
  final int corn;
  final int potatoes;

  static const _pillScale = 0.6;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // TalkBack lee primero el nombre del nivel y después las pastillas
    // (sin el orden, leería "Oleadas" antes que el nombre).
    Widget inOrder(int order, Widget child) => Semantics(
      container: true,
      sortKey: OrdinalSortKey(order.toDouble()),
      child: child,
    );
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Semantics(
        container: true,
        child: Row(
          children: [
            inOrder(
              1,
              RiveStatPill(
                key: const ValueKey('preview-waves'),
                icon: RiveIcon.flag,
                label: l10n.previewWavesLabel,
                value: '$waves',
                scale: _pillScale,
              ),
            ),
            const SizedBox(width: 16),
            inOrder(0, RiveTitleSign(title: title, width: 220)),
            const SizedBox(width: 16),
            inOrder(
              2,
              RiveStatPill(
                key: const ValueKey('preview-corn'),
                icon: RiveIcon.corn,
                label: l10n.previewCornLabel,
                value: '$corn',
                scale: _pillScale,
              ),
            ),
            const SizedBox(width: 8),
            inOrder(
              3,
              RiveStatPill(
                key: const ValueKey('preview-potatoes'),
                icon: RiveIcon.potato,
                label: l10n.previewPotatoesLabel,
                value: '$potatoes',
                scale: _pillScale,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Plagas que vienen" y la fila de tarjetas, que se desliza: se ven cinco
/// y asoma la sexta.
class _PestsPanel extends StatelessWidget {
  const new({required this.title, required this.cards});

  final String title;

  /// Cada tarjeta, para un ancho.
  final List<Widget Function(double width)> cards;

  static const _padding = EdgeInsets.fromLTRB(22, 14, 22, 16);
  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    final colors = GameColors.of(context);
    final titleStyle = Theme.of(context).textTheme.titleMedium
        ?.copyWith(color: colors.onHud, fontWeight: FontWeight.w800);
    return LayoutBuilder(
      builder: (context, constraints) {
        final inner = constraints.maxWidth - _padding.horizontal;
        // Lo que mide el título de verdad (con la letra del teléfono).
        final titlePainter = TextPainter(
          text: TextSpan(text: title, style: titleStyle),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout(maxWidth: inner);
        final titleHeight = titlePainter.height;
        titlePainter.dispose();
        final maxCardHeight =
            constraints.maxHeight - _padding.vertical - titleHeight - 6;
        // Cinco enteras y un poco de la sexta, sin pasarse del alto.
        final width = math.min(
          (inner - 5 * _gap) / 5.4,
          maxCardHeight / PestCardRive.aspect,
        );
        return Center(
          child: RivePanel(
            padding: _padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: titleStyle),
                const SizedBox(height: 6),
                SizedBox(
                  width: inner,
                  height: width * PestCardRive.aspect,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: cards.length,
                    separatorBuilder: (_, _) => const SizedBox(width: _gap),
                    itemBuilder: (_, index) => cards[index](width),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Volver, el anuncio (si hay uno cargado) y Comenzar.
class _Buttons extends StatelessWidget {
  const new({
    required this.onBack,
    required this.onStart,
    required this.onRewarded,
    this.rewardedLabel,
  });

  final VoidCallback onBack;
  final VoidCallback onStart;
  final VoidCallback onRewarded;

  /// `null` si no hay anuncio para ofrecer.
  final String? rewardedLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rewardedLabel = this.rewardedLabel;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RiveButton(
            key: const ValueKey('preview-back'),
            kind: RiveButtonKind.secondary,
            label: l10n.back,
            icon: RiveIcon.back,
            onPressed: onBack,
          ),
          if (rewardedLabel != null) ...[
            const SizedBox(width: 16),
            RiveButton(
              key: const ValueKey('preview-rewarded'),
              kind: RiveButtonKind.secondary,
              label: rewardedLabel,
              icon: RiveIcon.ad,
              onPressed: onRewarded,
            ),
          ],
          const SizedBox(width: 16),
          RiveButton(
            key: const ValueKey('preview-start'),
            label: l10n.previewStart,
            icon: RiveIcon.play,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}
