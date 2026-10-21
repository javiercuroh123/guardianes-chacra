import 'dart:async';

import 'package:flame/game.dart';
// `material.dart` también exporta una `Simulation` (la de física de Flutter).
import 'package:flutter/material.dart' hide Simulation;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/ads.dart';
import 'package:guardianes_chacra/app/analytics.dart';
import 'package:guardianes_chacra/app/audio.dart';
import 'package:guardianes_chacra/app/haptics.dart';
import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:guardianes_chacra/core/services/ads_service.dart';
import 'package:guardianes_chacra/core/services/audio_service.dart';
import 'package:guardianes_chacra/dev/dev_options.dart';
import 'package:guardianes_chacra/dev/dev_panel.dart';
import 'package:guardianes_chacra/dev/rive_bench.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/battle_stats.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/commands.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/fixed_step_clock.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/simulation.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/simulation_cheats.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/stars.dart';
import 'package:guardianes_chacra/features/battle/domain/events/sim_events.dart';
import 'package:guardianes_chacra/features/battle/domain/world/guardian.dart';
import 'package:guardianes_chacra/features/battle/presentation/battle_assets.dart';
import 'package:guardianes_chacra/features/battle/presentation/battle_game.dart';
import 'package:guardianes_chacra/features/battle/presentation/feedback/battle_analytics.dart';
import 'package:guardianes_chacra/features/battle/presentation/feedback/battle_feedback.dart';
import 'package:guardianes_chacra/features/battle/presentation/hud/battle_hud.dart';
import 'package:guardianes_chacra/features/battle/presentation/hud/battle_hud_state.dart';
import 'package:guardianes_chacra/features/battle/presentation/layout/map_fit.dart';
import 'package:guardianes_chacra/features/battle/presentation/menus/battle_menus.dart';
import 'package:guardianes_chacra/features/battle/presentation/overlays/battle_overlays.dart';
import 'package:guardianes_chacra/features/battle/presentation/style/battle_colors.dart';
import 'package:guardianes_chacra/features/battle/presentation/style/battle_palette.dart';
import 'package:guardianes_chacra/features/content/domain/content_texts.dart';
import 'package:guardianes_chacra/features/content/domain/game_content.dart';
import 'package:guardianes_chacra/features/content/domain/guardian_def.dart';
import 'package:guardianes_chacra/features/content/domain/level_def.dart';
import 'package:guardianes_chacra/features/content/presentation/content_providers.dart';
import 'package:guardianes_chacra/features/level_select/presentation/level_preview_screen.dart';
import 'package:guardianes_chacra/features/level_select/presentation/valley_reveal.dart';
import 'package:guardianes_chacra/features/progress/domain/progression.dart';
import 'package:guardianes_chacra/features/progress/presentation/progress_providers.dart';
import 'package:guardianes_chacra/features/settings/presentation/settings_providers.dart';
import 'package:guardianes_chacra/l10n/app_localizations.dart';

/// La pantalla de una partida: el puente entre Flutter, Riverpod y Flame.
///
/// - El juego ([BattleGame]) avisa toques y cambios; esta pantalla decide
///   qué menú mostrar y envía los comandos a la simulación.
/// - El HUD lee `battleHudProvider`, que se actualiza cuando el juego avisa
///   un cambio.
/// - Los menús ([BuildMenu], [GuardianCard], [SpecializationWindow]) son
///   widgets de Flutter ubicados sobre el mapa con [MapFit]; esta pantalla
///   guarda qué está seleccionado y confirma sus opciones.
/// - Pausa, victoria y derrota son overlays de Flame: widgets que el
///   `GameWidget` dibuja encima del juego cuando se activan por nombre
///   (`game.overlays.add(...)`).
/// - Los eventos que le importan a la app y no al dibujo (descubrir plagas
///   y guardianes, ganar o perder) los escucha esta pantalla.
class BattleScreen extends ConsumerStatefulWidget {
  const new({
    required this.levelId,
    this.assets,
    this.extraCorn = 0,
    super.key,
  });

  final String levelId;

  /// Maíz extra para la primera partida (la recompensa de un anuncio en la
  /// vista previa). Al reintentar, ya no se suma.
  final int extraCorn;

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
    required this.cheats,
    this.watchedRewarded = false,
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

  /// Los trucos de desarrollo de esta partida (solo los cambia el panel de
  /// desarrollo, nunca en release).
  final SimulationCheats cheats;

  /// Si en esta partida se vio un anuncio recompensado (para empezar con
  /// maíz o para revivir): entonces no toca intersticial al salir.
  bool watchedRewarded;
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
  late final AdsService _ads = ref.read(adsServiceProvider);

  /// El maíz extra que falta usar: solo en la primera partida.
  late int _pendingExtraCorn = widget.extraCorn;

  bool _paused = false;

  String? _selectedSlot;
  int? _selectedGuardian;

  /// Opción tocada una vez en el menú (se confirma con un segundo toque):
  /// un tipo de guardián, `upgrade`, `sell` o `branch:<id>`.
  String? _preview;

  /// La opción recién confirmada: hace su animación ("pop", estallido)
  /// antes de que el menú se cierre. Mientras tanto no se aceptan toques.
  String? _confirmed;

  /// El guardián cuya ventana de especialización está abierta (la
  /// simulación queda en pausa, pero el mapa se sigue dibujando para
  /// mostrar el alcance de cada rama).
  int? _specializing;

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
    if (devToolsEnabled) {
      session.game.debugOverlay = ref.watch(
        devOptionsProvider.select((options) => options.debugOverlay),
      );
    }
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
                    BattleOverlays.lost: (context, _) => _defeat(session),
                  },
                ),
              ),
              if (!covered) ...[
                Positioned(
                  top: 4,
                  left: 6,
                  right: 6,
                  child: BattleHud(
                    onToggleSpeed: _toggleSpeed,
                    onPause: _pause,
                    onDevTools: devToolsEnabled ? _openDevTools : null,
                  ),
                ),
                const Positioned(
                  top: 52,
                  left: 0,
                  right: 0,
                  child: Center(child: BattleWaveBanner()),
                ),
                // La ficha de un guardián ocupa ese rincón: mientras está
                // abierta no hay siguiente oleada.
                if (_selectedGuardian == null)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: BattleNextWave(onNextWave: _callNextWave),
                  ),
              ],
              if (_menu(context, fit, bounds) case final menu? when !covered)
                Positioned.fill(child: menu),
              if (devToolsEnabled
                      ? ref.watch(
                          devOptionsProvider.select(
                            (options) => options.riveBench,
                          ),
                        )
                      : RiveBenchMode.off
                  case final mode when mode != RiveBenchMode.off)
                Positioned(
                  left: 6,
                  right: 6,
                  bottom: 6,
                  child: RiveBench(
                    mode: mode,
                    sharedTexture: ref.watch(
                      devOptionsProvider.select(
                        (options) => options.riveSharedTexture,
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

  Widget _victory(_Session session) {
    final next = _levelAfter(session.level);
    final unlocked = session.unlocked;
    return VictoryOverlay(
      unlocked: [
        if (unlocked != null) ...[
          for (final id in unlocked.levels)
            UnlockedItem.level(name: _levelName(id), color: colorForId(id)),
          for (final id in unlocked.guardians)
            UnlockedItem.guardian(
              guardianId: id,
              name: _guardianName(id),
              color: colorFor(id, _content.guardians[id]?.color),
            ),
        ],
      ],
      stars: _starsFor(session, session.simulation.potatoes),
      potatoes: session.simulation.potatoes,
      maxPotatoes: session.simulation.startingPotatoes,
      cornHarvested: session.stats.cornHarvested,
      onNext: next == null
          ? null
          : () => _leaveResult(
              session,
              () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => LevelPreviewScreen(levelId: next.id),
                ),
              ),
            ),
      onRetry: () => _leaveResult(session, _retry),
      onExit: () => _leaveResult(session, _exit),
    );
  }

  /// La derrota. Si hay un anuncio recompensado cargado y la partida no se
  /// revivió todavía, ofrece verlo para seguir jugando.
  Widget _defeat(_Session session) {
    final potatoes = _content.ads.rewardedRevivePotatoes;
    return ValueListenableBuilder<AdsStatus>(
      valueListenable: _ads.status,
      builder: (context, status, _) => DefeatOverlay(
        potatoes: session.simulation.potatoes,
        maxPotatoes: session.simulation.startingPotatoes,
        revivePotatoes: potatoes,
        onRevive:
            status.rewardedReady && potatoes > 0 && session.simulation.canRevive
            ? () => _reviveWithAd(session, potatoes)
            : null,
        onRetry: () => _leaveResult(session, _retry),
        onExit: () => _leaveResult(session, _exit),
      ),
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
    final unlockAll = devToolsEnabled && ref.read(devOptionsProvider).unlockAll;
    final guardians = {
      for (final MapEntry(:key, :value) in content.guardians.entries)
        if (unlockAll || _progression.canBuild(progress, key)) key: value,
    };
    final cheats = SimulationCheats();
    final extraCorn = _pendingExtraCorn;
    _pendingExtraCorn = 0;
    final simulation = Simulation(
      cheats: cheats,
      extraCorn: extraCorn,
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
      cheats: cheats,
      watchedRewarded: extraCorn > 0,
    );
    if (devToolsEnabled) {
      game.debugOverlay = ref.read(devOptionsProvider).debugOverlay;
    }
    simulation.events.on<SimEvent>((event) => _onSimEvent(session, event));
    BattleFeedback(
      events: simulation.events,
      audio: _audio,
      haptics: ref.read(hapticsServiceProvider),
      pests: content.pests,
      music: level.music,
      vibrationEnabled: () => ref.read(settingsProvider).vibration,
    );
    BattleAnalytics(
      simulation: simulation,
      analytics: ref.read(analyticsServiceProvider),
      levelId: level.id,
      starsFor: (potatoes) => _starsFor(session, potatoes),
      extraCorn: extraCorn,
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
      _confirmed = null;
      _specializing = null;
    });
  }

  void _exit() => Navigator.of(context).maybePop();

  /// Al salir del resultado (ganar o perder): cuenta la partida y, si le
  /// toca según `AdPolicy`, muestra antes un intersticial.
  Future<void> _leaveResult(_Session session, VoidCallback action) async {
    final due = ref
        .read(adPolicyProvider)
        .resultClosed(
          interstitialEvery: _content.ads.interstitialEveryLevels,
          watchedRewarded: session.watchedRewarded,
        );
    if (due) await _ads.showInterstitial();
    if (mounted) action();
  }

  /// Muestra el anuncio recompensado y, si se vio entero, sigue la partida
  /// con [potatoes] papas.
  Future<void> _reviveWithAd(_Session session, int potatoes) async {
    final earned = await _ads.showRewarded();
    if (!mounted || session != _session) return;
    if (!earned) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).adNotCompleted)),
      );
      return;
    }
    // La música del nivel vuelve con el evento `LevelRevived` (ver
    // `BattleFeedback`).
    if (session.simulation.revive(potatoes)) session.watchedRewarded = true;
  }

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
        final unlocked = progress.recordResult(
          session.level.id,
          stars: _starsFor(session, potatoesLeft),
          progression: _progression,
        );
        session.unlocked = unlocked;
        // El valle dibuja el camino hasta cada nivel nuevo al volver a él.
        ref.read(valleyRevealProvider.notifier).add(unlocked.levels);
        session.game.overlays.add(BattleOverlays.won);
      case LevelLost():
        session.game.overlays.add(BattleOverlays.lost);
      case LevelRevived():
        session.game.overlays.remove(BattleOverlays.lost);
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

  /// El panel de desarrollo (nunca en release).
  void _openDevTools() {
    final session = _session;
    if (session == null) return;
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        // En horizontal, la hoja normal (media pantalla) no alcanza.
        isScrollControlled: true,
        builder: (_) => DevPanel(
          cheats: session.cheats,
          onSkipWave: () => session.simulation.enqueue(const SkipWave()),
          onStressTest: () => session.simulation.enqueue(const StressTest()),
        ),
      ),
    );
  }

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
    if (_confirmed != null || _specializing != null) return;
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
    if (_confirmed != null || _specializing != null) return;
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
    final session = _session;
    // Cerrar la especialización devuelve la partida a su ritmo.
    if (_specializing != null) session?.game.clock.paused = false;
    setState(() {
      _selectedSlot = null;
      _selectedGuardian = null;
      _preview = null;
      _confirmed = null;
      _specializing = null;
    });
    session?.game
      ?..highlightSlot(null)
      ..highlightGuardian(null)
      ..hideRange();
  }

  /// Primer toque: muestra el alcance de la opción (alrededor de [at]).
  /// Segundo toque: la confirma. Construir y especializar dejan ver su
  /// animación (el "pop", el estallido) antes de cerrar el menú.
  void _previewOrConfirm(MenuChoice choice, {required Vec2 at}) {
    if (_confirmed != null) return;
    final session = _session!;
    if (_preview != choice.id) {
      setState(() => _preview = choice.id);
      session.game.showRange(at: at, radius: choice.range);
      return;
    }
    session.simulation.enqueue(choice.command);
    final linger = switch (choice.command) {
      BuildGuardian() => const Duration(milliseconds: 280),
      SpecializeGuardian() => const Duration(milliseconds: 750),
      _ => null,
    };
    if (linger == null || MediaQuery.disableAnimationsOf(context)) {
      _clearSelection();
      return;
    }
    setState(() => _confirmed = choice.id);
    Future<void>.delayed(linger, () {
      if (mounted && session == _session && _confirmed == choice.id) {
        _clearSelection();
      }
    });
  }

  /// Abre las dos ramas del guardián [guardianId] con la simulación en
  /// pausa.
  void _openSpecialization(int guardianId) {
    _session!.game
      ..clock.paused = true
      ..hideRange();
    setState(() {
      _specializing = guardianId;
      _preview = null;
    });
  }

  /// Cierra la ventana sin elegir y vuelve a la ficha.
  void _closeSpecialization() {
    final session = _session!;
    session.game.clock.paused = false;
    setState(() {
      _specializing = null;
      _preview = null;
    });
    if (_guardian(_selectedGuardian ?? -1) case final guardian?) {
      session.game.showRange(at: guardian.position, radius: guardian.range);
    }
  }

  // --- Menús

  Widget? _menu(BuildContext context, MapFit fit, Size bounds) {
    final session = _session!;
    final l10n = AppLocalizations.of(context);
    Offset onScreen(Vec2 tiles) => fit.toScreen(
      Offset(tiles.x * BattleGame.tileSize, tiles.y * BattleGame.tileSize),
    );

    if (_selectedSlot case final slotId?) {
      final slot = session.level.map.buildSlots.firstWhere(
        (slot) => slot.id == slotId,
      );
      return BuildMenu(
        slotId: slotId,
        center: onScreen(slot.position),
        bounds: bounds,
        // Todos los guardianes: los bloqueados con candado y su regla.
        entries: [
          for (final def in _content.guardians.values)
            BuildEntry(
              def: def,
              name: _guardianName(def.id),
              lockRule: session.guardians.containsKey(def.id)
                  ? null
                  : _lockRule(def, l10n),
            ),
        ],
        canAfford: session.simulation.canAfford,
        preview: _preview,
        confirmed: _confirmed,
        onChoose: (choice) => _previewOrConfirm(choice, at: slot.position),
      );
    }

    if (_selectedGuardian case final guardianId?) {
      final guardian = _guardian(guardianId);
      if (guardian == null) return null;
      if (_specializing == guardianId) {
        return SpecializationWindow(
          guardian: guardian,
          canAfford: session.simulation.canAfford,
          branchNameOf: (branchId) => _branchName(guardian.def.id, branchId),
          branchDescriptionOf: (branchId) =>
              _branchDescription(guardian.def.id, branchId),
          preview: _preview,
          chosen: _confirmed,
          onChoose: (choice) =>
              _previewOrConfirm(choice, at: guardian.position),
          onClose: _closeSpecialization,
        );
      }
      return GuardianCard(
        guardian: guardian,
        center: onScreen(guardian.position),
        bounds: bounds,
        sellValue: session.simulation.sellValueOf(guardian),
        canAfford: session.simulation.canAfford,
        nameOf: _guardianName,
        branchNameOf: (branchId) => _branchName(guardian.def.id, branchId),
        preview: _preview,
        locale: _language,
        onChoose: (choice) => _previewOrConfirm(choice, at: guardian.position),
        onCommand: session.simulation.enqueue,
        onSpecialize: () => _openSpecialization(guardianId),
        onClose: _clearSelection,
      );
    }
    return null;
  }

  /// "Se abre al ganar Andenes": por qué [def] todavía no se puede
  /// construir.
  String _lockRule(GuardianDef def, AppLocalizations l10n) {
    final rule = def.unlock;
    if (rule.afterLevel case final level?) {
      return l10n.unlockAfterLevel(_levelName(level));
    }
    if (rule.totalStars > 0) return l10n.unlockStars(rule.totalStars);
    return l10n.rejectGeneric;
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

  String _branchDescription(String guardianType, String branchId) =>
      _content.texts.text(
        ContentTexts.branchDescription(guardianType, branchId),
        language: _language,
      );
}
