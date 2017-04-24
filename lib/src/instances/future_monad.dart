import 'dart:async';

import 'package:shuttlecock/shuttlecock.dart';

/// Wraps a Future in the monad interface.
class FutureMonad<T> extends Monad<T> implements Future<T> {
  final Future<T> _future;

  /// Wraps the provided future.
  FutureMonad(Future<T> future) : _future = future;

  @override
  FutureMonad<S> app<S>(FutureMonad<Function1<T, S>> app) =>
      app.flatMap((f) => then((t) => new FutureMonad(new Future.value(f(t)))));

  @override
  StreamMonad<T> asStream() => new StreamMonad(_future.asStream());

  @override
  FutureMonad<T> catchError(Function onError, {bool test(Object error)}) =>
      new FutureMonad(_future.catchError(onError, test: test));

  @override
  FutureMonad<S> flatMap<S>(Function1<T, FutureMonad<S>> f) =>
      then((t) => new FutureMonad(new Future.value(f(t))));

  @override
  FutureMonad<S> map<S>(Function1<T, S> f) => new FutureMonad(then(f));

  @override
  FutureMonad<S> then<S>(FutureOr onValue(T value), {Function onError}) =>
      new FutureMonad(_future.then(onValue, onError: onError));

  @override
  FutureMonad<T> timeout(Duration timeLimit, {FutureOr<T> onTimeout()}) =>
      new FutureMonad(_future.timeout(timeLimit, onTimeout: onTimeout));

  @override
  FutureMonad<T> whenComplete(action()) =>
      new FutureMonad(_future.whenComplete(action));
}
