import 'package:shuttlecock/shuttlecock.dart';

/// Represents a computation that failed throwing an error that should be
/// handled by the programmer.
class Failure<T> extends Try<T> {
  /// The exception thrown.
  final Exception error;

  /// Information when the error was thrown.
  final StackTrace stackTrace;

  /// This class should only have one instance provided by this constructor.
  Failure._(this.error, this.stackTrace) : super._();

  @override
  T get first {
    throw new StateError("No element");
  }

  @override
  int get hashCode => error.hashCode ^ stackTrace.hashCode;

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
  Try<T> operator +(Try<T> other) => other;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is Failure &&
        error == other.error &&
        stackTrace == other.stackTrace;
  }

  @override
  bool any(bool f(T element)) => false;

  @override
  Try<S> app<S>(Try<Function1<T, S>> app) => new Failure._(error, stackTrace);

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
  Try<S> expand<S>(Iterable<S> f(T element)) =>
      new Failure._(error, stackTrace);

  @override
  T firstWhere(bool test(T element), {T orElse()}) {
    if (orElse == null) {
      throw new StateError('Empty collection.');
    }

    return orElse();
  }

  @override
  Try<S> flatMap<S>(Function1<T, Monad<S>> f) =>
      new Failure._(error, stackTrace);

  @override
  S fold<S>(S initialValue, S combine(S previousValue, T element)) =>
      initialValue;

  @override
  void forEach(void f(T element)) {}

  @override
  T getOrElse(T orElse) => orElse;

  @override
  String join([String separator = '']) => '';

  @override
  T lastWhere(bool test(T element), {T orElse()}) {
    if (orElse == null) {
      throw new StateError('Empty collection.');
    }

    return orElse();
  }

  @override
  Try<S> map<S>(Function1<T, S> f) => new Failure<S>._(error, stackTrace);

  @override
  Try<T> orElse(Function0<Try<T>> f) => f();

  @override
  T reduce(T combine(T value, T element)) {
    throw new StateError("Too few elements");
  }

  @override
  T singleWhere(bool test(T element)) {
    throw new StateError("No element");
  }

  @override
  Try<T> skip(int count) => this;

  @override
  Try<T> skipWhile(bool test(T value)) => this;

  @override
  Try<T> take(int count) {
    if (count == 0) {
      return this;
    }

    throw new StateError("Too few elements");
  }

  @override
  Try<T> takeWhile(bool test(T value)) => this;

  @override
  List<T> toList({bool growable: true}) => [];

  @override
  Set<T> toSet() => new Set.identity();

  @override
  String toString() => 'Failure{error: $error, stackTrace: $stackTrace}';

  @override
  Try<T> where(bool test(T element)) => this;
}

/// A computation successfully completed.
class Success<T> extends Try<T> {
  /// The returned value.
  final T value;

  Success._(this.value) : super._();

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
  Try<T> operator +(Try<T> other) => this;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Success && value == other.value;

  @override
  bool any(bool f(T element)) => f(value);

  @override
  Try<S> app<S>(Try<Function1<T, S>> app) {
    if (app is Failure<Function1<T, S>>) {
      return new Failure._(app.error, app.stackTrace);
    }

    final Success<Function1<T, S>> some = app;
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
  Try<S> flatMap<S>(Function1<T, Try<S>> f) {
    try {
      return f(value);
    } on Exception catch (e, s) {
      return new Failure._(e, s);
    }
  }

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
  Try<S> map<S>(Function1<T, S> f) => new Try<S>(() => f(value));

  @override
  Try<T> orElse(Function0<Try<T>> f) => this;

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
  Try<T> skip(int count) => count == 0 ? this : new None();

  @override
  Try<T> skipWhile(bool test(T value)) => test(value) ? new None() : this;

  @override
  Try<T> take(int count) => count >= 1 ? this : new None();

  @override
  Try<T> takeWhile(bool test(T value)) => test(value) ? this : new None();

  @override
  List<T> toList({bool growable: true}) => [value].toList(growable: growable);

  @override
  Set<T> toSet() => new Set.from([value]);

  @override
  String toString() => value?.toString() ?? '';

  @override
  Try<T> where(bool test(T element)) => test(value) ? this : new None();
}

/// A computation that might throw an error while executed.
abstract class Try<T> extends Monad<T> implements Monoid<T>, IterableMonad<T> {
  /// Performs the specified computation providing either the produced value or
  /// the contextual information about the failure.
  factory Try(T value()) {
    try {
      return new Success._(value());
    } on Exception catch (e, s) {
      return new Failure._(e, s);
    }
  }

  Try._();

  /// Returns true if the instance is of the form Some v, false otherwise.
  bool get isDefined => !isEmpty;

  @override
  bool get isNotEmpty => !isEmpty;

  @override
  int get length => isEmpty ? 0 : 1;

  /// Returns Try's value if there is any or null if the instance is None.
  /// As with other language implementations, this method is provided to make
  /// easier the integration with imperative code but it is important to note
  /// that using null values should be avoided precisely using this Monad.
  T get orNull => getOrElse(null);

  /// Monoid + operator
  @override
  // ignore: override_on_non_overriding_method
  Try<T> operator +(Try<T> other);

  /// Applicative app method.
  @override
  Try<S> app<S>(Try<Function1<T, S>> app);

  /// Monad flatMap method.
  @override
  Try<S> flatMap<S>(Function1<T, Try<S>> f);

  /// Return the wrapped value or a given default if the instance is None.
  T getOrElse(T orElse);

  @override
  Try<S> map<S>(Function1<T, S> f);

  /// Returns the same instance or the result of the evaluation of a given
  /// function if the instance is None.
  Try<T> orElse(Function0<Try<T>> f);

  /// Convenience method to create a [Failure].
  static Try<T> fail<T>(Exception exception, StackTrace stackTrace) =>
      new Failure._(exception, stackTrace);

  /// TODO: Should we promote this somehow to Functor definition?
  /// A convenience static method to create new Try.
  static Try<T> of<T>(T value) => new Success._(value);
}
