import 'package:shuttlecock/shuttlecock.dart';
import 'package:test/test.dart';

import '../testing_functions.dart';

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
}

Writer<StringMonoid, int> _f(String s) =>
    new Writer<StringMonoid, int>(stringToLength(s), new StringMonoid(' _f '));

Writer<StringMonoid, String> _g(int s) =>
    new Writer<StringMonoid, String>(decorate(s), new StringMonoid(' _g '));

Writer<StringMonoid, T> _returnMonad<T>(T value) =>
    new Writer<StringMonoid, T>(value, new StringMonoid(''));
