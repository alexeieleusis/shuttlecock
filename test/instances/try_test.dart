import 'package:shuttlecock/shuttlecock.dart';
import 'package:test/test.dart';

import '../testing_functions.dart';

void main() {
  group('laws', () {
    group('applicative', () {
      test('pure identity', () {
        // ignore: omit_local_variable_types
        final Try<Function1<String, String>> pureIdentity =
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

  group('Failure', () {
    Try<int> tryMe;

    setUp(() {
      tryMe = new Try<int>(() => throw new Exception('what'));
    });

    test('constructor', () {
      expect(tryMe is Failure, isTrue);
    });

    test('apply', () {
      final ap = new Try<Function1<int, int>>(() => (i) => i + 1);
      expect(tryMe.app(ap) is Failure, isTrue);
    });

    test('flatMap', () {
      expect(
          tryMe.flatMap((i) => new Try<int>(() => i + 1)) is Failure, isTrue);
    });

    test('map', () {
      expect(tryMe.map((i) => i + 1) is Failure, isTrue);
    });

    test('sum failure', () {
      expect(
          (tryMe + new Try<int>(() => throw new Exception('sum failure')))
              is Failure,
          isTrue);
    });

    test('sum success', () {
      final success = new Try<int>(() => 7);
      final monoid = tryMe + success;
      expect(monoid, success);
    });
  });

  group('success', () {
    Try<int> tryMe;

    setUp(() {
      tryMe = new Try(() => 7);
    });

    test('constructor', () {
      expect(tryMe is Success, isTrue);
    });

    test('apply success', () {
      final ap = new Try<Function1<int, int>>(() => (i) => i + 1);
      final Success<int> apply = tryMe.app(ap);
      expect(apply.value, 8);
    });

    test('apply failure', () {
      final ap = new Try<Function1<int, int>>(
          () => throw new Exception('apply failure'));
      expect(tryMe.app(ap) is Failure, isTrue);
    });

    test('flatMap', () {
      final Success<int> flatMap =
          tryMe.flatMap((i) => new Try<int>(() => i + 1));
      expect(flatMap.value, 8);
    });

    test('map', () {
      final Success<int> map = tryMe.map((i) => i + 1);
      expect(map.value, 8);
    });

    test('sum failure', () {
      expect(tryMe + new Try<int>(() => throw new Exception('sum failure')),
          tryMe);
    });

    test('sum success', () {
      final success = new Try<int>(() => 7);
      final monoid = tryMe + success;
      expect(monoid, tryMe);
    });
  });
}

Try<int> _f(s) => new Try(() => stringToLength(s));

Try<String> _g(s) => new Try(() => decorate(s));

Try<T> _returnMonad<T>(T value) => new Try(() => value);
