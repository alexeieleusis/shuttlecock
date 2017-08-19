import 'package:shuttlecock/shuttlecock.dart';

/// A writer monad parametrized by the type [W] of output to accumulate.
///
/// The return function produces the output [Monoid].zero, while [flatMap]
/// combines the outputs of the sub computations using [Monoid.+].
class Writer<W extends Monoid, A> extends Monad<A> {
  /// The wrapped value.
  final A value;

  /// The embellishment for the value.
  final W embellishment;

  /// Wraps the values.
  Writer(this.value, this.embellishment);

  @override
  int get hashCode => value.hashCode ^ embellishment.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is Writer &&
        value == other.value &&
        embellishment == other.embellishment;
  }

  @override
  Writer<W, B> app<B>(Writer<W, Function1<A, B>> app) =>
      new Writer(app.value(value), embellishment);

  /// Composes the provided functions taking care of the nuisance.
  Function1<A, Writer<W, C>> compose<B, C>(
          Writer<W, B> f(A a), Writer<W, C> g(B b)) =>
      (a) {
        final fa = f(a);
        final gfa = g(fa.value);
        return new Writer(gfa.value, fa.embellishment + gfa.embellishment);
      };

  @override
  Writer<W, B> flatMap<B>(Function1<A, Writer<W, B>> f) {
    final writer = f(value);
    return new Writer(writer.value, embellishment + writer.embellishment);
  }

  @override
  Writer<W, B> map<B>(Function1<A, B> f) => new Writer(f(value), embellishment);

  @override
  String toString() => '($value, $embellishment)';
}
