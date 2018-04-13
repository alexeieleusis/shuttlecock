import 'package:meta/meta.dart';
import 'package:shuttlecock/src/category_theory/functions.dart';
import 'package:shuttlecock/src/instances/iterable_monad.dart';
import 'package:shuttlecock/src/instances/option.dart';
import 'package:shuttlecock/src/util/value_wrapper.dart';

/// Provides implementation for the classes using it as mixin.
abstract class SingleValueIterableMixin<T, M extends IterableMonad<T>>
    implements Iterable<T>, ValueWrapper<T, M> {
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

  /// The wrapped value.
  T get value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SingleValueIterableMixin && other is M && value == other.value;

  @override
  bool any(bool f(T element)) => f(value);

  @override
  bool contains(Object element) => element == value;

  @override
  T elementAt(int index) {
    if (index != 0) {
      throw new RangeError.index(index, this, 'index', null, 1);
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

    throw new StateError('No element');
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
  String join([String separator = '']) => value.toString();

  @override
  T lastWhere(bool test(T element), {T orElse()}) {
    if (test(value)) {
      return value;
    } else if (orElse != null) {
      return orElse();
    }

    throw new StateError('No element');
  }

  @override
  M orElse(Function0<M> f) => this as M;

  @override
  T reduce(T combine(T value, T element)) => value;

  @override
  T singleWhere(bool test(T element), {T orElse()}) {
    if (test(value)) {
      return value;
    }

    if (orElse != null) {
      return orElse();
    }

    throw new StateError('No element');
  }

  @override
  M skip(int count) => count == 0 ? this : toEmpty();

  @override
  M skipWhile(bool test(T value)) => test(value) ? toEmpty() : this;

  @override
  M take(int count) => count >= 1 ? this : toEmpty();

  @override
  M takeWhile(bool test(T value)) => test(value) ? this : toEmpty();

  /// Creates an empty instance.
  @protected
  M toEmpty();

  @override
  List<T> toList({bool growable = true}) => [value].toList(growable: growable);

  @override
  Set<T> toSet() => new Set.from([value]);

  /// Unfolds every element in the iterable with [IterableMonad.grow] and
  /// concatenates the result.
  IterableMonad<T> unfold(Function1<T, Option<T>> f) =>
      new IterableMonad.grow(value, f);

  @override
  M where(bool test(T element)) => test(value) ? this : toEmpty();
}
