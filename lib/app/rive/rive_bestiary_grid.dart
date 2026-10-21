import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';
import 'package:guardianes_chacra/app/rive/rive_pest_card.dart';
import 'package:guardianes_chacra/app/rive/rive_portrait.dart';
import 'package:guardianes_chacra/app/rive/rive_ui.dart';
import 'package:rive/rive.dart' as rive;

/// Los nombres de los artboards `BestiaryGrid` y `BestiaryEntry` (ver
/// `docs/UI_RIVE.md`).
abstract final class BestiaryGridRive {
  static const artboard = 'BestiaryGrid';
  static const viewModel = 'BestiaryGrid';

  /// La lista del Component List: una instancia de `BestiaryEntry` por
  /// ficha.
  static const entries = 'entries';

  static const entryArtboard = 'BestiaryEntry';
  static const entryViewModel = 'BestiaryEntry';
  static const name = 'name';

  /// El fondo de la ventana del retrato.
  static const color = 'color';

  /// Qué retrato se ve: el de la plaga (`pest`) o el del guardián
  /// (`guardian`).
  static const isGuardian = 'isGuardian';
  static const pest = 'pest';
  static const guardian = 'guardian';

  /// El marco dorado de la ficha elegida.
  static const selected = 'selected';

  /// La insignia "¡Nuevo!".
  static const isNew = 'isNew';
  static const newLabel = 'newLabel';

  /// Boca abajo (el dorso de madera con "?"): descubierta pero sin abrir.
  static const faceDown = 'faceDown';

  /// Se da vuelta.
  static const reveal = 'reveal';

  /// Lo que mide una ficha y el espacio entre fichas (el layout del
  /// artboard las acomoda en filas).
  static const Size entrySize = Size(112, 136);
  static const double gap = 8;
}

/// Una ficha de la grilla del Bestiario.
@immutable
class BestiaryEntryData {
  const new({
    required this.id,
    required this.name,
    required this.color,
    required this.semanticsLabel,
    this.isGuardian = false,
    this.locked = false,
    this.faceDown = false,
    this.isNew = false,
  });

  final String id;

  /// "???" si todavía no se descubrió.
  final String name;

  /// El color de la plaga o del guardián (la ventana lleva un tono claro).
  final Color color;
  final String semanticsLabel;
  final bool isGuardian;
  final bool locked;
  final bool faceDown;
  final bool isNew;
}

/// La grilla del Bestiario: un solo artboard de Rive con un Component List
/// que dibuja una `BestiaryEntry` por ficha, en [columns] columnas. Los
/// toques los recibe Flutter (la misma cuenta que el layout de Rive) y cada
/// ficha tiene su Semantics y su Key (`<keyPrefix><id>`).
///
/// Cuando una ficha pasa de boca abajo a boca arriba, se da vuelta. Sin el
/// archivo de Rive, tarjetas de Flutter con lo mismo.
class RiveBestiaryGrid extends ConsumerStatefulWidget {
  const new({
    required this.entries,
    required this.selectedId,
    required this.columns,
    required this.newLabel,
    required this.keyPrefix,
    required this.onTap,
    super.key,
  });

  final List<BestiaryEntryData> entries;
  final String? selectedId;
  final int columns;
  final String newLabel;
  final String keyPrefix;
  final ValueChanged<String> onTap;

  int get rows => (entries.length / columns).ceil();

  /// Lo que mide la grilla entera en unidades del artboard.
  Size get gridSize {
    const entry = BestiaryGridRive.entrySize;
    const gap = BestiaryGridRive.gap;
    return Size(
      columns * entry.width + (columns - 1) * gap,
      rows * entry.height + (rows - 1) * gap,
    );
  }

  @override
  ConsumerState<RiveBestiaryGrid> createState() => _RiveBestiaryGridState();
}

class _RiveBestiaryGridState extends ConsumerState<RiveBestiaryGrid>
    with RiveBindingState<RiveBestiaryGrid> {
  rive.ViewModelInstanceList? _list;
  rive.ViewModel? _entryModel;
  final _items = <rive.ViewModelInstance>[];

  @override
  String get artboardName => BestiaryGridRive.artboard;

  @override
  void bind(RiveBinding binding) {
    final list = binding.viewModel.list(BestiaryGridRive.entries);
    final model = ref
        .read(riveFileProvider)
        ?.viewModelByName(BestiaryGridRive.entryViewModel);
    if (list == null || model == null) {
      throw const RiveContractException('falta la lista de fichas');
    }
    _list = list;
    _entryModel = model;
    _rebuild();
  }

  /// Vuelve a llenar la lista (cambiaron las fichas).
  void _rebuild() {
    final list = _list;
    final model = _entryModel;
    if (list == null || model == null) return;
    while (list.length > 0) {
      list.removeAt(list.length - 1);
    }
    for (final item in _items) {
      item.dispose();
    }
    _items.clear();
    for (final entry in widget.entries) {
      final item = model.createInstance();
      if (item == null) {
        throw const RiveContractException('no se pudo crear una ficha');
      }
      _apply(item, entry);
      _items.add(item);
      list.add(item);
    }
    // En initState todavía no se puede leer MediaQuery: lo pone
    // didChangeDependencies.
    if (_calm case final calm?) {
      for (final item in _items) {
        item.boolean(RiveBinding.reduceMotion)?.value = calm;
      }
    }
  }

  void _apply(rive.ViewModelInstance item, BestiaryEntryData entry) {
    item.string(BestiaryGridRive.name)?.value = entry.name;
    item.string(BestiaryGridRive.newLabel)?.value = widget.newLabel;
    item.color(BestiaryGridRive.color)?.value = entry.locked
        ? const Color(0xFFD9D2C5)
        : RivePestCard.windowColor(entry.color);
    item.boolean(BestiaryGridRive.isGuardian)?.value = entry.isGuardian;
    item.boolean(BestiaryGridRive.selected)?.value =
        entry.id == widget.selectedId;
    item.boolean(BestiaryGridRive.isNew)?.value = entry.isNew;
    item.boolean(BestiaryGridRive.faceDown)?.value = entry.faceDown;
    item
        .enumerator('${BestiaryGridRive.pest}/${PestPortraitRive.pest}')
        ?.value = entry.locked || entry.isGuardian
        ? PestPortraitRive.unknown
        : PestPortraitRive.valueFor(entry.id);
    item
        .enumerator('${BestiaryGridRive.guardian}/${PortraitRive.guardian}')
        ?.value = entry.locked || !entry.isGuardian
        ? PortraitRive.unknown
        : PortraitRive.valueFor(entry.id);
  }

  /// "Menos movimiento", una vez leído.
  bool? _calm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final calm = _calm = MediaQuery.disableAnimationsOf(context);
    for (final item in _items) {
      item.boolean(RiveBinding.reduceMotion)?.value = calm;
    }
  }

  @override
  void didUpdateWidget(RiveBestiaryGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (binding == null) return;
    final sameIds =
        oldWidget.entries.length == widget.entries.length &&
        [
          for (var i = 0; i < widget.entries.length; i++)
            oldWidget.entries[i].id == widget.entries[i].id,
        ].every((same) => same);
    if (!sameIds) {
      _rebuild();
      return;
    }
    for (final (index, entry) in widget.entries.indexed) {
      final item = _items[index];
      _apply(item, entry);
      if (oldWidget.entries[index].faceDown && !entry.faceDown) {
        item.trigger(BestiaryGridRive.reveal)?.trigger();
      }
    }
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final grid = widget.gridSize;
      var scale = constraints.maxWidth / grid.width;
      if (constraints.hasBoundedHeight) {
        scale = scale.clamp(0, constraints.maxHeight / grid.height);
      }
      const entry = BestiaryGridRive.entrySize;
      const gap = BestiaryGridRive.gap;
      final binding = this.binding;
      return SizedBox(
        width: grid.width * scale,
        height: grid.height * scale,
        child: Stack(
          children: [
            Positioned.fill(
              child: binding != null
                  ? binding.widget(fit: rive.Fit.layout, layoutScale: scale)
                  : const SizedBox.shrink(),
            ),
            for (final (index, data) in widget.entries.indexed)
              Positioned(
                left: (index % widget.columns) * (entry.width + gap) * scale,
                top: (index ~/ widget.columns) * (entry.height + gap) * scale,
                width: entry.width * scale,
                height: entry.height * scale,
                child: Semantics(
                  container: true,
                  button: true,
                  selected: data.id == widget.selectedId,
                  label: data.semanticsLabel,
                  excludeSemantics: true,
                  child: GestureDetector(
                    key: ValueKey('${widget.keyPrefix}${data.id}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => widget.onTap(data.id),
                    child: binding != null
                        ? const SizedBox.expand()
                        : _FallbackEntry(
                            data: data,
                            selected: data.id == widget.selectedId,
                            newLabel: widget.newLabel,
                          ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

/// La ficha sin Rive: el color, el nombre y "¡Nuevo!".
class _FallbackEntry extends StatelessWidget {
  const new({
    required this.data,
    required this.selected,
    required this.newLabel,
  });

  final BestiaryEntryData data;
  final bool selected;
  final String newLabel;

  @override
  Widget build(BuildContext context) {
    final colors = GameColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.hud,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? colors.star : colors.onHud,
          width: selected ? 4 : 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: data.locked || data.faceDown
                      ? colors.locked
                      : RivePestCard.windowColor(data.color),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: data.locked || data.faceDown
                      ? const Text('?', style: TextStyle(fontSize: 24))
                      : CircleAvatar(radius: 14, backgroundColor: data.color),
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                data.name,
                style: TextStyle(
                  color: colors.onHud,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (data.isNew)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  newLabel,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.tertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
