import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:guardianes_chacra/app/rive/rive_curtain.dart';

/// La ruta de las pantallas del juego. Al ir y al volver, la cortina de
/// tejido ([RiveCurtain]) tapa la pantalla, la de abajo se cambia por la
/// otra justo a la mitad (con la cortina cerrada) y la cortina se abre:
/// [duration] en total. Con "menos movimiento", un fundido de
/// [calmDuration] sin cortina.
///
/// Al ir, la pantalla nueva se arma recién con la cortina cerrada: el
/// cuadro que tarda en armarla (en el Redmi, 150–200 ms el bestiario o la
/// batalla) queda tapado. Y el reloj de la ruta es un [SteadyClock]: un
/// cuadro lento retrasa la cortina en vez de saltarse el cierre o la
/// apertura.
///
/// Mientras la pantalla que llega está tapada no recibe toques, ni tampoco
/// la de abajo: unos 200 ms al ir y otros 200 al volver.
class CurtainRoute<T> extends PageRoute<T> {
  new({required this.builder, super.settings});

  final WidgetBuilder builder;

  static const duration = Duration(milliseconds: 400);
  static const calmDuration = Duration(milliseconds: 150);

  /// Lo más que avanza la ruta en un cuadro (dos cuadros a 60 Hz).
  static const maxStep = Duration(milliseconds: 34);

  /// Si la ruta usa el [SteadyClock]. En debug (y en los tests, que
  /// adelantan el tiempo de a saltos con `pump`) usa el reloj normal.
  static bool steadyClock = !kDebugMode;

  /// "Menos movimiento", leído sin suscribirse (la duración se fija al
  /// empujar la ruta).
  bool get _calm =>
      navigator?.context
          .getInheritedWidgetOfExactType<MediaQuery>()
          ?.data
          .disableAnimations ??
      false;

  @override
  Duration get transitionDuration => _calm ? calmDuration : duration;

  @override
  Duration get reverseTransitionDuration => transitionDuration;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  AnimationController createAnimationController() {
    if (!steadyClock) return super.createAnimationController();
    assert(
      !debugTransitionCompleted(),
      'No se puede volver a usar una $runtimeType ya liberada.',
    );
    return AnimationController(
      duration: transitionDuration,
      reverseDuration: reverseTransitionDuration,
      debugLabel: debugLabel,
      vsync: _SteadyVsync(navigator!),
    );
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => Semantics(
    scopesRoute: true,
    explicitChildNodes: true,
    child: builder(context),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => MediaQuery.disableAnimationsOf(context)
      ? FadeTransition(opacity: animation, child: child)
      : _CurtainTransition(animation: animation, child: child);
}

/// Un reloj que avanza lo que pasó entre un cuadro y otro, pero como mucho
/// [maxStep]: si un cuadro tarda 200 ms, la animación avanza solo 34 ms y
/// sigue desde ahí en vez de saltar.
class SteadyClock {
  new({this.maxStep = CurtainRoute.maxStep});

  final Duration maxStep;
  Duration _last = Duration.zero;
  Duration _steady = Duration.zero;

  /// El tiempo del reloj para un cuadro con [elapsed] desde que arrancó el
  /// ticker (que vuelve a 0 cada vez que se arranca).
  Duration tick(Duration elapsed) {
    if (elapsed < _last) {
      _last = Duration.zero;
      _steady = Duration.zero;
    }
    final step = elapsed - _last;
    _steady += step > maxStep ? maxStep : step;
    _last = elapsed;
    return _steady;
  }
}

/// Los tickers del navegador, pero con el tiempo de un [SteadyClock].
class _SteadyVsync implements TickerProvider {
  const new(this.inner);

  final TickerProvider inner;

  @override
  Ticker createTicker(TickerCallback onTick) {
    final clock = SteadyClock();
    return inner.createTicker((elapsed) => onTick(clock.tick(elapsed)));
  }
}

/// La pantalla, que se arma con la cortina cerrada y se ve de la mitad de
/// la ruta en adelante, y la cortina encima mientras la ruta se anima.
class _CurtainTransition extends StatefulWidget {
  const new({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  State<_CurtainTransition> createState() => _CurtainTransitionState();
}

class _CurtainTransitionState extends State<_CurtainTransition> {
  /// Si la pantalla ya se armó. Una vez armada, queda.
  bool _built = false;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.animation,
    child: widget.child,
    builder: (context, child) {
      final animation = widget.animation;
      final status = animation.status;
      final animating = status.isAnimating;
      final hidden = animation.value < 0.5;
      // En el primer cuadro de la ruta, el HeroController la arma fuera de
      // la pantalla (con la animación terminada) para medir los Hero: ahí
      // tampoco se arma (el juego no tiene Hero).
      final offstage = ModalRoute.of(context)?.offstage ?? false;
      _built =
          _built ||
          (!offstage &&
              (!animating ||
                  status == AnimationStatus.reverse ||
                  animation.value >= RiveCurtain.closedFrom));
      return Stack(
        fit: StackFit.expand,
        children: [
          AbsorbPointer(
            // Al ir, mientras la pantalla nueva está tapada; al volver,
            // mientras la cortina tapa la que se va.
            absorbing:
                animating && (status == AnimationStatus.forward) == hidden,
            child: _built
                ? Opacity(opacity: hidden ? 0 : 1, child: child)
                : const SizedBox.expand(),
          ),
          if (animating) RiveCurtain(progress: animation),
        ],
      );
    },
  );
}
