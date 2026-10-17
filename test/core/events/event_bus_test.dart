import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/core/events/event_bus.dart';

sealed class _Event {
  const new(this.value);
  final int value;
}

final class _Ping extends _Event {
  const new(super.value);
}

final class _Pong extends _Event {
  const new(super.value);
}

void main() {
  late EventBus<_Event> bus;

  setUp(() => bus = EventBus<_Event>());

  test('cada suscriptor recibe solo los eventos de su tipo', () {
    final pings = <int>[];
    final pongs = <int>[];
    bus
      ..on<_Ping>((event) => pings.add(event.value))
      ..on<_Pong>((event) => pongs.add(event.value))
      ..publish(const _Ping(1))
      ..publish(const _Pong(2))
      ..publish(const _Ping(3));

    expect(pings, [1, 3]);
    expect(pongs, [2]);
  });

  test('suscribirse al tipo base recibe todos los eventos en orden', () {
    final all = <_Event>[];
    bus
      ..on<_Event>(all.add)
      ..publish(const _Ping(1))
      ..publish(const _Pong(2));

    expect(all.map((event) => event.value), [1, 2]);
  });

  test('los suscriptores se llaman en el orden en que se suscribieron', () {
    final calls = <String>[];
    bus
      ..on<_Ping>((_) => calls.add('primero'))
      ..on<_Ping>((_) => calls.add('segundo'))
      ..publish(const _Ping(1));

    expect(calls, ['primero', 'segundo']);
  });

  test('cancelar la suscripción deja de entregar eventos', () {
    final received = <int>[];
    final subscription = bus.on<_Ping>((event) => received.add(event.value));

    bus.publish(const _Ping(1));
    subscription.cancel();
    bus.publish(const _Ping(2));

    expect(received, [1]);
  });

  test('cancelar durante una entrega no salta a los demás suscriptores', () {
    final calls = <String>[];
    late final EventSubscription first;
    first = bus.on<_Ping>((_) {
      calls.add('primero');
      first.cancel();
    });
    bus
      ..on<_Ping>((_) => calls.add('segundo'))
      ..publish(const _Ping(1))
      ..publish(const _Ping(2));

    expect(calls, ['primero', 'segundo', 'segundo']);
  });
}
