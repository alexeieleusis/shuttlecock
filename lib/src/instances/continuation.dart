import 'package:shuttlecock/shuttlecock.dart';

/// (A -> R) -> R
typedef R ContinuationFunction<R, A>(Function1<A, R> f);

/// Continuations represent the future of a computation, as a function from an
/// intermediate result to the final result. In continuation-passing style,
/// computations are built up from sequences of nested continuations, terminated
/// by a final continuation (often id) which produces the final result. Since
/// continuations are functions which represent the future of a computation,
/// manipulation of the continuation functions can achieve complex manipulations
/// of the future of the computation, such as interrupting a computation in the
/// middle, aborting a portion of a computation, restarting a computation and
/// interleaving execution of computations. The Continuation monad adapts CPS to
/// the structure of a monad.
class Continuation<R, A> extends Monad<A> implements Function {
  final ContinuationFunction<R, A> _runCont;

  /// Wraps the provided computation.
  Continuation(ContinuationFunction<R, A> runCont) : _runCont = runCont;

  // (((A -> B) -> R) -> R) -> ((B -> R) -> R)
  @override
  Continuation<R, B> app<B>(Continuation<R, Function1<A, B>> app) =>
      new Continuation<R, B>(
          (k) => _runCont((a) => app((f) => compose(f, k)(a))));
  // k :: B -> R
  // runCont :: (A -> R) -> R
  // app :: ((A -> B) -> R) -> R
  // f :: (A -> B)
  // compose(f, k) :: A -> R
  // compose(f, k)(a) :: R
  // app((f) => compose(f, k)(a))
  // (a) => app((f) => compose(f, k)(a)) :: A -> R

  /// Continues the computation with the provided function.
  R call(Function1<A, R> f) => _runCont(f);

  @override
  Continuation<R, B> flatMap<B>(Function1<A, Continuation<R, B>> f) =>
      new Continuation<R, B>((k) => _runCont((a) => f(a)(k)));
  // k :: B -> R
  // f :: A -> ((B -> R) -> R)
  // f(a) :: (B -> R) -> R
  // f(a)(k) :: R
  // (a) => f(a)(k) :: A -> R
  // _runCont :: (A -> R) -> R
  // (k) => _runCont((a) => f(a)(k)) :: (B -> R) -> R

  @override
  Continuation<R, B> map<B>(Function1<A, B> f) =>
      new Continuation<R, B>((k) => _runCont(compose(f, k)));
  // k :: B -> R
  // f :: A -> B
  // compose(f, k) :: A -> R
  // _runCont :: (A -> R) -> R
}
