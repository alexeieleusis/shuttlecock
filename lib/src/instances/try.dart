import 'package:shuttlecock/shuttlecock.dart';
import 'package:shuttlecock/src/util/empty_iterable_mixin.dart';
import 'package:shuttlecock/src/util/single_value_iterable_mixin.dart';
import 'package:shuttlecock/src/util/value_wrapper.dart';

/// Represents a computation that failed throwing an error that should be
/// handled by the programmer.
class Failure<T> extends Try<T> with EmptyIterableMixin<T, Try<T>> {
  /// The exception thrown.
  final Exception error;

  /// Information when the error was thrown.
  final StackTrace stackTrace;

  /// This class should only have one instance provided by this constructor.
  Failure._(this.error, this.stackTrace) : super._();

  @override
  int get hashCode => error.hashCode ^ stackTrace.hashCode;

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
  Try<S> app<S>(Try<Function1<T, S>> app) => new Failure._(error, stackTrace);

  @override
  @Deprecated('Use flatMap instead')
  Try<S> expand<S>(Iterable<S> f(T element)) =>
      new Failure._(error, stackTrace);

  @override
  Try<S> flatMap<S>(Function1<T, Monad<S>> f) =>
      new Failure._(error, stackTrace);

  @override
  Try<S> map<S>(Function1<T, S> f) => new Failure<S>._(error, stackTrace);

  @override
  Try<T> recover(Function1<Exception, T> onFailure) =>
      new Try(() => onFailure(error));

  @override
  Try<T> recoverWith(Function1<Exception, Try<T>> onFailure) =>
      onFailure(error);

  @override
  Either<Exception, T> toEither() => new Left(error);

  @override
  Option<T> toOption() => Option.empty<T>();

  @override
  String toString() => 'Failure{error: $error, stackTrace: $stackTrace}';

  @override
  Try<T> transform(Function1<T, Try<T>> f, Function1<Exception, Try<T>> g) =>
      recoverWith(g);
}

/// A computation successfully completed.
class Success<T> extends Try<T> with SingleValueIterableMixin<T, Try<T>> {
  /// The returned value.
  @override
  final T value;

  Success._(this.value) : super._();

  @override
  Try<T> operator +(Try<T> other) => this;

  @override
  Try<S> app<S>(Try<Function1<T, S>> app) {
    if (app is Failure<Function1<T, S>>) {
      return new Failure._(app.error, app.stackTrace);
    }

    final Success<Function1<T, S>> some = app;
    return map(some.value);
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
  Try<S> map<S>(Function1<T, S> f) => new Try<S>(() => f(value));

  @override
  Try<T> recover(Function onFailure) => this;

  @override
  Try<T> recoverWith(Function1<Exception, Try<T>> onFailure) => this;

  @override
  Either<Exception, T> toEither() => new Right(value);

  @override
  Try<T> toEmpty() {
    try {
      throw new Exception('Could not perform the desired operation.');
    } on Exception catch (e, s) {
      return new Failure._(e, s);
    }
  }

  @override
  Option<T> toOption() => Option.of(value);

  @override
  String toString() => value?.toString() ?? '';

  @override
  Try<T> transform(Function1<T, Try<T>> f, Function1<Exception, Try<T>> g) =>
      flatMap(f);
}

/// A computation that might throw an error while executed.
abstract class Try<T> extends Monad<T>
    with ValueWrapper<T, Try<T>>
    implements Monoid<T>, IterableMonad<T> {
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

  /// Returns true if the instance is a success, false otherwise.
  bool get isDefined => !isEmpty;

  /// Returns false if the instance is a success, false otherwise.
  bool get isFailure => isEmpty;

  @override
  bool get isNotEmpty => !isEmpty;

  /// Returns true if the instance is a success, false otherwise.
  bool get isSuccess => !isEmpty;

  @override
  int get length => isEmpty ? 0 : 1;

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

  @override
  Try<S> map<S>(Function1<T, S> f);

  /// Applies a function to the exception if failure or return the same
  /// instance if success. Similar to map but acting on Exceptions
  Try<T> recover(Function1<Exception, T> onFailure);

  /// Applies a function to the exception if failure or return the same
  /// instance if success. Similar to flatMap but acting on Exceptions
  Try<T> recoverWith(Function1<Exception, Try<T>> onFailure);

  /// Returns a Right with the value if success or Left with an exception in
  /// case of failure
  Either<Exception, T> toEither();

  /// Returns an option with the value if success or None in case of failure
  Option<T> toOption();

  /// Returns the result of f if success or the result of g if failure. Similar
  /// to apply flatMap . recoverWith.
  Try<T> transform(Function1<T, Try<T>> f, Function1<Exception, Try<T>> g);

  /// Convenience method to create a [Failure].
  static Try<T> fail<T>(Exception exception, StackTrace stackTrace) =>
      new Failure._(exception, stackTrace);

  /// TODO: Should we promote this somehow to Functor definition?
  /// A convenience static method to create new Try.
  static Try<T> of<T>(T value) => new Success._(value);
}
