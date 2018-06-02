import 'dart:async';

import 'package:shuttlecock/shuttlecock.dart';

typedef void Evolver<A>(EndoFunction<A> evolution);

class LensCase<TWhole> {
  // (a -> a) -> ()
  Evolver<TWhole> _evolver;

  // Stream a
  Stream<TWhole> _stream;

  /// Builds a new instance given an initial state.
  LensCase.of(TWhole initialState) {
    final evolutions = new StreamController.broadcast();
    void evolver<TWhole>(EndoFunction<TWhole> evolution) {
      evolutions.add(evolution);
    }

    _evolver = evolver;
    _stream = new StreamMonad<EndoFunction<TWhole>>.of(identity)
        .asBroadcastStream()
        .merge(evolutions.stream)
        .scan(initialState, (state, action) => action(state))
        .replay(buffer: 1)
        .asBroadcastStream();
  }

  /// Builds a new instance given a sink of evolutions and a stream of values.
  // Do we want to make this constructor private to ensure we always know the
  // stream repeats its last value and is broadcast?
  LensCase.on(Evolver<TWhole> evolver, Stream<TWhole> stream)
      : this._evolver = evolver,
        this._stream = stream;

  /// (a -> a) -> ()
  void evolve(EndoFunction<TWhole> evolution) {
    _evolver(evolution);
  }

  /// a -> ()
  void set(TWhole a) {
    _evolver((oldA) => a);
  }

  /// (a -> b) -> (b -> a -> a) -> LensCase b
  LensCase<TPiece> getSight<TPiece>(
      TPiece getter(TWhole whole), TWhole setter(TPiece piece, TWhole whole)) {
    // evolutions :: Stream (a -> a)
    // sink :: Stream (b -> b)
    void sinker(TPiece evolve(TPiece piece1)) {
      TWhole newEvol(TWhole whole) => setter(getter(whole), whole);
      _evolver(newEvol);
    }

    return new LensCase.on(sinker, _stream.map(getter));
  }

  ///   (a -> b) -> (b -> a -> a)
  /// ~ (a -> b) -> (a -> b -> a)
  /// ~ a -> (b, b -> a)
  /// a -> (b, b -> a) -> LensCase b
  LensCase<TPiece> getSight2<TPiece>(
      TPiece getter(TWhole whole), TWhole setter(TPiece piece, TWhole whole)) {
    final sink = null;
    return new LensCase.on(sink, _stream.map(getter));
  }

  /// view/get :: Stream a
  Stream<TWhole> get stream => _stream;
}
