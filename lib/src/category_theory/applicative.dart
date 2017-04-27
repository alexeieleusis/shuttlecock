import 'package:shuttlecock/shuttlecock.dart';

/// A functor with application, providing operations to embed pure expressions
/// (pure), and sequence computations and combine their results (<*>).
///
/// A minimal complete definition must include implementations of these
/// functions satisfying the following laws:
///
/// * identity
/// `pure id <*> v = v`
/// * composition
/// `pure (.) <*> u <*> v <*> w = u <*> (v <*> w)`
/// * homomorphism
/// `pure f <*> pure x = pure (f x)`
/// * interchange
/// `u <*> pure y = pure ($ y) <*> u`
///
/// The other methods have the following default definitions, which may be
/// overridden with equivalent specialized implementations:
///
/// `u *> v = pure (const id) <*> u <*> v`
/// `u <* v = pure const <*> u <*> v`
///
/// As a consequence of these laws, the Functor instance for `f` will satisfy
///
/// `fmap f x = pure f <*> x`
/// If `f` is also a Monad, it should satisfy
///
/// `pure = return`
/// `(<*>) = ap`
/// (which implies that `pure` and `<*>` satisfy the applicative functor laws).
///
/// Minimal complete definition
///
/// `pure, (<*>)`
///
/// Methods
///
/// `pure :: a -> f a`
///
/// Lift a value.
/// `(<*>) :: f (a -> b) -> f a -> f b infixl 4`
///
/// Sequential application.
/// `(*>) :: f a -> f b -> f b infixl 4`
///
/// Sequence actions, discarding the value of the first argument.
/// `(<*) :: f a -> f b -> f a infixl 4`
///
/// Sequence actions, discarding the value of the second argument.
abstract class Applicative<A> extends Functor<A> {
  /// Applies the functor...
  /// Reminder functor is defined fmap :: (a -> b) -> f a -> f b
  /// (<*>) :: f (a -> b) -> f a -> f b
  // TODO: Write less lame documentation.
  Applicative<B> app<B>(covariant Applicative<Function1<A, B>> app);
}
