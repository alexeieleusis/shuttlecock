import 'package:shuttlecock/src/category_theory/functions.dart';
import 'package:shuttlecock/src/instances/iterable_monad.dart';
import 'package:shuttlecock/src/util/value_wrapper.dart';

/// Provides implementation for the cases where IterableMonads are empty.
abstract class EmptyIterableMixin<T, M extends IterableMonad<T>>
    implements Iterable<T>, ValueWrapper<T, M> {
  @override
  T get first {
    throw new StateError("No element");
  }

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
  bool any(bool f(T element)) => false;

  @override
  bool contains(Object element) => false;

  @override
  T elementAt(int index) {
    throw new RangeError.index(index, this, "index", null, 0);
  }

  @override
  bool every(bool f(T element)) => true;

  @override
  T firstWhere(bool test(T element), {T orElse()}) {
    if (orElse == null) {
      throw new StateError('Empty collection.');
    }

    return orElse();
  }

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
  M orElse(Function0<M> f) => f();

  @override
  T reduce(T combine(T value, T element)) {
    throw new StateError("Too few elements");
  }

  @override
  T singleWhere(bool test(T element)) {
    throw new StateError("No element");
  }

  @override
  M skip(int count) => this as M;

  @override
  M skipWhile(bool test(T value)) => this as M;

  @override
  M take(int count) {
    if (count == 0) {
      return this as M;
    }

    throw new StateError("Too few elements");
  }

  @override
  M takeWhile(bool test(T value)) => this as M;

  @override
  List<T> toList({bool growable: true}) => [];

  @override
  Set<T> toSet() => new Set.identity();

  @override
  M where(bool test(T element)) => this as M;
}
