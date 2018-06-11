import 'dart:async';

import 'package:shuttlecock/shuttlecock.dart';

// (a -> a) -> ()
typedef Evolver<A> = void Function(EndoFunction<A> evolution);

class LensCase<TWhole> {
  // (a -> a) -> ()
  Evolver<TWhole> _evolver;

  // Stream a
  StreamMonad<TWhole> _stream;

  /// Builds a new instance given an initial state.
  LensCase.of(TWhole initialState) {
    // TODO: Implement disposable and close the sink there.
    final evolutions = new StreamController<EndoFunction<TWhole>>.broadcast();
    void evolver(EndoFunction<TWhole> evolution) {
      evolutions.add(evolution);
    }

    _evolver = evolver;
    _stream = new StreamMonad<EndoFunction<TWhole>>.of(identity)
        .asBroadcastStream()
        .merge(new StreamMonad(evolutions.stream))
        .scan(initialState, (state, action) => action(state))
        .distinct()
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
  void update(TWhole a) => _evolver((oldA) => a);

  /// (a -> b) -> (b -> a -> a) -> LensCase b
  LensCase<TPiece> getSight<TPiece>(
      TPiece getter(TWhole whole), TWhole setter(TPiece piece, TWhole whole)) {
    // evolutions :: Stream (a -> a)
    // sink :: Stream (b -> b)
    void sinker(TPiece evolve(TPiece piece1)) {
      TWhole newEvol(TWhole whole) => setter(evolve(getter(whole)), whole);
      _evolver(newEvol);
    }

    return new LensCase.on(sinker, _stream.map(getter).distinct());
  }

  StreamMonad<IterableMonad<LensCase<TPiece>>> getSightSequence<TPiece>(
      Iterable<TPiece> getter(TWhole whole),
      TWhole setter(Iterable<TPiece> pieces, TWhole whole)) {
    // TODO: Should there be an overload accepting events from new lenses as
    // long as they are in the specified index?
    var emitted = false;
    final pieceLens = getSight(getter, setter);
    final future = _stream.first.then((whole) {
      final pieces = getter(whole).toList().asMap();
      final lenses = pieces
          .map((index, piece) => new MapEntry(index, new LensCase.of(piece)));
      final subscriptions = lenses.map((index, lens) => new MapEntry(
          index,
          lens.stream.skip(1).listen((piece) {
            final newPieces = pieces.values.toList();
            newPieces[index] = piece;
            if (!emitted) {
              pieceLens.update(newPieces);
            }
            emitted = true;
          })));
      _stream.first.then((state) {
        subscriptions.values.forEach((subscription) => subscription.cancel());
      });
      return new IterableMonad.fromIterable(lenses.values);
    });
    return new FutureMonad(future).asStream();
  }

  /// view/get :: Stream a
  StreamMonad<TWhole> get stream => _stream;
}
