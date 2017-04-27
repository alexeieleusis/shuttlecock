import 'dart:async';
import 'package:shuttlecock/shuttlecock.dart';
import 'package:shuttlecock/src/instances/future_monad.dart';
import 'package:test/test.dart';

import '../testing_functions.dart';

void main() {
  group('laws', () {
    test('map identity', () async {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.map(identity);

      expect(await bound, await monadInstance);
    });

    test('map composition', () async {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.map(stringToLength).map(decorate);
      final composedBound =
          monadInstance.map(compose(stringToLength, decorate));

      expect(await bound, await composedBound);
    });

    test('map flatMap composition', () async {
      final monadInstance = _returnMonad(helloWorld);
      final flatMap =
          monadInstance.flatMap((s) => _returnMonad(stringToLength(s)));
      final map = monadInstance.map(stringToLength);

      expect(await flatMap, await map);
    });

    test('return flatMap f', () async {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.flatMap(_f);

      expect(await bound, await _f(helloWorld));
    });

    test('m flatMap return', () async {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.flatMap(_returnMonad);

      expect(await bound, await monadInstance);
    });

    test('composition', () async {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.flatMap(_f).flatMap(_g);
      final composedBound = monadInstance.flatMap((s) => _f(s).flatMap(_g));

      expect(await bound, await composedBound);
    });
  });
}

FutureMonad<int> _f(s) =>
    new FutureMonad<int>(new Future.value(stringToLength(s)));

FutureMonad<String> _g(s) =>
    new FutureMonad<String>(new Future.value(decorate(s)));

FutureMonad<T> _returnMonad<T>(T value) =>
    new FutureMonad<T>(new Future.value(value));
