import 'package:flutter/material.dart';
import 'package:guardianes_chacra/features/battle/presentation/style/battle_palette.dart';
import 'package:guardianes_chacra/features/content/domain/guardian_def.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';

/// La plaga como se ve en la partida (círculo si camina, rombo si vuela),
/// para la vista previa y el Bestiario. Sin [def], una silueta con "?".
class PestIcon extends StatelessWidget {
  const new({
    required this.def,
    this.size = 36,
    this.hidden = false,
    super.key,
  });

  final PestDef def;
  final double size;

  /// Todavía no descubierta: se muestra como silueta.
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final flying = def.tags.contains(PestTag.flying);
    final color = hidden
        ? const Color(0xFF9E9E9E)
        : colorFor(def.id, def.color);
    final body = SizedBox.square(
      dimension: size * (flying ? 0.8 : 0.9),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: flying ? BoxShape.rectangle : BoxShape.circle,
          border: Border.all(color: const Color(0xCC1B1B1B), width: 2),
        ),
        child: hidden
            ? const Center(
                child: Text(
                  '?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    );
    return SizedBox.square(
      dimension: size,
      child: Center(
        // El rombo es un cuadrado girado 45°, como en la partida.
        child: flying ? Transform.rotate(angle: 0.785398, child: body) : body,
      ),
    );
  }
}

/// El guardián como se ve en la partida: un cuadrado de su color con su
/// inicial.
class GuardianIcon extends StatelessWidget {
  const new({
    required this.def,
    required this.label,
    this.size = 36,
    this.hidden = false,
    super.key,
  });

  final GuardianDef def;
  final String label;
  final double size;
  final bool hidden;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: hidden ? const Color(0xFF9E9E9E) : colorFor(def.id, def.color),
        borderRadius: BorderRadius.circular(size * 0.2),
        border: Border.all(color: const Color(0xCC1B1B1B), width: 2),
      ),
      child: Center(
        child: Text(
          hidden ? '?' : label,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
}
