import 'package:shuttlecock/shuttlecock.dart';

/// The Monad class defines the basic operations over a monad, a concept from a
/// branch of mathematics known as category theory. From the perspective of a
/// programmer, however, it is best to think of a monad as an abstract
/// datatype of actions, providing a context for a computation allowing to focus
/// on the domain and not on implementation nuances.
abstract class Monad<A> extends Applicative<A> {
  /// Sequentially compose two actions, passing any value produced by this
  /// as an argument to the second.
  Monad<B> flatMap<B>(covariant Function1<A, Monad<B>> f);
}
