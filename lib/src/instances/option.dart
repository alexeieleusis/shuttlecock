import 'package:shuttlecock/shuttlecock.dart';
import 'package:shuttlecock/src/util/empty_iterable_mixin.dart';
import 'package:shuttlecock/src/util/single_value_iterable_mixin.dart';
import 'package:shuttlecock/src/util/value_wrapper.dart';

/// Represents the absence of the value. This is the Zero of the monoid.
class None<T> extends Option<T> with EmptyIterableMixin<T, Option<T>> {
  /// All nones are equal :P
  None() : super._();

  @override
  int get hashCode => 0;

  @override
  bool operator ==(Object other) => identical(this, other) || other is None;

  @override
  Option<S> app<S>(Option<Function1<T, S>> app) => new None();

  @override
  @Deprecated('Use flatMap instead')
  Option<S> expand<S>(Iterable<S> f(T element)) => new None();

  @override
  Option<S> flatMap<S>(Function1<T, Option<S>> f) => new None();

  @override
  Option<S> map<S>(Function1<T, S> f) => new None<S>();

  @override
  String toString() => 'None';
}

/// Represents an optional value. It satisfies the type equation FX = 1 + X,
/// where the functor F takes a set to a point plus that set. This is known as
/// Maybe in Haskell.
abstract class Option<T> extends Monad<T>
    with ValueWrapper<T, Option<T>>
    implements Monoid<T>, IterableMonad<T> {
  /// Creates a new option provided its value, of the value is null, it will
  /// return None.
  factory Option(T value) {
    if (value == null) {
      return new None();
    }

    return new Some(value);
  }

  Option._();

  /// Returns true if the instance is of the form Some v, false otherwise.
  bool get isDefined => !isEmpty;

  @override
  bool get isNotEmpty => !isEmpty;

  @override
  int get length => isEmpty ? 0 : 1;

  /// Operation of the monoid.
  @override
  // ignore: override_on_non_overriding_method
  Option<T> operator +(Option<T> other) => isEmpty ? other : this;

  /// Applies the functor...
  @override
  Option<S> app<S>(Option<Function1<T, S>> app);

  /// Sequentially compose two actions, passing any value produced by this
  /// as an argument to the second.
  @override
  Option<S> flatMap<S>(Function1<T, Option<S>> f);

  @override
  Option<S> map<S>(Function1<T, S> f);

  /// A convenience static method to create Nones.
  static Option<T> empty<T>() => new None<T>();

  /// TODO: Should we promote this somehow to Functor definition?
  /// A convenience static method to create new Options.
  static Option<T> of<T>(T value) => new Some(value);
}

/// Container that is guaranteed to contain a value (non null).
class Some<T> extends Option<T> with SingleValueIterableMixin<T, Option<T>> {
  /// The value this instance represents.
  @override
  final T value;

  /// Creates a new instance of Some with a given value
  Some(this.value) : super._();

  @override
  Option<S> app<S>(Option<Function1<T, S>> app) {
    if (app is None) {
      return new None();
    }

    final Some<Function1<T, S>> some = app;
    return map(some.value);
  }

  @override
  Option<S> flatMap<S>(Function1<T, Option<S>> f) => f(value);

  @override
  Option<S> map<S>(Function1<T, S> f) => new Some<S>(f(value));

  @override
  Option<T> toEmpty() => new None();

  @override
  String toString() => 'Some $value';
}
