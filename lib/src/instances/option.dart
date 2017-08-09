import 'package:shuttlecock/shuttlecock.dart';

/// Represents the absence of the value. This is the Zero of the monoid.
class None<T> extends Option<T> {
  /// All nones are equal :P
  None() : super._();

  @override
  T get first {
    throw new StateError("No element");
  }

  @override
  int get hashCode => 0;

  @override
  bool get isEmpty => true;

  @override
  Iterator<T> get iterator => [].iterator;

  @override
  T get last {
    throw new StateError("No element");
  }

  @override
  T get single {
    throw new StateError("No element");
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is None;

  @override
  bool any(bool f(T element)) => false;

  @override
  Option<S> app<S>(Option<Function1<T, S>> app) => new None();

  @override
  bool contains(Object element) => false;

  @override
  T elementAt(int index) {
    throw new RangeError.index(index, this, "index", null, 0);
  }

  @override
  bool every(bool f(T element)) => true;

  @override
  @Deprecated('Use flatMap instead')
  Option<S> expand<S>(Iterable<S> f(T element)) => new None();

  @override
  T firstWhere(bool test(T element), {T orElse()}) {
    if (orElse == null) {
      throw new StateError('Empty collection.');
    }

    return orElse();
  }

  @override
  Option<S> flatMap<S>(Function1<T, Option<S>> f) => new None();

  @override
  S fold<S>(S initialValue, S combine(S previousValue, T element)) =>
      initialValue;

  @override
  void forEach(void f(T element)) {}

  @override
  T getOrElse(T orElse) => orElse;

  @override
  String join([String separator = ""]) => '';

  @override
  T lastWhere(bool test(T element), {T orElse()}) {
    if (orElse == null) {
      throw new StateError('Empty collection.');
    }

    return orElse();
  }

  @override
  Option<S> map<S>(Function1<T, S> f) => new None<S>();

  @override
  Option<T> orElse(Function0<Option<T>> f) => f();

  @override
  T reduce(T combine(T value, T element)) {
    throw new StateError("Too few elements");
  }

  // TODO: implement single
  @override
  T singleWhere(bool test(T element)) {
    throw new StateError("No element");
  }

  @override
  Option<T> skip(int count) => this;

  @override
  Option<T> skipWhile(bool test(T value)) => this;

  @override
  Option<T> take(int count) {
    if (count == 0) {
      return this;
    }

    throw new StateError("Too few elements");
  }

  @override
  Option<T> takeWhile(bool test(T value)) => this;

  @override
  List<T> toList({bool growable: true}) => [];

  @override
  Set<T> toSet() => new Set.identity();

  @override
  String toString() => 'None';

  @override
  Option<T> where(bool test(T element)) => this;
}

/// Represents an optional value. It satisfies the type equation FX = 1 + X,
/// where the functor F takes a set to a point plus that set. This is known as
/// Maybe in Haskell.
abstract class Option<T> extends Monad<T>
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

  /// Returns Option's value if there is any or null if the instance is None.
  /// As with other language implementations, this method is provided to make
  /// easier the integration with imperative code but it is important to note
  /// that using null values should be avoided precisely using this Monad.
  T get orNull => getOrElse(null);

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

  /// Return the wrapped value or a given default if the instance is None.
  T getOrElse(T orElse);

  @override
  Option<S> map<S>(Function1<T, S> f);

  /// Returns the same instance or the result of the evaluation of a given
  /// function if the instance is None.
  Option<T> orElse(Function0<Option<T>> f);

  /// A convenience static method to create Nones.
  static Option<T> empty<T>() => new None<T>();

  /// TODO: Should we promote this somehow to Functor definition?
  /// A convenience static method to create new Options.
  static Option<T> of<T>(T value) => new Some(value);
}

/// Container that is guaranteed to contain a value (non null).
class Some<T> extends Option<T> {
  /// The value this instance represents.
  final T value;

  /// Creates a new instance of Some with a given value
  Some(this.value) : super._();

  @override
  T get first => value;

  @override
  int get hashCode => value.hashCode;

  @override
  bool get isEmpty => false;

  @override
  Iterator<T> get iterator => [value].iterator;

  @override
  T get last => value;

  @override
  T get single => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Some && value == other.value;

  @override
  bool any(bool f(T element)) => f(value);

  @override
  Option<S> app<S>(Option<Function1<T, S>> app) {
    if (app is None) {
      return new None();
    }

    final Some<Function1<T, S>> some = app;
    return map(some.value);
  }

  @override
  bool contains(Object element) => element == value;

  @override
  T elementAt(int index) {
    if (index != 0) {
      throw new RangeError.index(index, this, "index", null, 1);
    }

    return value;
  }

  @override
  bool every(bool f(T element)) => f(value);

  @override
  IterableMonad<S> expand<S>(Iterable<S> f(T element)) =>
      new IterableMonad<S>.fromIterable(f(value));

  @override
  T firstWhere(bool test(T element), {T orElse()}) {
    if (test(value)) {
      return value;
    } else if (orElse != null) {
      return orElse();
    }

    throw new StateError("No element");
  }

  @override
  Option<S> flatMap<S>(Function1<T, Option<S>> f) => f(value);

  @override
  S fold<S>(S initialValue, S combine(S previousValue, T element)) =>
      combine(initialValue, value);

  @override
  void forEach(void f(T element)) {
    f(value);
  }

  @override
  T getOrElse(T orElse) => value;

  @override
  String join([String separator = ""]) => value.toString();

  @override
  T lastWhere(bool test(T element), {T orElse()}) {
    if (test(value)) {
      return value;
    } else if (orElse != null) {
      return orElse();
    }

    throw new StateError("No element");
  }

  @override
  Option<S> map<S>(Function1<T, S> f) => new Some<S>(f(value));

  @override
  Option<T> orElse(Function0<Option<T>> f) => this;

  @override
  T reduce(T combine(T value, T element)) => value;

  @override
  T singleWhere(bool test(T element)) {
    if (test(value)) {
      return value;
    }

    throw new StateError("No element");
  }

  @override
  Option<T> skip(int count) => count == 0 ? this : new None();

  @override
  Option<T> skipWhile(bool test(T value)) => test(value) ? new None() : this;

  @override
  Option<T> take(int count) => count >= 1 ? this : new None();

  @override
  Option<T> takeWhile(bool test(T value)) => test(value) ? this : new None();

  @override
  List<T> toList({bool growable: true}) => [value].toList(growable: growable);

  @override
  Set<T> toSet() => new Set.from([value]);

  @override
  String toString() => 'Some $value';

  @override
  Option<T> where(bool test(T element)) => test(value) ? this : new None();
}
