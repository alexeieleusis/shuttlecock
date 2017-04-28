import 'package:shuttlecock/src/category_theory/functions.dart';
import 'package:shuttlecock/src/category_theory/monad.dart';

/// Computation type:
/// Computations which read values from a shared environment.
///
/// Binding strategy:
/// Monad values are functions from the environment to a value. The bound
/// function is applied to the bound value, and both have access to the shared
/// environment.
///
/// Useful for:
/// Maintaining variable bindings, or other shared environment.
class Reader<A, B> extends Monad<B> implements Function {
  /// The wrapped computation.
  final Function1<A, B> run;

  /// Wraps the computation provided.
  Reader(this.run);

  /// A reader whose computation always return [b].
  Reader.returnReader(B b) : this((a) => b);

  @override
  Reader<A, C> app<C>(Reader<A, Function1<B, C>> app) =>
      new Reader((a) => app(a)(this(a)));

  /// Performs the wrapped computation.
  B call(A a) => run(a);

  @override
  Reader<A, C> flatMap<C>(Function1<B, Reader<A, C>> f) =>
      new Reader((a) => map(f)(a)(a));

  @override
  Reader<A, C> map<C>(Function1<B, C> f) => new Reader(compose(f, run));
}
