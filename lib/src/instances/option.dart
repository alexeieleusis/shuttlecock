import 'package:shuttlecock/shuttlecock.dart';

/// Represents the absence of the value. This is the Zero of the monoid.
class None<T> extends Option<T> {
  /// This class should only have one instance provided by this constructor.
  None() : super._();

  @override
  int get hashCode => 0;

  @override
  Option<T> operator +(Option<T> other) => other;

  @override
  bool operator ==(Object other) => identical(this, other) || other is None;

  @override
  Option<S> app<S>(Option<Function1<T, S>> app) => new None();

  @override
  Option<S> flatMap<S>(Function1<T, Monad<S>> f) => new None();

  @override
  Option<S> map<S>(Function1<T, S> f) => new None<S>();

  @override
  String toString() => 'None';
}

/// Represents an optional value. It satisfies the type equation FX = 1 + X,
/// where the functor F takes a set to a point plus that set. This is known as
/// Maybe in Haskell.
abstract class Option<T> extends Monad<T> implements Monoid<T> {
  /// Creates a new option provided its value, of the value is null, it will
  /// return None.
  factory Option(T value) {
    if (value == null) {
      return new None();
    }

    return new Some(value);
  }
  Option._();

  @override
  Option<T> operator +(Option<T> other);

  @override
  Option<S> app<S>(Option<Function1<T, S>> app);

  @override
  Option<S> flatMap<S>(Function1<T, Option<S>> f);

  @override
  Option<S> map<S>(Function1<T, S> f);
}

/// Container that is guaranteed to contain a value (non null).
class Some<T> extends Option<T> {
  /// The value this instance represents.
  final T value;

  /// Creates a new instance of Some with a given value
  Some(this.value) : super._();

  @override
  int get hashCode => value.hashCode;

  @override
  Option<T> operator +(Option<T> other) => this;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Some && value == other.value;

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
  String toString() => 'Some $value';
}
