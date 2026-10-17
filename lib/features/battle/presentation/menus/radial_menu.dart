import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Un botón redondo del menú radial: un círculo de color con una letra o
/// un ícono y, debajo, un texto corto (el costo, el reembolso…).
///
/// Sin [onTap] se ve gris y no responde (por ejemplo, si no alcanza el
/// maíz).
class RadialButton extends StatelessWidget {
  const new({
    required this.caption,
    required this.color,
    required this.semanticsLabel,
    this.label,
    this.icon,
    this.onTap,
    this.selected = false,
    super.key,
  });

  static const double diameter = 46;
  static const double width = 72;

  final String? label;
  final IconData? icon;
  final String caption;
  final Color color;
  final String semanticsLabel;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: semanticsLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: diameter,
                height: diameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: enabled ? color : const Color(0xFF6E6E6E),
                  border: Border.all(
                    color: selected ? Colors.white : const Color(0xCC1B1B1B),
                    width: selected ? 3 : 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: icon != null
                    ? Icon(icon, color: Colors.white, size: 24)
                    : Text(
                        label ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 2),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xCC1B1B1B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
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

/// Coloca [children] en círculo alrededor de [center] (en coordenadas del
/// área de [bounds]), corriéndolo si hace falta para que el menú no se
/// salga de la pantalla. Solo los botones reciben toques: el resto pasa al
/// juego que está debajo.
class RadialMenu extends StatelessWidget {
  const new({
    required this.center,
    required this.bounds,
    required this.children,
    this.title,
    this.hint,
    this.radius = 62,
    super.key,
  });

  final Offset center;
  final Size bounds;
  final List<Widget> children;
  final String? title;
  final String? hint;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final margin = radius + RadialButton.diameter;
    double clampTo(double value, double size) =>
        size <= margin * 2 ? size / 2 : value.clamp(margin, size - margin);
    final x = clampTo(center.dx, bounds.width);
    final y = clampTo(center.dy, bounds.height);

    // Empieza arriba y sigue en el sentido de las agujas del reloj.
    double angleOf(int index) =>
        -math.pi / 2 + 2 * math.pi * index / children.length;

    return Stack(
      children: [
        for (final (index, child) in children.indexed)
          Positioned(
            left:
                x +
                radius * math.cos(angleOf(index)) -
                RadialButton.width / 2,
            top:
                y +
                radius * math.sin(angleOf(index)) -
                RadialButton.diameter / 2,
            child: child,
          ),
        if (title != null || hint != null)
          Positioned(
            left: x - 90,
            width: 180,
            top: y + radius + RadialButton.diameter / 2 + 18,
            child: _Caption(lines: [?title, ?hint]),
          ),
      ],
    );
  }
}

class _Caption extends StatelessWidget {
  const new({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC1B1B1B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          lines.join('\n'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    ),
  );
}
