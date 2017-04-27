import 'package:shuttlecock/shuttlecock.dart';
import 'package:tuple/tuple.dart';

RunState<S, A> _buildRunState<S, A>(A a) => (s) => new Tuple2<A, S>(a, s);

/// A function that performs computations on state.
typedef Tuple2<A, S> RunState<S, A>(S s);

/// A State s a is a stateful computation that manipulates a state of type s and
/// has a result of type a. An instance of the State monad is a function from a
/// state to a state and content pair, i.e. a [RunState]
/// (from https://www.youtube.com/watch?v=XxzzJiXHOJs&t=1535s).
class State<TState, TContent> extends Monad<TContent> implements Function {
  /// Performs the computations needed to get the next state.
  final RunState<TState, TContent> _runState;

  /// Wraps the provided computation.
  State(RunState<TState, TContent> runState) : _runState = runState;

  /// The return function for the monad.
  State.returnState(TContent value) : _runState = _buildRunState(value);

  @override
  State<TState, B> app<B>(State<TState, Function1<TContent, B>> app) {
    Tuple2<B, TState> newRunState(TState s) {
      final appPair = app(s);
      return new Tuple2<B, TState>(
          appPair.item1(_runState(s).item1), appPair.item2);
    }

    return new State<TState, B>(newRunState);
  }

  /// Performs the computation wrapped by this state.
  Tuple2<TContent, TState> call(TState state) => _runState(state);

  @override
  State<TState, B> flatMap<B>(Function1<TContent, State<TState, B>> f) {
    Tuple2<B, TState> newRunState(TState s) {
      final pair = _runState(s);
      return f(pair.item1)(pair.item2);
    }

    return new State<TState, B>(newRunState);
  }

  @override
  State<TState, B> map<B>(Function1<TContent, B> f) {
    Tuple2<B, TState> newRunState(TState s) {
      final pair = _runState(s);
      return new Tuple2<B, TState>(f(pair.item1), pair.item2);
    }

    return new State<TState, B>(newRunState);
  }

  /// Retrieves the state by copying it as the value
  static State<S, S> get<S>() => new State((s) => new Tuple2(s, s));

  /// Sets the state of the monad and does not yield a value.
  static State<TState, Null> put<TState, _>(State<TState, _> state) =>
      new State.returnState(null);
}
