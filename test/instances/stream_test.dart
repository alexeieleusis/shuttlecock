import 'dart:async';

import 'package:shuttlecock/shuttlecock.dart';
import 'package:shuttlecock/src/instances/stream_monad.dart';
import 'package:test/test.dart';

import '../testing_functions.dart';

/// These tests are a bit different because of asynchronisity. Structure is the
/// same as in other monad instances.
void main() {
  // For some weird reason this has to go first, otherwise laws group fails.
  group('applicative', () {
    group('applicative', () {
      test('pure identity', () async {
        // ignore: omit_local_variable_types
        final StreamMonad<Function1<String, String>> pureIdentity =
            _returnMonad(identity);

        expect(await _returnMonad(helloWorld).app(pureIdentity).toList(),
            await _returnMonad(helloWorld).toList());
      });

      test('pure f app pure x', () async {
        final pureStringToLength = _returnMonad(stringToLength);
        final monadInstance = _returnMonad(helloWorld);

        expect(await monadInstance.app(pureStringToLength).toList(),
            await _returnMonad(stringToLength(helloWorld)).toList());
      });

      test('interchange', () async {
        final pureEval = _returnMonad(eval(helloWorld));

        final monadInstance = _returnMonad(helloWorld);

        expect(await monadInstance.app(_returnMonad(stringToLength)).toList(),
            await _returnMonad(stringToLength).app(pureEval).toList());
      });

      test('composition', () async {
        final pureStringToLength = _returnMonad(stringToLength);
        final pureDecorate = _returnMonad(decorate);
        final pureComposition = _returnMonad(compose(decorate, stringToLength));

        expect(
            await _returnMonad(helloWorld)
                .app(pureStringToLength)
                .app(pureDecorate)
                .toList(),
            await _returnMonad(helloWorld).app(pureComposition).toList());
        expect(
            await _returnMonad(helloWorld)
                .app(pureStringToLength
                    .app(_returnMonad(curry(compose, decorate))))
                .toList(),
            await _returnMonad(helloWorld)
                .app(pureStringToLength)
                .app(pureDecorate)
                .toList());
      });

      test('map apply', () async {
        final pureStringToLength = _returnMonad(stringToLength);
        expect(await _returnMonad(helloWorld).app(pureStringToLength).toList(),
            await _returnMonad(helloWorld).map(stringToLength).toList());
      });
    });

    test('apply', () async {
      final stream = new StreamMonad(
          new Stream.fromIterable([1, 2, 3]).asBroadcastStream());
      final functions = new StreamMonad(
          new Stream.fromIterable([(i) => 2 * i, (i) => 3 * i])
              .asBroadcastStream());

      final apply = await stream.app(functions).toList();

      expect(apply.length, 6);
      expect(apply, [2, 4, 6, 3, 6, 9]);
    });
  });

  group('laws', () {
    test('map identity', () async {
      final monadInstance = _returnMonad(helloWorld);
      final expected = await monadInstance.toList();
      final bound = _returnMonad(helloWorld).map(identity);
      final actual = await bound.toList();

      expect(actual, expected);
    });

    test('map composition', () async {
      final bound = _returnMonad(helloWorld).map(stringToLength).map(decorate);
      final composedBound =
          _returnMonad(helloWorld).map(compose(decorate, stringToLength));

      final actual = await bound.toList();
      final expected = await composedBound.toList();
      expect(actual, expected);
    });

    test('map flatMap composition', () async {
      final flatMap = _returnMonad(helloWorld)
          .flatMap((s) => _returnMonad(stringToLength(s)));
      final map = _returnMonad(helloWorld).map(stringToLength);

      await Future.wait([flatMap.toList(), map.toList()]);
      expect(await flatMap.toList(), await map.toList());
    });

    test('return flatMap f', () async {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.flatMap(_f);

      expect(await bound.toList(), await _f(helloWorld).toList());
    });

    test('m flatMap return', () async {
      final bound = _returnMonad(helloWorld).flatMap(_returnMonad);

      expect(await bound.toList(), await _returnMonad(helloWorld).toList());
    });

    test('composition', () async {
      final bound = _returnMonad(helloWorld).flatMap(_f).flatMap(_g);
      final composedBound =
          _returnMonad(helloWorld).flatMap((s) => _f(s).flatMap(_g));

      // composedBound requires to go through two cycles in the event loop.
      scheduleMicrotask(() async {
        expect(await bound.toList(), await composedBound.toList());
      });
    });
  });
}

StreamMonad<int> _f(s) => new StreamMonad<int>(
    new Stream.fromIterable([stringToLength(s)]).asBroadcastStream());

StreamMonad<String> _g(s) => new StreamMonad<String>(
    new Stream.fromIterable([decorate(s)]).asBroadcastStream());

StreamMonad<T> _returnMonad<T>(T value) =>
    new StreamMonad<T>(new Stream.fromIterable([value]).asBroadcastStream());
