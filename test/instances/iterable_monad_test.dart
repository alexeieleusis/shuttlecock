import 'package:shuttlecock/shuttlecock.dart';
import 'package:test/test.dart';

import '../testing_functions.dart';

// TODO: IterableMonad<A> === 1 + A + AxA + AxAxA + ... == 1 +
void main() {
  group('laws', () {
    test('map identity', () {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.map(identity);

      expect(bound, monadInstance);
    });

    test('map composition', () {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.map(stringToLength).map(decorate);
      final composedBound =
          monadInstance.map(compose(stringToLength, decorate));

      expect(bound, composedBound);
    });

    test('map flatMap composition', () {
      final monadInstance = _returnMonad(helloWorld);
      final flatMap =
          monadInstance.flatMap((s) => _returnMonad(stringToLength(s)));
      final map = monadInstance.map(stringToLength);

      expect(flatMap, map);
    });

    test('return flatMap f', () {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.flatMap(_f);

      expect(bound, _f(helloWorld));
    });

    test('m flatMap return', () {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.flatMap(_returnMonad);

      expect(bound, monadInstance);
    });

    test('composition', () {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.flatMap(_f).flatMap(_g);
      final composedBound = monadInstance.flatMap((s) => _f(s).flatMap(_g));

      expect(bound, composedBound);
    });
  });

  group('IterableMonad', () {
    test('apply', () {
      final iterable = new IterableMonad.fromIterable([1, 2, 3]);
      final functions =
          new IterableMonad.fromIterable([(i) => 2 * i, (i) => 3 * i]);

      final apply = iterable.app(functions).toList();

      expect(apply.length, 6);
      expect(apply, [2, 4, 6, 3, 6, 9]);
    });

    test('flatmap', () {
      final iterable = new IterableMonad.fromIterable([1, 2, 3]);
      IterableMonad<int> f(int i) => new IterableMonad.fromIterable([i, i * i]);

      final flatten = iterable.flatMap(f).toList();

      expect(flatten, hasLength(6));
      expect(flatten, [1, 1, 2, 4, 3, 9]);
    });
  });
}

IterableMonad<int> _f(s) => new IterableMonad.fromIterable([stringToLength(s)]);

IterableMonad<String> _g(s) => new IterableMonad.fromIterable([decorate(s)]);

IterableMonad<T> _returnMonad<T>(T value) =>
    new IterableMonad.fromIterable([value]);
