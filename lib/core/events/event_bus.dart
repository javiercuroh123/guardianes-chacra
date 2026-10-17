/// Bus de eventos sincrónico: quien publica no conoce a quien escucha.
///
/// La simulación publica sus eventos y los gráficos, el audio, los logros o
/// la analítica se suscriben por tipo. Es sincrónico (sin `Stream`) para que
/// cada evento se procese dentro del mismo tick en que ocurrió y el orden
/// sea siempre el mismo.
class EventBus<E> {
  // Se reemplaza la lista en cada cambio (copia al escribir): así se puede
  // suscribir o cancelar mientras se entrega un evento sin romper el bucle.
  List<_Handler<E>> _handlers = const [];

  /// Llama a [handler] con cada evento de tipo [T] (o de sus subtipos).
  EventSubscription on<T extends E>(void Function(T event) handler) {
    final entry = _Handler<E>(
      accepts: (event) => event is T,
      deliver: (event) => handler(event as T),
    );
    _handlers = [..._handlers, entry];
    return _Subscription(() {
      entry.active = false;
      _handlers = [
        for (final other in _handlers)
          if (!identical(other, entry)) other,
      ];
    });
  }

  void publish(E event) {
    for (final entry in _handlers) {
      // Un suscriptor anterior pudo cancelar este durante la misma entrega.
      if (entry.active && entry.accepts(event)) {
        entry.deliver(event);
      }
    }
  }
}

/// Permite dejar de recibir eventos.
abstract interface class EventSubscription {
  void cancel();
}

class _Handler<E> {
  new({required this.accepts, required this.deliver});

  final bool Function(E event) accepts;
  final void Function(E event) deliver;
  bool active = true;
}

class _Subscription implements EventSubscription {
  new(this._onCancel);

  final void Function() _onCancel;
  bool _cancelled = false;

  @override
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _onCancel();
  }
}
