import 'dart:async';

import 'package:flame/game.dart';
// `material.dart` también exporta una `Simulation` (la de física de Flutter).
import 'package:flutter/material.dart' hide Simulation;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/audio.dart';
import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:guardianes_chacra/core/services/audio_service.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/battle_stats.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/commands.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/fixed_step_clock.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/simulation.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/stars.dart';
import 'package:guardianes_chacra/features/battle/domain/events/sim_events.dart';
import 'package:guardianes_chacra/features/battle/domain/world/guardian.dart';
import 'package:guardianes_chacra/features/battle/presentation/battle_assets.dart';
import 'package:guardianes_chacra/features/battle/presentation/battle_game.dart';
import 'package:guardianes_chacra/features/battle/presentation/feedback/battle_feedback.dart';
import 'package:guardianes_chacra/features/battle/presentation/hud/battle_hud.dart';
import 'package:guardianes_chacra/features/battle/presentation/hud/battle_hud_state.dart';
import 'package:guardianes_chacra/features/battle/presentation/layout/map_fit.dart';
import 'package:guardianes_chacra/features/battle/presentation/menus/radial_menu.dart';
import 'package:guardianes_chacra/features/battle/presentation/overlays/battle_overlays.dart';
import 'package:guardianes_chacra/features/battle/presentation/style/battle_colors.dart';
import 'package:guardianes_chacra/features/battle/presentation/style/battle_palette.dart';
import 'package:guardianes_chacra/features/content/domain/content_texts.dart';
import 'package:guardianes_chacra/features/content/domain/game_content.dart';
import 'package:guardianes_chacra/features/content/domain/guardian_def.dart';
import 'package:guardianes_chacra/features/content/domain/level_def.dart';
import 'package:guardianes_chacra/features/content/presentation/content_providers.dart';
import 'package:guardianes_chacra/features/level_select/presentation/level_preview_screen.dart';
import 'package:guardianes_chacra/features/progress/domain/progression.dart';
import 'package:guardianes_chacra/features/progress/presentation/progress_providers.dart';
import 'package:guardianes_chacra/features/settings/presentation/settings_providers.dart';
import 'package:guardianes_chacra/l10n/app_localizations.dart';

/// Estrategias de apuntado en el orden en que se recorren con el botón
/// "Apuntar" (son los ids del registro de comportamientos).
const _targetingCycle = ['first', 'last', 'strongest', 'closest'];

/// La pantalla de una partida: el puente entre Flutter, Riverpod y Flame.
///
/// - El juego ([BattleGame]) avisa toques y cambios; esta pantalla decide
///   qué menú mostrar y envía los comandos a la simulación.
/// - El HUD lee `battleHudProvider`, que se actualiza cuando el juego avisa
///   un cambio.
/// - Los menús son widgets de Flutter ubicados sobre el mapa con [MapFit].
/// - Pausa, victoria y derrota son overlays de Flame: widgets que el
///   `GameWidget` dibuja encima del juego cuando se activan por nombre
///   (`game.overlays.add(...)`).
/// - Los eventos que le importan a la app y no al dibujo (descubrir plagas
///   y guardianes, ganar o perder) los escucha esta pantalla.
class BattleScreen extends ConsumerStatefulWidget {
  const new({required this.levelId, this.assets, super.key});

  final String levelId;

  /// Para los tests: el mapa y las imágenes ya cargados (ver
  /// `BattleAssets`).
  final BattleAssets? assets;

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

/// Lo que dura una partida: se crea de nuevo al reintentar.
class _Session {
  new({
    required this.level,
    required this.simulation,
    required this.game,
    required this.stats,
    required this.guardians,
  });

  final LevelDef level;
  final Simulation simulation;
  final BattleGame game;
  final BattleStats stats;

  /// Los guardianes desbloqueados al empezar: los únicos que la simulación
  /// conoce (construir otro se rechaza) y los que ofrece el menú.
  final Map<String, GuardianDef> guardians;

  /// Lo que abrió la victoria (para contarlo en el overlay).
  Unlocked? unlocked;
}

class _BattleScreenState extends ConsumerState<BattleScreen> {
  _Session? _session;
  late GameContent _content;
  late Progression _progression;
  late String _language;

  /// Pausa la partida cuando la app pasa a segundo plano.
  late final AppLifecycleListener _lifecycle;

  /// Se lee la primera vez que se usa (al empezar la partida): al cerrar
  /// la pantalla (en `dispose`) ya no se puede leer de Riverpod.
  late final AudioService _audio = ref.read(audioServiceProvider);

  bool _paused = false;

  String? _selectedSlot;
  int? _selectedGuardian;

  /// Opción tocada una vez en el menú (se confirma con un segundo toque):
  /// un tipo de guardián, `upgrade`, `sell` o `branch:<id>`.
  String? _preview;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onHide: _pause);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    // De vuelta en los menús, suena su música.
    if (_session != null) _audio.playMusic(_content.audio.menuMusic);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    _language = Localizations.localeOf(context).languageCode;
    return Scaffold(
      backgroundColor: BattleColors.letterbox,
      body: switch (ref.watch(gameContentProvider)) {
        AsyncData(:final value) => _battle(context, value),
        AsyncError(:final error) => Center(
          child: Text(
            l10n.contentLoadError('$error'),
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _battle(BuildContext context, GameContent content) {
    final session = _session ??= _startSession(content);
    final hud = ref.watch(battleHudProvider);
    final ended = hud != null && hud.status != BattleStatus.playing;
    // Con un overlay encima, el HUD y los menús se ocultan: el velo los
    // taparía a medias y sus botones seguirían respondiendo.
    final covered = ended || _paused;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bounds = constraints.biggest;
          final fit = MapFit.compute(
            map: BattleGame.mapSizeOf(session.level),
            viewport: bounds,
          );
          return Stack(
            children: [
              Positioned.fill(
                child: GameWidget(
                  key: ObjectKey(session.game),
                  game: session.game,
                  overlayBuilderMap: {
                    BattleOverlays.pause: (context, _) => PauseOverlay(
                      onResume: _resume,
                      onRetry: _retry,
                      onExit: _exit,
                    ),
                    BattleOverlays.won: (context, _) => _victory(session),
                    BattleOverlays.lost: (context, _) =>
                        DefeatOverlay(onRetry: _retry, onExit: _exit),
                  },
                ),
              ),
              if (!covered)
                Positioned(
                  top: 4,
                  left: 6,
                  right: 6,
                  child: BattleHud(
                    onNextWave: _callNextWave,
                    onToggleSpeed: _toggleSpeed,
                    onPause: _pause,
                  ),
                ),
              if (_menu(context, fit, bounds) case final menu? when !covered)
                Positioned.fill(child: menu),
            ],
          );
        },
      ),
    );
  }

  Widget _victory(_Session session) {
    final next = _levelAfter(session.level);
    final unlocked = session.unlocked;
    return VictoryOverlay(
      unlocked: [
        if (unlocked != null) ...[
          for (final id in unlocked.levels) _levelName(id),
          for (final id in unlocked.guardians) _guardianName(id),
        ],
      ],
      stars: _starsFor(session, session.simulation.potatoes),
      potatoes: session.simulation.potatoes,
      cornHarvested: session.stats.cornHarvested,
      onNext: next == null
          ? null
          : () => Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => LevelPreviewScreen(levelId: next.id),
              ),
            ),
      onRetry: _retry,
      onExit: _exit,
    );
  }

  // --- Partida

  _Session _startSession(GameContent content) {
    _content = content;
    _progression = Progression.of(content);
    final level = content.levels.firstWhere(
      (level) => level.id == widget.levelId,
    );
    final progress = ref.read(progressProvider);
    final guardians = {
      for (final MapEntry(:key, :value) in content.guardians.entries)
        if (_progression.canBuild(progress, key)) key: value,
    };
    final simulation = Simulation(
      level: level,
      pests: content.pests,
      guardians: guardians,
      rules: content.rules,
      seed: 1,
    );
    final game = BattleGame(
      simulation: simulation,
      level: level,
      battleAssets: widget.assets ?? const BattleAssets(),
      sprites: {
        for (final pest in content.pests.values) ?pest.sprite,
        for (final guardian in guardians.values) ...[
          ?guardian.sprite,
          for (final level in guardian.levels) ?level.sprite,
          for (final branch in guardian.branches) ?branch.level.sprite,
        ],
      },
      showDamageNumbers: ref.read(settingsProvider).damageNumbers,
      reduceMotion: MediaQuery.disableAnimationsOf(context),
      labelFor: (type) => _guardianName(type).characters.first.toUpperCase(),
      onSlotTapped: _onSlotTapped,
      onGuardianTapped: _onGuardianTapped,
      onEmptyTapped: _clearSelection,
      onChanged: _onGameChanged,
      onRejected: _onRejected,
    );
    final session = _Session(
      level: level,
      simulation: simulation,
      game: game,
      stats: BattleStats(simulation.events),
      guardians: guardians,
    );
    simulation.events.on<SimEvent>((event) => _onSimEvent(session, event));
    BattleFeedback(
      events: simulation.events,
      audio: _audio,
      pests: content.pests,
      music: level.music,
      vibrationEnabled: () => ref.read(settingsProvider).vibration,
      vibrate: (haptic) => unawaited(switch (haptic) {
        Haptic.collcaDamaged => HapticFeedback.mediumImpact(),
        Haptic.boss => HapticFeedback.heavyImpact(),
      }),
    );
    // El HUD se muestra apenas termina este frame (no se puede cambiar un
    // provider mientras se construye la pantalla).
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncHud(session));
    return session;
  }

  void _retry() {
    setState(() {
      _session = null;
      _paused = false;
      _selectedSlot = null;
      _selectedGuardian = null;
      _preview = null;
    });
  }

  void _exit() => Navigator.of(context).maybePop();

  void _syncHud(_Session session) {
    if (!mounted || session != _session) return;
    ref.read(battleHudProvider.notifier).hud = BattleHudState.of(
      session.simulation,
      speed: session.game.clock.speed,
    );
  }

  void _onGameChanged() {
    final session = _session;
    if (session == null) return;
    _syncHud(session);
    if (session.simulation.status != BattleStatus.playing) {
      // Con la partida terminada no queda nada que construir ni mejorar.
      _clearSelection();
    } else if (_selectedSlot != null || _selectedGuardian != null) {
      // El menú abierto muestra costos, niveles y estrategia: se redibuja.
      setState(() {});
    }
  }

  void _onSimEvent(_Session session, SimEvent event) {
    final progress = ref.read(progressProvider.notifier);
    switch (event) {
      // El Bestiario se llena al ver cada plaga y al construir cada guardián.
      case PestSpawned(:final pestType):
        progress.discoverPest(pestType);
      case GuardianBuilt(:final guardianType):
        progress.discoverGuardian(guardianType);
      case LevelWon(:final potatoesLeft):
        session.unlocked = progress.recordResult(
          session.level.id,
          stars: _starsFor(session, potatoesLeft),
          progression: _progression,
        );
        session.game.overlays.add(BattleOverlays.won);
      case LevelLost():
        session.game.overlays.add(BattleOverlays.lost);
      case _:
        break;
    }
  }

  void _onRejected(RejectionReason reason) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1500),
          content: Text(
            reason == RejectionReason.notEnoughCorn
                ? l10n.rejectNotEnoughCorn
                : l10n.rejectGeneric,
          ),
        ),
      );
  }

  // --- Controles del HUD

  void _callNextWave() => _session?.simulation.enqueue(const CallNextWave());

  void _toggleSpeed() {
    final session = _session;
    if (session == null) return;
    final clock = session.game.clock;
    clock.speed = clock.speed == GameSpeed.normal
        ? GameSpeed.fast
        : GameSpeed.normal;
    _syncHud(session);
  }

  /// Detiene el bucle de Flame (no se actualiza ni se redibuja) y muestra
  /// la pausa. También se llama al pasar a segundo plano.
  void _pause() {
    final session = _session;
    if (session == null ||
        _paused ||
        session.simulation.status != BattleStatus.playing) {
      return;
    }
    _clearSelection();
    // Flame también se pausa solo en segundo plano, pero al volver se
    // reanudaría sin preguntar. `pauseEngine()` desde aquí cuenta como una
    // pausa del jugador: sigue pausado hasta tocar Continuar.
    session.game
      ..pauseEngine()
      ..overlays.add(BattleOverlays.pause);
    _audio.pauseMusic();
    setState(() => _paused = true);
  }

  void _resume() {
    final session = _session;
    if (session == null || !_paused) return;
    session.game
      ..overlays.remove(BattleOverlays.pause)
      ..resumeEngine();
    _audio.resumeMusic();
    setState(() => _paused = false);
  }

  // --- Selección

  void _onSlotTapped(String slotId) {
    final occupant = _guardianOnSlot(slotId);
    if (occupant != null) return _onGuardianTapped(occupant.id);
    setState(() {
      _selectedSlot = slotId;
      _selectedGuardian = null;
      _preview = null;
    });
    _session!.game
      ..highlightSlot(slotId)
      ..highlightGuardian(null)
      ..hideRange();
  }

  void _onGuardianTapped(int guardianId) {
    final guardian = _guardian(guardianId);
    if (guardian == null) return;
    setState(() {
      _selectedSlot = null;
      _selectedGuardian = guardianId;
      _preview = null;
    });
    _session!.game
      ..highlightSlot(null)
      ..highlightGuardian(guardianId)
      ..showRange(at: guardian.position, radius: guardian.range);
  }

  void _clearSelection() {
    if (_selectedSlot == null && _selectedGuardian == null) return;
    setState(() {
      _selectedSlot = null;
      _selectedGuardian = null;
      _preview = null;
    });
    _session?.game
      ?..highlightSlot(null)
      ..highlightGuardian(null)
      ..hideRange();
  }

  /// Primer toque: muestra el alcance de la opción. Segundo toque: la
  /// confirma.
  void _previewOrConfirm(
    String option, {
    required Vec2 at,
    required double range,
    required PlayerCommand command,
  }) {
    if (_preview != option) {
      setState(() => _preview = option);
      _session!.game.showRange(at: at, radius: range);
      return;
    }
    _session!.simulation.enqueue(command);
    _clearSelection();
  }

  // --- Menús

  Widget? _menu(BuildContext context, MapFit fit, Size bounds) {
    final session = _session!;
    Offset onScreen(Vec2 tiles) => fit.toScreen(
      Offset(tiles.x * BattleGame.tileSize, tiles.y * BattleGame.tileSize),
    );
    final l10n = AppLocalizations.of(context);
    final hint = _preview == null ? null : l10n.menuConfirmHint;

    if (_selectedSlot case final slotId?) {
      final slot = session.level.map.buildSlots.firstWhere(
        (slot) => slot.id == slotId,
      );
      return RadialMenu(
        center: onScreen(slot.position),
        bounds: bounds,
        hint: hint,
        children: [
          for (final def in session.guardians.values)
            RadialButton(
              key: ValueKey('build-${def.id}'),
              label: _guardianName(def.id).characters.first.toUpperCase(),
              caption: '${def.levels.first.cost}',
              color: colorFor(def.id, def.color),
              selected: _preview == def.id,
              semanticsLabel: l10n.menuBuild(
                _guardianName(def.id),
                def.levels.first.cost,
              ),
              onTap: session.simulation.corn < def.levels.first.cost
                  ? null
                  : () => _previewOrConfirm(
                      def.id,
                      at: slot.position,
                      range: def.levels.first.range,
                      command: BuildGuardian(
                        slotId: slotId,
                        guardianType: def.id,
                      ),
                    ),
            ),
        ],
      );
    }

    if (_selectedGuardian case final guardianId?) {
      final guardian = _guardian(guardianId);
      if (guardian == null) return null;
      return RadialMenu(
        center: onScreen(guardian.position),
        bounds: bounds,
        title: '${_guardianName(guardian.def.id)} · ${guardian.level}',
        hint: hint,
        children: _guardianOptions(guardian, l10n),
      );
    }
    return null;
  }

  List<Widget> _guardianOptions(GuardianView guardian, AppLocalizations l10n) {
    final session = _session!;
    final corn = session.simulation.corn;
    final def = guardian.def;
    final color = colorFor(def.id, def.color);
    final atLastLevel = guardian.level == def.levels.length;
    final canUpgrade = guardian.branchId == null && !atLastLevel;
    final canSpecialize = guardian.branchId == null && atLastLevel;

    return [
      if (canUpgrade)
        RadialButton(
          key: const ValueKey('menu-upgrade'),
          icon: Icons.arrow_upward,
          caption: '${def.levels[guardian.level].cost}',
          color: color,
          selected: _preview == 'upgrade',
          semanticsLabel:
              '${l10n.menuUpgrade}: '
              '${def.levels[guardian.level].cost}',
          onTap: corn < def.levels[guardian.level].cost
              ? null
              : () => _previewOrConfirm(
                  'upgrade',
                  at: guardian.position,
                  range: def.levels[guardian.level].range,
                  command: UpgradeGuardian(guardian.id),
                ),
        ),
      if (canSpecialize)
        for (final branch in def.branches)
          RadialButton(
            key: ValueKey('menu-branch-${branch.id}'),
            label: _branchName(def.id, branch.id).characters.first,
            caption: '${branch.level.cost}',
            color: color,
            selected: _preview == 'branch:${branch.id}',
            semanticsLabel:
                '${_branchName(def.id, branch.id)}: '
                '${branch.level.cost}',
            onTap: corn < branch.level.cost
                ? null
                : () => _previewOrConfirm(
                    'branch:${branch.id}',
                    at: guardian.position,
                    range: branch.level.range,
                    command: SpecializeGuardian(
                      guardian.id,
                      branchId: branch.id,
                    ),
                  ),
          ),
      RadialButton(
        key: const ValueKey('menu-sell'),
        icon: Icons.sell_outlined,
        caption: '+${session.simulation.sellValueOf(guardian)}',
        color: const Color(0xFF8D6E4F),
        selected: _preview == 'sell',
        semanticsLabel:
            '${l10n.menuSell}: ${session.simulation.sellValueOf(guardian)}',
        onTap: () => _previewOrConfirm(
          'sell',
          at: guardian.position,
          range: guardian.range,
          command: SellGuardian(guardian.id),
        ),
      ),
      if (def.levels.first.targets.isNotEmpty)
        RadialButton(
          key: const ValueKey('menu-targeting'),
          icon: Icons.gps_fixed,
          caption: _targetingName(guardian.targetingId, l10n),
          color: const Color(0xFF455A64),
          semanticsLabel:
              '${l10n.menuTargeting}: '
              '${_targetingName(guardian.targetingId, l10n)}',
          onTap: () {
            final index = _targetingCycle.indexOf(guardian.targetingId);
            final next = _targetingCycle[(index + 1) % _targetingCycle.length];
            session.simulation.enqueue(
              SetTargeting(guardian.id, strategy: next),
            );
          },
        ),
    ];
  }

  // --- Datos

  int _starsFor(_Session session, int potatoesLeft) => starsFor(
    potatoesLeft: potatoesLeft,
    startingPotatoes: session.level.startingPotatoes,
    rules: _content.rules,
  );

  LevelDef? _levelAfter(LevelDef level) {
    final index = _content.levels.indexOf(level);
    return index + 1 < _content.levels.length
        ? _content.levels[index + 1]
        : null;
  }

  GuardianView? _guardian(int id) => _session?.simulation.guardians
      .where((guardian) => guardian.id == id)
      .firstOrNull;

  GuardianView? _guardianOnSlot(String slotId) => _session?.simulation.guardians
      .where((guardian) => guardian.slotId == slotId)
      .firstOrNull;

  String _levelName(String id) =>
      _content.texts.text(ContentTexts.levelName(id), language: _language);

  String _guardianName(String type) =>
      _content.texts.text(ContentTexts.guardianName(type), language: _language);

  String _branchName(String guardianType, String branchId) =>
      _content.texts.text(
        ContentTexts.branchName(guardianType, branchId),
        language: _language,
      );

  String _targetingName(String id, AppLocalizations l10n) => switch (id) {
    'first' => l10n.targetingFirst,
    'last' => l10n.targetingLast,
    'strongest' => l10n.targetingStrongest,
    'closest' => l10n.targetingClosest,
    _ => id,
  };
}
