import 'package:shuttlecock/shuttlecock.dart';
import 'package:test/test.dart';
import 'package:tuple/tuple.dart';

import '../testing_functions.dart';

void main() {
  group('laws', () {
    group('applicative', () {
      test('pure identity', () {
        // ignore: omit_local_variable_types
        final Either<int, Function1<String, String>> pureIdentity =
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

  group('Left', () {
    final value = 'foo';
    Either<String, int> left;

    setUp(() {
      left = new Left<String, int>(value);
    });

    test('apply left', () {
      final Either<String, int> apply =
          left.app(new Left<String, Function1<int, int>>(value));
      expect(apply is Left<String, int>, isTrue);
      expect((apply as Left).value, value);
    });

    test('apply right', () {
      final Either<String, int> apply =
          left.app(new Right<String, Function1<int, int>>(identity));
      expect(apply is Left<String, int>, isTrue);
      expect((apply as Left).value, value);
    });

    test('flatMap left', () {
      final Either<String, int> apply =
          left.flatMap((i) => new Left<String, int>('$value$i'));
      expect(apply is Left, isTrue);
      expect((apply as Left).value, value);
    });

    test('flatMap right', () {
      final Either<String, int> apply =
          left.flatMap((i) => new Right<String, int>(i + 1));
      expect(apply is Left, isTrue);
      expect((apply as Left).value, value);
    });

    test('map', () {
      final Either<String, int> apply = left.map((i) => i + 1);
      expect(apply is Left, isTrue);
      expect((apply as Left).value, value);
    });
  });

  group('Right', () {
    final value = 7;
    final string = 'value';
    Either<String, int> right;

    setUp(() {
      right = new Right<String, int>(value);
    });

    test('apply left', () {
      final Either<String, int> apply =
          right.app(new Left<String, Function1<int, int>>(string));
      expect(apply is Left, isTrue);
      expect((apply as Left).value, string);
    });

    test('apply right', () {
      final Either<String, int> apply =
          right.app(new Right<String, Function1<int, int>>((i) => i + 1));
      expect(apply is Right, isTrue);
      expect((apply as Right).value, value + 1);
    });

    test('flatMap left', () {
      final Either<String, int> apply =
          right.flatMap((i) => new Left<String, int>(string));
      expect(apply is Left, isTrue);
      expect((apply as Left).value, string);
    });

    test('flatMap right', () {
      final Either<String, int> apply =
          right.flatMap((i) => new Right<String, int>(i + 1));
      expect(apply is Right, isTrue);
      expect((apply as Right).value, value + 1);
    });

    test('map', () {
      final Either<String, int> apply = right.map((i) => i + 1);
      expect(apply is Right, isTrue);
      expect((apply as Right).value, value + 1);
    });
  });

  group(
      'product distributes sum ==='
      'Tuple2<A, Either<B, C>> == Either<Tuple2<A, B>, Tuple2<A, C>>', () {
    Either<Tuple2<A, B>, Tuple2<A, C>> f<A, B, C>(
        Tuple2<A, Either<B, C>> pair) {
      if (pair.item2 is Left<B, C>) {
        return new Left<Tuple2<A, B>, Tuple2<A, C>>(
            new Tuple2<A, B>(pair.item1, pair.item2.value));
      }

      return new Right<Tuple2<A, B>, Tuple2<A, C>>(
          new Tuple2<A, C>(pair.item1, pair.item2.value));
    }

    Tuple2<A, Either<B, C>> g<A, B, C>(
        Either<Tuple2<A, B>, Tuple2<A, C>> either) {
      if (either is Left<Tuple2<A, B>, Tuple2<A, C>>) {
        return new Tuple2<A, Either<B, C>>(
            either.value.item1, new Left<B, C>(either.value.item2));
      }

      return new Tuple2<A, Either<B, C>>(
          either.value.item1, new Right<B, C>(either.value.item2));
    }

    test('identity == compose(f, g)', () {
      final v1 = new Tuple2(2, new Left('22'));
      final v2 = new Tuple2(3, new Right(33));

      expect(g(f(v1)), v1);
      expect(g(f(v2)), v2);
    });

    test('identity == compose(g, f)', () {
      final Either<Tuple2<int, String>, Tuple2<int, int>> v1 =
          new Left<Tuple2<int, String>, Tuple2<int, int>>(
              const Tuple2<int, String>(2, '22'));

      final Either<Tuple2<int, String>, Tuple2<int, int>> v2 =
          new Right<Tuple2<int, String>, Tuple2<int, int>>(
              const Tuple2<int, int>(3, 33));

      // There is a bug in tuple that forces us to use value.
      expect(f(g(v1)), v1);
      expect(f(g(v2)), v2);
    });
  });
}

Either<int, int> _f(s) => new Right<int, int>(stringToLength(s));

Either<int, String> _g(s) => new Right<int, String>(decorate(s));

Either<int, T> _returnMonad<T>(T value) => new Right<int, T>(value);
