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
  int get hashCode => error.hashCode ^ stackTrace.hashCode;

  @override
  Try<T> operator +(Try<T> other) => other;

  @override
  String toString() => 'Failure{error: $error, stackTrace: $stackTrace}';

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
  Try<S> flatMap<S>(Function1<T, Monad<S>> f) =>
      new Failure._(error, stackTrace);

  @override
  Try<S> map<S>(Function1<T, S> f) => new Failure<S>._(error, stackTrace);
}

/// A computation successfully completed.
class Success<T> extends Try<T> {
  /// The returned value.
  final T value;

  Success._(this.value) : super._();

  @override
  int get hashCode => value.hashCode;

  @override
  Try<T> operator +(Try<T> other) => this;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Success && value == other.value;

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
  String toString() => value?.toString() ?? '';
}

/// A computation that might throw an error while executed.
abstract class Try<T> extends Monad<T> implements Monoid<T> {
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

  @override
  Try<T> operator +(Try<T> other);

  @override
  Try<S> app<S>(Try<Function1<T, S>> app);

  @override
  Try<S> flatMap<S>(Function1<T, Try<S>> f);

  @override
  Try<S> map<S>(Function1<T, S> f);
}
