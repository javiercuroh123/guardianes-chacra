import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/app/widgets/stars_row.dart';
import 'package:guardianes_chacra/dev/dev_options.dart';
import 'package:guardianes_chacra/features/content/domain/content_texts.dart';
import 'package:guardianes_chacra/features/content/domain/game_content.dart';
import 'package:guardianes_chacra/features/content/domain/level_def.dart';
import 'package:guardianes_chacra/features/content/presentation/content_providers.dart';
import 'package:guardianes_chacra/features/level_select/presentation/level_preview_screen.dart';
import 'package:guardianes_chacra/features/level_select/presentation/valley_layout.dart';
import 'package:guardianes_chacra/features/progress/domain/progress.dart';
import 'package:guardianes_chacra/features/progress/domain/progression.dart';
import 'package:guardianes_chacra/features/progress/presentation/progress_providers.dart';
import 'package:guardianes_chacra/l10n/app_localizations.dart';

/// Selección de nivel como un mapa del valle: cada nivel es un círculo en
/// el sendero, con sus mejores estrellas o un candado.
class LevelSelectScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.valleyTitle)),
      body: switch (ref.watch(gameContentProvider)) {
        AsyncData(:final value) => _Valley(
          content: value,
          progress: ref.watch(progressProvider),
          unlockAll:
              devToolsEnabled &&
              ref.watch(devOptionsProvider.select((dev) => dev.unlockAll)),
        ),
        AsyncError(:final error) => Center(
          child: Text(l10n.contentLoadError('$error')),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Valley extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colors = GameColors.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context);
    final progression = Progression.of(content);
    final fractions = valleyNodePositions(content.levels.length);
    String levelName(String id) =>
        content.texts.text(ContentTexts.levelName(id), language: language);

    /// `null` si se puede jugar; si no, qué falta según su regla.
    String? lockedMessage(LevelDef level) {
      if (unlockAll || progression.canPlay(progress, level.id)) return null;
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final centers = [
          for (final f in fractions)
            Offset(f.dx * size.width, f.dy * size.height),
        ];
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _ValleyPainter(colors: colors, path: centers),
              ),
            ),
            for (final (index, level) in content.levels.indexed)
              Positioned(
                left: centers[index].dx - _LevelNode.width / 2,
                top: centers[index].dy - _LevelNode.circle / 2,
                child: _LevelNode(
                  key: ValueKey('level-${level.id}'),
                  number: index + 1,
                  name: levelName(level.id),
                  stars: progress.starsOf(level.id),
                  lockedMessage: lockedMessage(level),
                  onOpen: () {
                    // El aviso de "bloqueado" es de toda la app: si sigue
                    // visible, taparía los botones de la vista previa.
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => LevelPreviewScreen(levelId: level.id),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LevelNode extends StatelessWidget {
  const new({
    required this.number,
    required this.name,
    required this.stars,
    required this.lockedMessage,
    required this.onOpen,
    super.key,
  });

  static const double circle = 64;
  static const double width = 150;

  final int number;
  final String name;
  final int stars;

  /// Qué falta para abrirlo, o `null` si está abierto.
  final String? lockedMessage;
  final VoidCallback onOpen;

  bool get unlocked => lockedMessage == null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = GameColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      enabled: unlocked,
      label: unlocked
          ? l10n.valleyLevelSemantics(name, stars)
          : l10n.valleyLockedSemantics(name),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: switch (lockedMessage) {
          null => onOpen,
          final message =>
            () => ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message))),
        },
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: circle,
                height: circle,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: unlocked ? scheme.primary : colors.locked,
                  // Contorno oscuro, como en los dibujos de la interfaz.
                  border: Border.all(color: scheme.onSurface, width: 3),
                ),
                alignment: Alignment.center,
                child: unlocked
                    ? Text(
                        '$number',
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : const Icon(Icons.lock_rounded, color: Colors.white),
              ),
              const SizedBox(height: 4),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.hud,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: Column(
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onHud,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (unlocked) StarsRow(stars: stars, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// El fondo del valle: cielo, montañas con nieve, pasto y el sendero que
/// une los niveles.
class _ValleyPainter extends CustomPainter {
  new({required this.colors, required this.path});

  final GameColors colors;
  final List<Offset> path;

  @override
  void paint(Canvas canvas, Size size) {
    final horizon = size.height * 0.45;
    canvas
      ..drawRect(
        Rect.fromLTWH(0, 0, size.width, horizon),
        Paint()..color = colors.valleySky,
      )
      ..drawRect(
        Rect.fromLTWH(0, horizon, size.width, size.height - horizon),
        Paint()..color = colors.valleyGrass,
      );

    final mountain = Paint()..color = colors.valleyMountain;
    final snow = Paint()..color = Colors.white;
    for (final (x, height) in [(0.2, 0.32), (0.5, 0.4), (0.82, 0.3)]) {
      final peak = Offset(size.width * x, horizon - size.height * height);
      final half = size.width * 0.2;
      canvas.drawPath(
        Path()
          ..moveTo(peak.dx - half, horizon)
          ..lineTo(peak.dx, peak.dy)
          ..lineTo(peak.dx + half, horizon)
          ..close(),
        mountain,
      );
      final cap = (horizon - peak.dy) * 0.25;
      canvas.drawPath(
        Path()
          ..moveTo(peak.dx - half * 0.25, peak.dy + cap)
          ..lineTo(peak.dx, peak.dy)
          ..lineTo(peak.dx + half * 0.25, peak.dy + cap)
          ..close(),
        snow,
      );
    }

    if (path.length > 1) {
      final trail = Path()..moveTo(path.first.dx, path.first.dy);
      for (var i = 1; i < path.length; i++) {
        final from = path[i - 1];
        final to = path[i];
        trail.quadraticBezierTo((from.dx + to.dx) / 2, from.dy, to.dx, to.dy);
      }
      canvas.drawPath(
        trail,
        Paint()
          ..color = colors.valleyPath
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ValleyPainter old) =>
      old.colors != colors ||
      old.path.length != path.length ||
      !_samePoints(old.path, path);

  static bool _samePoints(List<Offset> a, List<Offset> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
