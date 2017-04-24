/// Toy definition for a monoid. Classes extending or implementing Monoid need
/// to have a Zero, since it is a static property, it cannot be declared here
/// and implementors are responsible for providing and documenting it.

/// Wrapper class to handle int with the monoid interface.
class DoubleMonoid implements Monoid<double> {
  /// The wrapped value.
  final double value;

  /// Wraps the value.
  DoubleMonoid(this.value);

  @override
  int get hashCode => value.hashCode;

  @override
  DoubleMonoid operator +(DoubleMonoid other) =>
      new DoubleMonoid(value + other.value);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is DoubleMonoid && value == other.value;
  }

  @override
  String toString() => value.toString();
}

/// Wrapper class to handle int with the monoid interface.
class IntMonoid implements Monoid<int> {
  /// The wrapped value.
  final int value;

  /// Wraps the value.
  IntMonoid(this.value);

  @override
  int get hashCode => value.hashCode;

  @override
  IntMonoid operator +(IntMonoid other) => new IntMonoid(value + other.value);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is IntMonoid && value == other.value;
  }

  @override
  String toString() => value.toString();
}

/// A class for monoids (types with an associative binary operation that has an
/// identity) with various general-purpose instances.
// ignore: one_member_abstracts
abstract class Monoid<A> {
  /// Operation of the monoid.
  Monoid<A> operator +(covariant Monoid<A> other);
}

/// Wrapper class to handle num with the monoid interface.
class NumMonoid implements Monoid<num> {
  /// The wrapped value.
  final num value;

  /// Wraps the value.
  NumMonoid(this.value);

  @override
  int get hashCode => value.hashCode;

  @override
  NumMonoid operator +(NumMonoid other) => new NumMonoid(value + other.value);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is NumMonoid && value == other.value;
  }

  @override
  String toString() => value.toString();
}

/// Wrapper class to handle Strings with the monoid interface.
class StringMonoid implements Monoid<String> {
  /// The wrapped value.
  final String value;

  /// Wraps the value.
  StringMonoid(this.value);

  @override
  int get hashCode => value.hashCode;

  @override
  StringMonoid operator +(StringMonoid other) =>
      new StringMonoid('$value${other.value}');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is StringMonoid && value == other.value;
  }

  @override
  String toString() => value;
}
