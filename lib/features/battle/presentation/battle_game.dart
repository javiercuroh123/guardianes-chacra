import 'dart:ui';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:guardianes_chacra/core/events/event_bus.dart';
import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/fixed_step_clock.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/simulation.dart';
import 'package:guardianes_chacra/features/battle/domain/events/sim_events.dart';
import 'package:guardianes_chacra/features/battle/presentation/components/guardian_component.dart';
import 'package:guardianes_chacra/features/battle/presentation/components/interpolated.dart';
import 'package:guardianes_chacra/features/battle/presentation/components/pest_component.dart';
import 'package:guardianes_chacra/features/battle/presentation/components/projectile_component.dart';
import 'package:guardianes_chacra/features/battle/presentation/components/pulse_component.dart';
import 'package:guardianes_chacra/features/battle/presentation/components/range_component.dart';
import 'package:guardianes_chacra/features/battle/presentation/components/slot_component.dart';
import 'package:guardianes_chacra/features/battle/presentation/layout/map_fit.dart';
import 'package:guardianes_chacra/features/battle/presentation/style/battle_colors.dart';
import 'package:guardianes_chacra/features/battle/presentation/style/battle_palette.dart';
import 'package:guardianes_chacra/features/content/domain/level_def.dart';

/// La partida en pantalla. Hace tres cosas y ninguna regla:
///
/// 1. **Reloj**: en cada frame convierte el tiempo real en pasos fijos
///    (`FixedStepClock`) y avanza la [Simulation].
/// 2. **Dibujo**: escucha los eventos de la simulación para crear y quitar
///    componentes, y cada componente lee su vista (`PestView`…) para
///    dibujarse, interpolando entre ticks.
/// 3. **Toques**: avisa qué se tocó ([onSlotTapped], [onGuardianTapped],
///    [onEmptyTapped]); la pantalla decide qué menú abrir y envía los
///    comandos a la simulación.
class BattleGame extends FlameGame {
  new({
    required this.simulation,
    required this.level,
    this.loadMap = loadTiledMap,
    this.labelFor,
    this.onSlotTapped,
    this.onGuardianTapped,
    this.onEmptyTapped,
    this.onChanged,
    this.onRejected,
  });

  /// Píxeles del mundo por casilla de la simulación (el tamaño de las
  /// casillas de los mapas de Tiled).
  static const double tileSize = 64;

  /// Tamaño del mapa en píxeles del mundo.
  static Size mapSizeOf(LevelDef level) =>
      Size(level.map.width * tileSize, level.map.height * tileSize);

  final Simulation simulation;
  final LevelDef level;

  /// Carga el dibujo del mapa. Los tests pasan uno ya cargado: decodificar
  /// la imagen del tileset no funciona con el reloj falso de los tests.
  final Future<Component> Function(LevelDef level) loadMap;

  /// El mapa de Tiled del nivel. El tileset (.tsx y .png) está junto al
  /// mapa en assets/tiles/, igual que en Tiled; por defecto Flame buscaría
  /// la imagen en assets/images/.
  static Future<Component> loadTiledMap(LevelDef level) => TiledComponent.load(
    level.mapFile,
    Vector2.all(tileSize),
    images: Images(prefix: 'assets/tiles/'),
  );

  /// Texto que se dibuja sobre cada guardián (su inicial en el idioma del
  /// jugador). Si falta, se usa la inicial de su id.
  final String Function(String guardianType)? labelFor;

  final void Function(String slotId)? onSlotTapped;
  final void Function(int guardianId)? onGuardianTapped;
  final void Function()? onEmptyTapped;

  /// Cambió algo que muestran el HUD o los menús (maíz, papas, oleada, el
  /// final o un guardián). Se avisa como mucho una vez por frame.
  final void Function()? onChanged;

  /// La simulación rechazó un comando (por ejemplo, por falta de maíz).
  final void Function(RejectionReason reason)? onRejected;

  final FixedStepClock clock = FixedStepClock();

  final ComponentPool<ProjectileComponent> projectilePool = ComponentPool(
    factory: ProjectileComponent.new,
    maxSize: 200,
  );
  final ComponentPool<PulseComponent> pulsePool = ComponentPool(
    factory: PulseComponent.new,
    maxSize: 60,
  );

  final Map<int, PestComponent> _pests = {};
  final Map<int, GuardianComponent> _guardians = {};
  final Map<int, ProjectileComponent> _projectiles = {};
  final Map<String, SlotComponent> _slots = {};
  final RangeComponent _range = RangeComponent();
  EventSubscription? _subscription;
  bool _changed = false;

  @override
  Color backgroundColor() => BattleColors.letterbox;

  @override
  Future<void> onLoad() async {
    final map = await loadMap(level);
    final mapSize = mapSizeOf(level);
    await world.addAll([
      map,
      GroundComponent(size: Vector2(mapSize.width, mapSize.height)),
      for (final slot in level.map.buildSlots)
        _slots[slot.id] = SlotComponent(
          slotId: slot.id,
          position: _toWorld(slot.position),
          tileSize: tileSize,
        ),
      _range,
    ]);

    camera.viewfinder
      ..anchor = Anchor.center
      ..position = Vector2(mapSize.width / 2, mapSize.height / 2);
    // `size` es el tamaño del visor de la cámara, que en la web todavía
    // puede ser 0 aquí; el del lienzo ya es el real.
    if (hasLayout) _fitCamera(canvasSize);

    _subscription = simulation.events.on<SimEvent>(_onEvent);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // También antes de terminar de cargar: si el tamaño llega antes que el
    // mapa (pasa en la web), la cámara ya queda lista.
    _fitCamera(size);
  }

  @override
  void onRemove() {
    _subscription?.cancel();
    super.onRemove();
  }

  @override
  void update(double dt) {
    final steps = clock.advance(dt);
    for (var i = 0; i < steps; i++) {
      if (i == steps - 1) _forEachInterpolated((c) => c.rememberPrevious());
      simulation.step();
    }
    if (steps > 0) _forEachInterpolated((c) => c.readCurrent());
    final alpha = clock.alpha;
    for (final pest in _pests.values) {
      pest.interpolate(alpha);
    }
    for (final projectile in _projectiles.values) {
      projectile.interpolate(alpha);
    }

    super.update(dt);

    if (_changed) {
      _changed = false;
      onChanged?.call();
    }
  }

  // --- Selección (la pantalla la controla).

  void highlightSlot(String? slotId) {
    for (final slot in _slots.values) {
      slot.selected = slot.slotId == slotId;
    }
  }

  void highlightGuardian(int? guardianId) {
    for (final guardian in _guardians.values) {
      guardian.selected = guardian.guardianId == guardianId;
    }
  }

  /// Muestra un alcance de [radius] casillas alrededor de [at] (casillas).
  void showRange({required Vec2 at, required double radius}) =>
      _range.show(at: _toWorld(at), radius: radius * tileSize);

  void hideRange() => _range.hide();

  // --- Eventos de la simulación → componentes.

  void _onEvent(SimEvent event) {
    switch (event) {
      case PestSpawned(:final pestId):
        final view = simulation.pests.firstWhere((pest) => pest.id == pestId);
        world.add(
          _pests[pestId] = PestComponent(view: view, tileSize: tileSize),
        );
      case CollcaDamaged(:final pestId):
        _pests.remove(pestId)?.removeFromParent();
        _changed = true;
      case PestDefeated(:final pestId):
        _pests.remove(pestId)?.removeFromParent();
      case GuardianBuilt(:final guardianId):
        final view = simulation.guardians.firstWhere(
          (guardian) => guardian.id == guardianId,
        );
        world.add(
          _guardians[guardianId] = GuardianComponent(
            view: view,
            tileSize: tileSize,
            label: labelFor?.call(view.def.id) ?? view.def.id[0].toUpperCase(),
          ),
        );
        _changed = true;
      case GuardianSold(:final guardianId):
        _guardians.remove(guardianId)?.removeFromParent();
        _changed = true;
      case GuardianUpgraded(:final guardianId):
      case GuardianSpecialized(:final guardianId):
        _guardians[guardianId]?.refresh();
        _changed = true;
      case GuardianFired(:final guardianId, :final pestId, :final projectileId):
        final target = _pests[pestId];
        if (target != null) _guardians[guardianId]?.aimAt(target.position);
        final view = simulation.projectiles.firstWhere(
          (projectile) => projectile.id == projectileId,
        );
        final projectile = projectilePool.acquire()
          ..follow(view, tileSize: tileSize);
        _projectiles[projectileId] = projectile;
        world.add(projectile);
      case ProjectileImpacted(:final projectileId, :final position):
        final projectile = _projectiles.remove(projectileId);
        projectile?.removeFromParent();
        final splash = projectile?.view.splashRadius ?? 0;
        _pulse(
          at: position,
          radius: splash > 0 ? splash * tileSize : tileSize * 0.15,
          color: BattleColors.impact,
          duration: 0.2,
        );
      case AreaPulsed(:final guardianId):
        final guardian = _guardians[guardianId];
        if (guardian != null) {
          _pulse(
            at: guardian.view.position,
            radius: guardian.view.range * tileSize,
            color: colorFor(guardian.view.def.id, guardian.view.def.color),
          );
        }
      case CommandRejected(:final reason):
        onRejected?.call(reason);
      case CornChanged() ||
          WaveStarted() ||
          LevelWon() ||
          LevelLost() ||
          TargetingChanged():
        _changed = true;
      case WaveCompleted() || PestDamaged():
        break;
    }
  }

  void _pulse({
    required Vec2 at,
    required double radius,
    required Color color,
    double duration = 0.3,
  }) {
    world.add(
      pulsePool.acquire()..start(
        at: _toWorld(at),
        radius: radius,
        color: color,
        duration: duration,
      ),
    );
  }

  void _forEachInterpolated(void Function(Interpolated component) action) {
    _pests.values.forEach(action);
    _projectiles.values.forEach(action);
  }

  void _fitCamera(Vector2 viewport) {
    // Un zoom de 0 haría desaparecer el mapa.
    if (viewport.x <= 0 || viewport.y <= 0) return;
    final fit = MapFit.compute(
      map: mapSizeOf(level),
      viewport: Size(viewport.x, viewport.y),
    );
    camera.viewfinder.zoom = fit.zoom;
  }

  Vector2 _toWorld(Vec2 tiles) =>
      Vector2(tiles.x * tileSize, tiles.y * tileSize);
}
