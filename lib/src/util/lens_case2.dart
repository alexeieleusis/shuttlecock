import 'dart:async';

import 'package:shuttlecock/shuttlecock.dart';

typedef void Evolver<A>(EndoFunction<A> evolution);

class LensCaseFountain<TWhole> {
  Stream<LensCase<TWhole>> _stream;

  LensCaseFountain(TWhole initialState) {
    final evolutions = new StreamController.broadcast();

    void evolver<TWhole>(EndoFunction<TWhole> evolution) {
      evolutions.add(evolution);
    }

    _stream = new StreamMonad<EndoFunction<TWhole>>.of(identity)
        .asBroadcastStream()
        .merge(evolutions.stream)
        .scan(initialState, (state, action) => action(state))
        .map((state) => new LensCase<TWhole>(state, evolver))
        .replay(buffer: 1)
        .asBroadcastStream();
  }

  Stream<LensCase<TWhole>> get stream => _stream;
}

class LensCase<TWhole> {
  // (a -> a) -> ()
  Evolver<TWhole> _evolver;

  // a
  TWhole _value;

  /// () -> a
  TWhole get value => _value;

  LensCase(TWhole value, Evolver<TWhole> evolver) {
    _evolver = evolver;
    _value = value;
  }

  /// a -> ()
  void update(TWhole newValue) => evolve((old) => newValue);

  /// (a -> a) -> ()
  void evolve(EndoFunction<TWhole> evolution) => _evolver(evolution);

  /// (a -> b) -> (b -> a -> a) -> LensCase b
  LensCase<TPiece> getSight<TPiece>(
      TPiece getter(TWhole whole), TWhole setter(TPiece piece, TWhole whole)) {
    // evolutions :: Stream (a -> a)
    // sink :: Stream (b -> b)
    void sinker(TPiece evolvePiece(TPiece piece1)) {
      TWhole newEvol(TWhole whole) => setter(evolvePiece(getter(whole)), whole);
      _evolver(newEvol);
    }

    return new LensCase(getter(_value), sinker);
  }

  /// getSightSequence???
  /// (a -> [b]) -> ([b] -> a -> a) -> [LensCase b]
  Iterable<LensCase<TPiece>> getSightSequence<TPiece>(
      Iterable<TPiece> getter(TWhole whole),
      TWhole setter(Iterable<TPiece> pieces, TWhole whole)) {
    return null;
  }
}
