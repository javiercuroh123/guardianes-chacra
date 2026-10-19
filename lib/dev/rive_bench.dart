import 'dart:async';

import 'package:flutter/material.dart';
import 'package:guardianes_chacra/app/rive/rive_counter.dart';
import 'package:guardianes_chacra/dev/dev_options.dart';
import 'package:rive/rive.dart' as rive;

/// Prueba de rendimiento de la Fase 1 de la interfaz (solo debug y
/// profile): contadores de Rive encima de la partida, unos cambiando a cada
/// rato y otros quietos, para ver en el teléfono cuánto cuestan los widgets
/// de Rive. Con [sharedTexture], todos dibujan en una sola textura
/// (`RivePanel`, solo con el renderer de Rive); sin ella, cada uno en la
/// suya.
class RiveBench extends StatefulWidget {
  const new({required this.mode, this.sharedTexture = false, super.key});

  final RiveBenchMode mode;
  final bool sharedTexture;

  @override
  State<RiveBench> createState() => _RiveBenchState();
}

class _RiveBenchState extends State<RiveBench> {
  late final Timer _timer;
  var _tick = 0;

  @override
  void initState() {
    super.initState();
    // Más seguido que la animación (0,4 s): los que cambian siempre se
    // están animando.
    _timer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => setState(() => _tick++),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  int _valueOf(int i) {
    if (i >= widget.mode.animated) return 100 + i;
    // Unos suben y otros bajan.
    return i.isEven ? _tick * 3 + i : 999 - _tick * 2 - i;
  }

  @override
  Widget build(BuildContext context) {
    final row = Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (var i = 0; i < widget.mode.count; i++)
          RiveCounter(
            value: _valueOf(i),
            semanticsLabel: 'Prueba $i',
            useSharedTexture: widget.sharedTexture,
            fallback: Text('$i', style: const TextStyle(color: Colors.white)),
          ),
      ],
    );
    return IgnorePointer(
      child: widget.sharedTexture ? rive.RivePanel(child: row) : row,
    );
  }
}
