import 'package:meta/meta.dart';
import 'package:shuttlecock/shuttlecock.dart';

/// A Store is a stream holder that represents changes of state.
///
/// Store [changes] stream emits every time observed signals streams emits a
/// function f that generates a new state N from a previous state P.
///
/// This implementation was designed to be used with an
/// immutable data structure S and pure functions as signals.
/// Performing side effects or mutations may cause raise conditions
/// difficult to reason about.
///
/// This implementation is inspired in ELM Architecture and can be used as an
/// alternative for Redux like implementations.
@immutable
class Store<S> {
  /// Stream of state changes.
  ///
  /// [changes] emits every time there is a new event action from the observed
  /// signals, which may potentially emit states with no changes from previous
  /// ones. Users should use distinct or other operators to ignore no change
  /// events.
  final StreamMonad<S> changes;

  /// [initialState] will be the first event from [changes] stream.
  /// [signals] is a collection of streams, each of them emits actions on state
  /// objects.
  /// An action in this context is expected to be a pure function from S to S.
  Store(
      S initialState, IterableMonad<StreamMonad<EndoFunction<S>>> signals)
      : changes = signals
      // Concat all signals into a single stream.
      .fold<StreamMonad<EndoFunction<S>>>(
      // Start signals with the identity to ensure that first event is the
      // initial state
      new StreamMonad<EndoFunction<S>>.of(identity)
          // Stores are intended to have multiple subscribers, there is no
          // need to offer a single subscription stream.
          .asBroadcastStream(),
          (acc, a) => acc.merge(a))
      // Merge with never to ensure that this stream will never close even if
      // all subscribers cancel subscriptions.
      // We should be ready for new subscribers.
      .merge(new StreamMonad.never())
      // Reduce last state with the next action and emit new event.
      .scan<S>(initialState, (state, signal) => signal(state))
      //  Replay last event to new subscribers.
      .replay(buffer: 1).asBroadcastStream();
}