import 'package:shuttlecock/shuttlecock.dart';
import 'package:shuttlecock/src/instances/reader.dart';
import 'package:test/test.dart';

import '../testing_functions.dart';

void main() {
  group('laws', () {
    test('map identity', () {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.map(identity);

      expect(bound(0), monadInstance(0));
    });

    test('map composition', () {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.map(stringToLength).map(decorate);
      final composedBound =
          monadInstance.map(compose(stringToLength, decorate));

      expect(bound(0), composedBound(0));
    });

    test('map flatMap composition', () {
      final monadInstance = _returnMonad(helloWorld);
      final flatMap =
          monadInstance.flatMap((s) => _returnMonad(stringToLength(s)));
      final map = monadInstance.map(stringToLength);

      expect(flatMap(0), map(0));
    });

    test('return flatMap f', () {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.flatMap(_f);

      expect(bound(0), _f(helloWorld)(0));
    });

    test('m flatMap return', () {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.flatMap(_returnMonad);

      expect(bound(0), monadInstance(0));
    });

    test('composition', () {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.flatMap(_f).flatMap(_g);
      final composedBound = monadInstance.flatMap((s) => _f(s).flatMap(_g));

      expect(bound(0), composedBound(0));
    });
  });
}

Reader<int, int> _f(s) => new Reader<int, int>.returnReader(stringToLength(s));

Reader<int, String> _g(s) => new Reader<int, String>.returnReader(decorate(s));

Reader<int, T> _returnMonad<T>(T value) =>
    new Reader<int, T>.returnReader(value);
