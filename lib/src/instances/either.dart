import 'package:shuttlecock/shuttlecock.dart';

/// Union type constructor for type parameters [S] and [T].
// TODO: Either implements the Error monad in Haskell, that means that whenever
// an instance of Left is created, a stacktrace is saved. It also is a monoid.
abstract class Either<S, T> extends Monad<T> {
  /// The wrapped value. An instance of [S] for [Left] of [T] for [Right].
  dynamic /*S | T*/ get value;

  Either<T, S> swap();
}

/// Left set, usually denotes the absence of a value, e.g. en error message.
class Left<S, T> extends Either<S, T> {
  /// What we have instead of the value we expected.
  @override
  final S value;

  /// Created a wrapper of the left set.
  Left(this.value);

  @override
  int get hashCode => value?.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Left<S, T> && value == other.value;

  @override
  Either<S, U> app<U>(Either<S, Function1<T, U>> app) => new Left<S, U>(value);

  @override
  Either<S, U> flatMap<U>(Function1<T, Either<S, U>> f) =>
      new Left<S, U>(value);

  @override
  Left<S, U> map<U>(Function1<T, U> f) => new Left<S, U>(value);

  @override
  Either<T, S> swap() => new Right(value);

  @override
  String toString() => 'Left{value: $value}';
}

/// Represents the right value in an either.
class Right<S, T> extends Either<S, T> {
  /// The value represented by this either.
  @override
  final T value;

  /// Constructor for the value container.
  Right(this.value);

  @override
  int get hashCode => value?.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Right<S, T> && value == other.value;

  @override
  Either<S, U> app<U>(Either<S, Function1<T, U>> app) {
    if (app is Left<S, Function1<T, U>>) {
      return new Left<S, U>(app.value);
    }

    final Right<S, Function1<T, U>> right = app;
    return new Right<S, U>(right.value(value));
  }

  @override
  Either<S, U> flatMap<U>(Function1<T, Either<S, U>> f) => f(value);

  @override
  Either<S, U> map<U>(Function1<T, U> f) => new Right<S, U>(f(value));

  @override
  Either<T, S> swap() => new Left(value);

  @override
  String toString() => 'Right{value: $value}';
}
