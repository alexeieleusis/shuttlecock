import 'package:shuttlecock/shuttlecock.dart';

/// The Identity monad is a monad that does not embody any computational
/// strategy. It simply applies the bound function to its input without any
/// modification. Computationally, there is no reason to use the Identity monad
/// instead of the much simpler act of simply applying functions to their
/// arguments. The purpose of the Identity monad is its fundamental role in the
/// theory of monad transformers. Any monad transformer applied to the Identity
/// monad yields a non-transformer version of that monad.
class IdentityMonad<T> implements Monad<T> {
  /// The value represented by this instance.
  final T value;

  /// Wraps a value.
  IdentityMonad(this.value);

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is IdentityMonad && value == other.value;

  @override
  IdentityMonad<S> app<S>(IdentityMonad<Function1<T, S>> app) =>
      new IdentityMonad(app.value(value));

  @override
  IdentityMonad<S> flatMap<S>(Function1<T, IdentityMonad<S>> f) => f(value);

  @override
  IdentityMonad<S> map<S>(Function1<T, S> f) => new IdentityMonad(f(value));
}
