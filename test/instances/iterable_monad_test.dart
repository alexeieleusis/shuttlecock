import 'package:shuttlecock/shuttlecock.dart';
import 'package:test/test.dart';

import '../testing_functions.dart';

// TODO: IterableMonad<A> === 1 + A + AxA + AxAxA + ... == 1 +
void main() {
  group('laws', () {
    group('applicative', () {
      test('pure identity', () {
        // ignore: omit_local_variable_types
        final IterableMonad<Function1<String, String>> pureIdentity =
            _returnMonad(identity);
        final monadInstance = _returnMonad(helloWorld);

        expect(monadInstance.app(pureIdentity), monadInstance);
      });

      test('pure f app pure x', () {
        final pureStringToLength = _returnMonad(stringToLength);
        final monadInstance = _returnMonad(helloWorld);

        expect(monadInstance.app(pureStringToLength),
            _returnMonad(stringToLength(helloWorld)));
      });

      test('interchange', () {
        final pureStringToLength = _returnMonad(stringToLength);
        final pureEval = _returnMonad(eval(helloWorld));
        final monadInstance = _returnMonad(helloWorld);

        expect(monadInstance.app(pureStringToLength),
            pureStringToLength.app(pureEval));
      });

      test('composition', () {
        final pureStringToLength = _returnMonad(stringToLength);
        final pureDecorate = _returnMonad(decorate);
        final pureComposition = _returnMonad(compose(decorate, stringToLength));
        final monadInstance = _returnMonad(helloWorld);

        expect(monadInstance.app(pureStringToLength).app(pureDecorate),
            monadInstance.app(pureComposition));
        expect(
            monadInstance.app(
                pureStringToLength.app(_returnMonad(curry(compose, decorate)))),
            monadInstance.app(pureStringToLength).app(pureDecorate));
      });

      test('map apply', () {
        final pureStringToLength = _returnMonad(stringToLength);
        final monadInstance = _returnMonad(helloWorld);

        expect(monadInstance.app(pureStringToLength),
            monadInstance.map(stringToLength));
      });
    });

    test('map identity', () {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.map(identity);

      expect(bound, monadInstance);
    });

    test('map composition', () {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.map(stringToLength).map(decorate);
      final composedBound =
          monadInstance.map(compose(decorate, stringToLength));

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

  group('unfold', () {
    test('seed', () {
      Option<int> f(int x) => x < 5 ? new Option(x + 1) : new None();

      expect(new IterableMonad.unfoldSeed(0, f), [0, 1, 2, 3, 4, 5]);
    });

    test('iterable', () {
      Option<int> f(int x) => x < 30 ? new Option(2 * x) : new None();

      expect(new IterableMonad.fromIterable([1, 2, 3]).unfold(f),
          [1, 2, 4, 8, 16, 32, 2, 4, 8, 16, 32, 3, 6, 12, 24, 48]);
    });
  });
}

IterableMonad<int> _f(s) => new IterableMonad.fromIterable([stringToLength(s)]);

IterableMonad<String> _g(s) => new IterableMonad.fromIterable([decorate(s)]);

IterableMonad<T> _returnMonad<T>(T value) =>
    new IterableMonad.fromIterable([value]);
