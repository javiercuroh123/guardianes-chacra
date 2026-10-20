import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/rive/rive_icons.dart';
import 'package:guardianes_chacra/app/rive/rive_ui.dart';
import 'package:rive/rive.dart' as rive;

/// Un artboard del archivo de Rive atado a su view model: lo que necesita
/// cada widget envoltorio (botón, contador, estrella…).
///
/// Las propiedades se piden con [string], [boolean], etc. Si falta alguna
/// (alguien la renombró en el editor), lanzan [RiveContractException] y el
/// envoltorio cae a su respaldo de Flutter en vez de quedar a medias.
class RiveBinding {
  new _(this.controller, this.viewModel);

  final rive.RiveWidgetController controller;
  final rive.ViewModelInstance viewModel;

  /// La propiedad que apaga los bucles y los movimientos grandes.
  static const reduceMotion = 'reduceMotion';

  /// `null` si el artboard no está, no tiene la state machine `Main` o no
  /// tiene view model.
  static RiveBinding? tryCreate(rive.File file, String artboard) {
    rive.RiveWidgetController? controller;
    try {
      controller = rive.RiveWidgetController(
        file,
        artboardSelector: rive.ArtboardSelector.byName(artboard),
        stateMachineSelector: rive.StateMachineSelector.byName(
          RiveUi.stateMachine,
        ),
      );
      return RiveBinding._(
        controller,
        controller.dataBind(rive.DataBind.auto()),
      );
    } on Object catch (error) {
      debugPrint('Rive: $artboard no está completo ($error); uso el respaldo.');
      controller?.dispose();
      return null;
    }
  }

  rive.ViewModelInstanceString string(String path) =>
      _need(viewModel.string(path), path);

  rive.ViewModelInstanceNumber number(String path) =>
      _need(viewModel.number(path), path);

  rive.ViewModelInstanceBoolean boolean(String path) =>
      _need(viewModel.boolean(path), path);

  rive.ViewModelInstanceTrigger trigger(String path) =>
      _need(viewModel.trigger(path), path);

  rive.ViewModelInstanceEnum enumerator(String path) =>
      _need(viewModel.enumerator(path), path);

  /// El ícono del `IconSet` anidado en la propiedad [path].
  rive.ViewModelInstanceEnum icon(String path) =>
      enumerator('$path/${IconSetRive.icon}');

  T _need<T>(T? property, String path) =>
      property ?? (throw RiveContractException('falta la propiedad "$path"'));

  /// El widget que lo dibuja. Los toques los recibe Flutter (el envoltorio),
  /// no Rive.
  Widget widget({rive.Fit fit = rive.Fit.contain, double layoutScale = 1}) =>
      rive.RiveWidget(
        controller: controller,
        fit: fit,
        layoutScaleFactor: layoutScale,
        hitTestBehavior: rive.RiveHitTestBehavior.none,
      );

  void dispose() {
    viewModel.dispose();
    controller.dispose();
  }
}

/// Lleva un número del view model a su valor nuevo poco a poco, cuadro a
/// cuadro. Rive no anima los layouts cuando el valor llega por data binding
/// (la pastilla del selector y el relleno de la barra saltaban), así que el
/// movimiento lo hace Flutter y Rive solo dibuja cada paso.
class RiveNumberTween {
  new({
    required TickerProvider vsync,
    required Duration duration,
    this.curve = Curves.easeOutCubic,
  }) : _controller = AnimationController(vsync: vsync, duration: duration) {
    _controller.addListener(_tick);
  }

  final Curve curve;
  final AnimationController _controller;
  rive.ViewModelInstanceNumber? _number;
  double _from = 0;
  double _to = 0;

  /// Empieza en [value], sin animar.
  void attach(rive.ViewModelInstanceNumber number, double value) {
    _number = number..value = value;
    _from = value;
    _to = value;
  }

  /// Va hasta [value]; con [instant] (menos movimiento), de golpe.
  void animateTo(double value, {required bool instant}) {
    final number = _number;
    if (number == null || value == _to) return;
    _to = value;
    if (instant) {
      _controller.stop();
      number.value = value;
      return;
    }
    _from = number.value;
    _controller.forward(from: 0);
  }

  void _tick() => _number?.value =
      _from + (_to - _from) * curve.transform(_controller.value);

  void dispose() => _controller.dispose();
}

/// Al archivo de Rive le falta algo que el código busca por nombre.
class RiveContractException implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => message;
}

/// El estado de un envoltorio de Rive: al montarse crea el [RiveBinding]
/// (si el archivo está cargado) y le pone los valores iniciales con [bind];
/// al final lo libera. Sin archivo, o si falta algo, [binding] queda en
/// `null` y el widget dibuja su respaldo.
///
/// Si el view model tiene `reduceMotion`, se llena sola desde
/// `MediaQuery.disableAnimations` y se actualiza si cambia.
mixin RiveBindingState<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  RiveBinding? binding;

  /// El artboard que dibuja este widget.
  String get artboardName;

  /// Pone los valores iniciales (los textos, el ícono…). Puede lanzar
  /// [RiveContractException] si falta una propiedad: entonces se usa el
  /// respaldo.
  void bind(RiveBinding binding);

  @override
  void initState() {
    super.initState();
    final file = ref.read(riveFileProvider);
    if (file == null) return;
    final created = RiveBinding.tryCreate(file, artboardName);
    if (created == null) return;
    try {
      bind(created);
      binding = created;
    } on RiveContractException catch (error) {
      debugPrint('Rive: $artboardName no está completo ($error).');
      created.dispose();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    binding?.viewModel.boolean(RiveBinding.reduceMotion)?.value =
        MediaQuery.disableAnimationsOf(context);
  }

  @override
  void dispose() {
    binding?.dispose();
    super.dispose();
  }
}
