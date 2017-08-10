import 'package:shuttlecock/src/category_theory/functions.dart';
import 'package:shuttlecock/src/category_theory/functor.dart';

/// Provides context to possibly wrap a value.
abstract class ValueWrapper<T, M extends Functor<T>> {
  /// Returns Try's value if there is any or null if the instance is None.
  /// As with other language implementations, this method is provided to make
  /// easier the integration with imperative code but it is important to note
  /// that using null values should be avoided precisely using this Monad.
  T get orNull => getOrElse(null);

  /// Returns the wrapped value if any or defaults to the provided value.
  T getOrElse(T orElse);

  /// Returns this if a value is wrapped or defaults to the provided computation.
  M orElse(Function0<M> f);
}
