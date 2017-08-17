import 'dart:async';

import 'package:shuttlecock/shuttlecock.dart';

/// Wraps a Future in the monad interface.
class FutureMonad<T> extends Monad<T> implements Future<T> {
  final Future<_Wrapper<T>> _future;

  /// Wraps the provided future.
  FutureMonad(Future<T> future) : _future = future.then((t) => new _Wrapper(t));

  /// Creates a new FutureMonad resolved with a given value
  FutureMonad.of(T value) : _future = new Future.value(new _Wrapper(value));

  // We wrap our internal values in an auxiliary class to avoid auto joining in
  // regular futures.
  FutureMonad._wrapped(Future<_Wrapper<T>> future) : _future = future;

  @override
  FutureMonad<S> app<S>(FutureMonad<Function1<T, S>> app) => app.flatMap(map);

  @override
  StreamMonad<T> asStream() =>
      new StreamMonad(_future.asStream().map((w) => w.value));

  @override
  FutureMonad<T> catchError(Function onError, {bool test(Object error)}) =>
      new FutureMonad(
          _future.catchError(onError, test: test).then((w) => w.value));

  @override
  FutureMonad<S> flatMap<S>(Function1<T, FutureMonad<S>> f) {
    final _completer = new Completer<_Wrapper<S>>();
    _future.then((w) {
      f(w.value).then((s) => _completer.complete(new _Wrapper(s)));
    });
    return new FutureMonad._wrapped(_completer.future);
  }

  @override
  FutureMonad<S> map<S>(Function1<T, S> f) =>
      new FutureMonad._wrapped(_future.then((w) => w.map(f)));

  @override
  FutureMonad<S> then<S>(FutureOr<S> onValue(T value), {Function onError}) =>
      new FutureMonad(
          _future.then((w) => w.value).then(onValue, onError: onError));

  @override
  FutureMonad<T> timeout(Duration timeLimit, {FutureOr<T> onTimeout()}) =>
      new FutureMonad(_future
          .then((w) => w.value)
          .timeout(timeLimit, onTimeout: onTimeout));

  @override
  FutureMonad<T> whenComplete(action()) =>
      new FutureMonad(_future.then((w) => w.value).whenComplete(action));
}

// A wrapper to avoid auto joining in Dart Futures
class _Wrapper<T> implements Functor<T> {
  final T _value;

  _Wrapper(T value) : _value = value;

  T get value => _value;

  @override
  _Wrapper<S> map<S>(Function1<T, S> f) => new _Wrapper(f(value));
}
