import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show FontWeight, TextStyle;
import 'package:guardianes_chacra/features/battle/domain/engine/simulation.dart';
import 'package:guardianes_chacra/features/content/domain/level_def.dart';

final Paint _pathPaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 3
  ..color = const Color(0xCCFF00FF);
final Paint _rangePaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 2
  ..color = const Color(0xAA00E5FF);

/// Superposición de depuración, en el mundo: los caminos del nivel y el
/// alcance de cada guardián. Solo se agrega fuera de release.
class DebugWorldOverlay extends Component {
  new({required this.level, required this.simulation, required this.tileSize})
    : super(priority: 50);

  final LevelDef level;
  final Simulation simulation;
  final double tileSize;

  late final List<Path> _paths = [
    for (final path in level.map.paths)
      Path()..addPolygon([
        for (final point in path.points)
          Offset(point.x * tileSize, point.y * tileSize),
      ], false),
  ];

  @override
  void render(Canvas canvas) {
    for (final path in _paths) {
      canvas.drawPath(path, _pathPaint);
    }
    for (final guardian in simulation.guardians) {
      canvas.drawCircle(
        Offset(guardian.position.x * tileSize, guardian.position.y * tileSize),
        guardian.range * tileSize,
        _rangePaint,
      );
    }
  }
}

/// Superposición de depuración, fija en la pantalla: FPS y cuántas cosas
/// hay en juego. [counts] se lee cada medio segundo.
class DebugStatsOverlay extends PositionComponent {
  new({required this.counts}) : super(position: Vector2(8, 60), priority: 100);

  final String Function() counts;

  final FpsComponent _fps = FpsComponent();
  final TextComponent _text = TextComponent(
    textRenderer: TextPaint(
      style: const TextStyle(
        color: Color(0xFFFFFF00),
        fontSize: 14,
        fontWeight: FontWeight.bold,
        backgroundColor: Color(0xAA000000),
      ),
    ),
  );
  double _sinceUpdate = 1;

  @override
  Future<void> onLoad() => addAll([_fps, _text]);

  @override
  void update(double dt) {
    super.update(dt);
    _sinceUpdate += dt;
    if (_sinceUpdate < 0.5) return;
    _sinceUpdate = 0;
    _text.text = ' ${_fps.fps.toStringAsFixed(0)} FPS · ${counts()} ';
  }
}
