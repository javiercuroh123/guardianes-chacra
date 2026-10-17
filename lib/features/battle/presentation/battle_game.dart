import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:guardianes_chacra/core/events/event_bus.dart';
import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:guardianes_chacra/dev/debug_overlay.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/fixed_step_clock.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/sim_time.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/simulation.dart';
import 'package:guardianes_chacra/features/battle/domain/events/sim_events.dart';
import 'package:guardianes_chacra/features/battle/presentation/battle_assets.dart';
import 'package:guardianes_chacra/features/battle/presentation/components/damage_number_component.dart';
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
import 'package:guardianes_chacra/features/content/domain/sprite_def.dart';

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
///
/// Además del dibujo, da la sensación de impacto ("game feel"): destello
/// al recibir daño, números de daño (si están activados), partículas al
/// derrotar una plaga y una sacudida de cámara cuando aparece el jefe.
class BattleGame extends FlameGame {
  new({
    required this.simulation,
    required this.level,
    this.battleAssets = const BattleAssets(),
    this.sprites = const [],
    this.showDamageNumbers = false,
    this.reduceMotion = false,
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

  /// Carga el mapa y las imágenes. Los tests pasan unos ya cargados:
  /// decodificar imágenes no funciona con el reloj falso de los tests.
  final BattleAssets battleAssets;

  /// Los sprites que pueden aparecer en la partida (se cargan al empezar).
  final Iterable<SpriteDef> sprites;

  /// Muestra números con el daño que recibe cada plaga (Ajustes).
  bool showDamageNumbers;

  /// El teléfono pide menos animaciones (accesibilidad): sin sacudidas.
  final bool reduceMotion;

  /// Texto que se dibuja sobre cada guardián (su inicial en el idioma del
  /// jugador). Si falta, se usa la inicial de su id.
  final String Function(String guardianType)? labelFor;

  final void Function(String slotId)? onSlotTapped;
  final void Function(int guardianId)? onGuardianTapped;
  final void Function()? onEmptyTapped;

  /// Cambió algo que muestran el HUD o los menús (maíz, papas, oleada, la
  /// cuenta regresiva, el final o un guardián). Se avisa como mucho una vez
  /// por frame.
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
  final ComponentPool<DamageNumberComponent> damageNumberPool = ComponentPool(
    factory: DamageNumberComponent.new,
    maxSize: maxDamageNumbers,
  );

  /// Tope de números de daño a la vez y de estallidos de partículas: con un
  /// enjambre, más no se leería y costaría rendimiento.
  static const maxDamageNumbers = 24;
  static const maxBursts = 10;

  /// Cada cuánto se muestra el daño acumulado de cada plaga: así el daño
  /// por quemadura, que llega en cada tick, se ve como un solo número.
  static const damageNumberInterval = 0.3;

  /// La sacudida de cámara al aparecer el jefe.
  static const shakeSeconds = 0.5;
  static const shakeAmplitude = 10.0;

  final Map<int, PestComponent> _pests = {};
  final Map<int, GuardianComponent> _guardians = {};
  final Map<int, ProjectileComponent> _projectiles = {};
  final Map<String, SlotComponent> _slots = {};
  final RangeComponent _range = RangeComponent();
  EventSubscription? _subscription;
  bool _changed = false;

  /// Lo último que se avisó de la cuenta regresiva (ver [update]).
  ({int? seconds, int bonus})? _countdown;

  Map<String, Image> _images = const {};
  final Map<SpriteDef, SpriteAnimation?> _animations = {};

  /// Daño recibido por cada plaga desde el último número mostrado.
  final Map<int, double> _pendingDamage = {};
  double _sinceDamageNumbers = 0;
  int _damageNumbers = 0;

  final math.Random _random = math.Random(7);
  final Vector2 _cameraCenter = Vector2.zero();
  double _shake = 0;

  bool get isShaking => _shake > 0;

  DebugWorldOverlay? _debugWorld;
  DebugStatsOverlay? _debugStats;

  /// La superposición de depuración: caminos, alcances, FPS y conteos (la
  /// enciende el panel de desarrollo, nunca en release).
  bool get debugOverlay => _debugWorld != null;

  set debugOverlay(bool on) {
    if (on == debugOverlay) return;
    if (!on) {
      _debugWorld?.removeFromParent();
      _debugStats?.removeFromParent();
      _debugWorld = _debugStats = null;
      return;
    }
    world.add(
      _debugWorld = DebugWorldOverlay(
        level: level,
        simulation: simulation,
        tileSize: tileSize,
      ),
    );
    camera.viewport.add(
      _debugStats = DebugStatsOverlay(
        counts: () =>
            '${_pests.length} plagas · ${_projectiles.length} proyectiles · '
            '${world.children.length} componentes',
      ),
    );
  }

  @override
  Color backgroundColor() => BattleColors.letterbox;

  @override
  Future<void> onLoad() async {
    final map = await battleAssets.loadMap(level);
    _images = await battleAssets.loadImages({
      for (final sprite in sprites) sprite.image,
    });
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

    _cameraCenter.setValues(mapSize.width / 2, mapSize.height / 2);
    camera.viewfinder
      ..anchor = Anchor.center
      ..position = _cameraCenter.clone();
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

    // La cuenta regresiva avanza sin eventos: se avisa cuando cambia lo que
    // muestra el HUD (los segundos o el bono), no en cada tick.
    final ticks = simulation.nextWaveCountdownTicks;
    final countdown = (
      seconds: ticks == null ? null : ticksToWholeSeconds(ticks),
      bonus: simulation.earlyCallBonus,
    );
    if (countdown != _countdown) {
      _countdown = countdown;
      _changed = true;
    }

    _showDamageNumbers(dt);
    _updateShake(dt);

    if (_changed) {
      _changed = false;
      onChanged?.call();
    }
  }

  /// La animación de [sprite] con su imagen ya cargada, o `null` (no tiene
  /// sprite o la imagen no se pudo cargar: se dibuja la forma).
  SpriteAnimation? animationFor(SpriteDef? sprite) {
    if (sprite == null) return null;
    return _animations.putIfAbsent(sprite, () {
      final image = _images[sprite.image];
      if (image == null) return null;
      return SpriteAnimation.fromFrameData(
        image,
        SpriteAnimationData.sequenced(
          amount: sprite.frames,
          stepTime: 1 / sprite.fps,
          textureSize: Vector2(
            image.width / sprite.frames,
            image.height.toDouble(),
          ),
        ),
      );
    });
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
          _pests[pestId] = PestComponent(
            view: view,
            tileSize: tileSize,
            animation: animationFor(view.def.sprite),
          ),
        );
        if (view.def.boss && !reduceMotion) _shake = shakeSeconds;
      case CollcaDamaged(:final pestId):
        _pests.remove(pestId)?.removeFromParent();
        _changed = true;
      case PestDefeated(:final pestId):
        final pest = _pests.remove(pestId);
        if (pest != null) {
          pest.removeFromParent();
          _burst(pest);
        }
        _pendingDamage.remove(pestId);
      case PestDamaged(:final pestId, :final amount):
        _pests[pestId]?.flash();
        if (showDamageNumbers) {
          _pendingDamage[pestId] = (_pendingDamage[pestId] ?? 0) + amount;
        }
      case GuardianBuilt(:final guardianId):
        final view = simulation.guardians.firstWhere(
          (guardian) => guardian.id == guardianId,
        );
        world.add(
          _guardians[guardianId] = GuardianComponent(
            view: view,
            tileSize: tileSize,
            label: labelFor?.call(view.def.id) ?? view.def.id[0].toUpperCase(),
            animationFor: animationFor,
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
      case WaveCompleted():
        break;
    }
  }

  /// Muestra, cada [damageNumberInterval], el daño acumulado de cada plaga.
  void _showDamageNumbers(double dt) {
    _sinceDamageNumbers += dt;
    if (_sinceDamageNumbers < damageNumberInterval) return;
    _sinceDamageNumbers = 0;
    for (final MapEntry(key: pestId, value: damage) in _pendingDamage.entries) {
      final pest = _pests[pestId];
      if (pest == null || damage < 0.5) continue;
      if (_damageNumbers >= maxDamageNumbers) break;
      _damageNumbers++;
      final number = damageNumberPool.acquire()
        ..start(
          text: '${damage.round()}',
          at: pest.position - Vector2(0, pest.size.y),
        );
      unawaited(number.removed.then((_) => _damageNumbers--));
      world.add(number);
    }
    _pendingDamage.clear();
  }

  /// Unas partículas del color de la plaga derrotada.
  void _burst(PestComponent pest) {
    if (world.children.whereType<ParticleSystemComponent>().length >=
        maxBursts) {
      return;
    }
    final paint = Paint()
      ..color = colorFor(pest.view.def.id, pest.view.def.color);
    world.add(
      ParticleSystemComponent(
        position: pest.position.clone(),
        priority: 30,
        particle: Particle.generate(
          count: pest.view.def.boss ? 24 : 10,
          lifespan: 0.45,
          generator: (_) {
            final angle = _random.nextDouble() * 2 * math.pi;
            final speed = 40 + _random.nextDouble() * 80;
            return AcceleratedParticle(
              speed: Vector2(math.cos(angle), math.sin(angle)) * speed,
              acceleration: Vector2(0, 120),
              child: CircleParticle(radius: 3, paint: paint),
            );
          },
        ),
      ),
    );
  }

  /// Sacude la cámara mientras dure [_shake], cada vez menos.
  void _updateShake(double dt) {
    if (_shake <= 0) return;
    _shake = math.max(0, _shake - dt);
    final strength = shakeAmplitude * _shake / shakeSeconds;
    final t = _shake * 60;
    camera.viewfinder.position = _cameraCenter.clone()
      ..add(Vector2(math.sin(t * 1.7), math.cos(t * 1.3)) * strength);
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
