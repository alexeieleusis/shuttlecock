/// Composes [f] with [g].
Function1<A, C> compose<A, B, C>(Function1<B, C> g, Function1<A, B> f) =>
    (a) => g(f(a));

/// Given a function that takes two parameters and a reference of the first type
/// returns a function that takes only one paramter of the second type.
Function1<B, C> curry<A, B, C>(Function2<A, B, C> f, A a) => (b) => f(a, b);

/// Produces a function that evaluates the provided function in the specified
/// value.
Function1<Function1<A, R>, R> eval<R, A>(A a) => (f) => f(a);

/// Identity function that returns i
A identity<A>(A a) => a;

/// Returns a function mathematically equal to the one provided but it is
/// computed once for each input and its value is cached and returned in
/// subsequent invocations.
Function1<A, B> memoize<A, B>(Function1<A, B> f) {
  final memoized = <A, B>{};
  return (a) => memoized[a] ??= f(a);
}

/// Arity 1 functions that return the same type that they take.
typedef A EndoFunction<A>(A a);

/// Generic definition for functions of arity 1. Strictly speaking all functions
/// should adhere to this typedef, different signatures should be used only as
/// a more convenient way to express them.
typedef B Function1<A, B>(A a);

/// Definition of functions that take two parameters. At this point is
/// introduced to clearly define currying.
typedef C Function2<A, B, C>(A a, B b);
