import 'package:shuttlecock/shuttlecock.dart';

/// Iterable the adds the missing parts to be a monad. The zero of the monoid is
/// any empty instance.
class IterableMonad<T> extends Monad<T> implements Iterable<T>, Monoid<T> {
  final Iterable<T> _data;

  /// Creates an empty iterable.
  IterableMonad() : _data = const Iterable.empty();

  /// Wraps an iterable in a monad.
  IterableMonad.fromIterable(Iterable<T> data) : _data = data {
    if (_data == null) {
      throw new ArgumentError.notNull();
    }
  }

  /// Creates an iterable by iteratively applying [f] to the provided [seed]
  /// until [None] is returned.
  factory IterableMonad.grow(T seed, Function1<T, Option<T>> f) {
    final data = [seed];
    var option = f(seed);
    while (option.isNotEmpty) {
      data.add(option.first);
      option = f(option.single);
    }
    return new IterableMonad.fromIterable(new List.unmodifiable(data));
  }

  @override
  T get first => _data.first;

  @override
  bool get isEmpty => _data.isEmpty;

  @override
  bool get isNotEmpty => _data.isNotEmpty;

  @override
  Iterator<T> get iterator => _data.iterator;

  @override
  T get last => _data.last;

  @override
  int get length => _data.length;

  @override
  T get single => _data.single;

  @override
  IterableMonad<T> operator +(IterableMonad<T> other) =>
      new IterableMonad.fromIterable([this, other].expand((i) => i));

  @override
  bool any(bool f(T element)) => _data.any(f);

  @override
  IterableMonad<S> app<S>(IterableMonad<Function1<T, S>> app) {
    final Iterable<S> newData = app._data.fold<List<S>>(
        [],
        (accS, f) => _data.fold<List<S>>(accS, (accT, t) {
              accS.add(f(t));
              return accS;
            }));

    return new IterableMonad.fromIterable(newData);
  }

  /// TODO: Dart 2.0 requires this method to be implemented. See https://github.com/dart-lang/sdk/issues/31664.
  @override
  // ignore: override_on_non_overriding_method
  Iterable<S> cast<S>() {
    throw new UnimplementedError('cast');
  }

  @override
  bool contains(Object element) => _data.contains(element);

  @override
  T elementAt(int index) => _data.elementAt(index);

  @override
  bool every(bool f(T element)) => _data.every(f);

  /// This method is implemented only to comply with the [Iterable] but it is
  /// recommended to use flatMap instead.
  @override
  @Deprecated('Use flatMap instead')
  Iterable<S> expand<S>(Iterable<S> f(T element)) => _data.expand(f);

  @override
  T firstWhere(bool test(T element), {T orElse()}) =>
      _data.firstWhere(test, orElse: orElse);

  @override
  IterableMonad<S> flatMap<S>(Function1<T, IterableMonad<S>> f) =>
      new IterableMonad.fromIterable(_data.expand(f));

  @override
  S fold<S>(S initialValue, S combine(S previousValue, T element)) =>
      _data.fold(initialValue, combine);

  /// TODO: Dart 2.0 requires this method to be implemented. See https://github.com/dart-lang/sdk/issues/31664.
  @override
  // ignore: override_on_non_overriding_method
  Iterable<T> followedBy(Iterable<T> other) {
    throw new UnimplementedError('followedBy');
  }

  @override
  void forEach(void f(T element)) {
    _data.forEach(f);
  }

  @override
  String join([String separator = '']) => _data.join(separator);

  @override
  T lastWhere(bool test(T element), {T orElse()}) => _data.lastWhere(test);

  /// Returns a new lazy [Iterable] with elements that are created by
  /// calling `f` on each element of this `Iterable` in iteration order.
  ///
  /// This method returns a view of the mapped elements. As long as the
  /// returned [Iterable] is not iterated over, the supplied function [f] will
  /// not be invoked. The transformed elements will not be cached. Iterating
  /// multiple times over the returned [Iterable] will invoke the supplied
  /// function [f] multiple times on the same element.
  ///
  /// Methods on the returned iterable are allowed to omit calling `f`
  /// on any element where the result isn't needed.
  /// For example, [elementAt] may call `f` only once.
  IterableMonad<S> map<S>(S f(T t)) =>
      new IterableMonad.fromIterable(_data.map(f));

  @override
  T reduce(T combine(T value, T element)) => _data.reduce(combine);

  /// TODO: Dart 2.0 requires this method to be implemented. See https://github.com/dart-lang/sdk/issues/31664.
  @override
  // ignore: override_on_non_overriding_method
  Iterable<S> retype<S>() {
    throw new UnimplementedError('retype');
  }

  @override
  T singleWhere(bool test(T element), {T orElse()}) =>
      any(test) || orElse == null ? _data.singleWhere(test) : orElse();

  @override
  IterableMonad<T> skip(int count) =>
      new IterableMonad.fromIterable(_data.skip(count));

  @override
  IterableMonad<T> skipWhile(bool test(T value)) =>
      new IterableMonad.fromIterable(_data.skipWhile(test));

  @override
  IterableMonad<T> take(int count) =>
      new IterableMonad.fromIterable(_data.take(count));

  @override
  IterableMonad<T> takeWhile(bool test(T value)) =>
      new IterableMonad.fromIterable(_data.takeWhile(test));

  // TODO: Implement an ListMonad?
  @override
  List<T> toList({bool growable: true}) => _data.toList(growable: growable);

  // TODO: Implement a SetMonad?
  @override
  Set<T> toSet() => _data.toSet();

  /// Unfolds every element in the iterable with [IterableMonad.grow] and
  /// concatenates the result.
  IterableMonad<T> unfold(Function1<T, Option<T>> f) =>
      flatMap((e) => new IterableMonad.grow(e, f));

  @override
  IterableMonad<T> where(bool test(T element)) =>
      new IterableMonad.fromIterable(_data.where(test));

  /// TODO: Dart 2.0 requires this method to be implemented. See https://github.com/dart-lang/sdk/issues/31664.
  @override
  // ignore: override_on_non_overriding_method
  Iterable<S> whereType<S>() {
    throw new UnimplementedError('whereType');
  }
}
