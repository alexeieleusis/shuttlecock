import 'dart:async';

import 'package:shuttlecock/shuttlecock.dart';
import 'package:shuttlecock/src/instances/future_monad.dart';
import 'package:test/test.dart';

import '../testing_functions.dart';

void main() {
  group('laws', () {
    group('applicative', () {
      test('pure identity', () async {
        // ignore: omit_local_variable_types
        final FutureMonad<Function1<String, String>> pureIdentity =
            _returnMonad(identity);
        final monadInstance = _returnMonad(helloWorld);

        expect(await monadInstance.app(pureIdentity), await monadInstance);
      });

      test('pure f app pure x', () async {
        final pureStringToLength = _returnMonad(stringToLength);
        final monadInstance = _returnMonad(helloWorld);

        expect(await monadInstance.app(pureStringToLength),
            await _returnMonad(stringToLength(helloWorld)));
      });

      test('interchange', () async {
        final pureStringToLength = _returnMonad(stringToLength);
        final pureEval = _returnMonad(eval(helloWorld));
        final monadInstance = _returnMonad(helloWorld);

        expect(await monadInstance.app(pureStringToLength),
            await pureStringToLength.app(pureEval));
      });

      test('composition', () async {
        final pureStringToLength = _returnMonad(stringToLength);
        final pureDecorate = _returnMonad(decorate);
        final pureComposition = _returnMonad(compose(decorate, stringToLength));
        final monadInstance = _returnMonad(helloWorld);

        expect(await monadInstance.app(pureStringToLength).app(pureDecorate),
            await monadInstance.app(pureComposition));
        expect(
            await monadInstance.app(
                pureStringToLength.app(_returnMonad(curry(compose, decorate)))),
            await monadInstance.app(pureStringToLength).app(pureDecorate));
      });

      test('map apply', () async {
        final pureStringToLength = _returnMonad(stringToLength);
        final monadInstance = _returnMonad(helloWorld);

        expect(await monadInstance.app(pureStringToLength),
            await monadInstance.map(stringToLength));
      });
    });

    test('map identity', () async {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.map(identity);

      expect(await bound, await monadInstance);
    });

    test('map composition', () async {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.map(stringToLength).map(decorate);
      final composedBound =
          monadInstance.map(compose(decorate, stringToLength));

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

    test('flatmap chained', () async {
      final future = new FutureMonad.of(new FutureMonad.of(1));
      expect(await future.flatMap((x) => new FutureMonad.of(x is int)), false);
      expect(await future.flatMap((x) => new FutureMonad.of(x is FutureMonad)),
          true);
      // ignore: unrelated_type_equality_checks
      expect(await future.flatMap((x) => new FutureMonad.of(x == 1)), false);
      expect(await future, 1);
    });
  });
}

FutureMonad<int> _f(s) =>
    new FutureMonad<int>(new Future.value(stringToLength(s)));

FutureMonad<String> _g(s) =>
    new FutureMonad<String>(new Future.value(decorate(s)));

FutureMonad<T> _returnMonad<T>(T value) =>
    new FutureMonad<T>(new Future.value(value));
