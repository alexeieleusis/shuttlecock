import 'package:shuttlecock/shuttlecock.dart';
import 'package:shuttlecock/src/instances/identity_monad.dart';
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

  group('Left', () {
    final value = 7;
    IdentityMonad<int> monad;

    setUp(() {
      monad = new IdentityMonad(value);
    });

    test('apply', () {
      final ap = new IdentityMonad<Function1<int, int>>((i) => i + 1);
      expect(monad.app(ap).value, 8);
    });

    test('flatMap', () {
      expect(monad.flatMap((i) => new IdentityMonad(i + 1)).value, 8);
    });

    test('map', () {
      expect(monad.map((i) => i + 1).value, 8);
    });
  });
}

IdentityMonad<int> _f(s) => new IdentityMonad(stringToLength(s));

IdentityMonad<String> _g(s) => new IdentityMonad(decorate(s));

IdentityMonad<T> _returnMonad<T>(T value) => new IdentityMonad(value);
