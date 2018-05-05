import 'package:shuttlecock/shuttlecock.dart';
import 'package:shuttlecock/src/instances/eval.dart';
import 'package:test/test.dart';

import '../testing_functions.dart';

void main() {
  group('laws', () {
    group('applicative', () {
      test('pure identity', () {
        // ignore: omit_local_variable_types
        final Eval<Function1<String, String>> pureIdentity =
            _returnMonad(identity);
        final monadInstance = _returnMonad(helloWorld);

        expect(monadInstance.app(pureIdentity).value, monadInstance.value);
      });

      test('pure f app pure x', () {
        final pureStringToLength = _returnMonad(stringToLength);
        final monadInstance = _returnMonad(helloWorld);

        expect(monadInstance.app(pureStringToLength).value,
            _returnMonad(stringToLength(helloWorld)).value);
      });

      test('interchange', () {
        final pureStringToLength = _returnMonad(stringToLength);
        final pureEval = _returnMonad(eval(helloWorld));
        final monadInstance = _returnMonad(helloWorld);

        expect(monadInstance.app(pureStringToLength).value,
            pureStringToLength.app(pureEval).value);
      });

      test('composition', () {
        final pureStringToLength = _returnMonad(stringToLength);
        final pureDecorate = _returnMonad(decorate);
        final pureComposition = _returnMonad(compose(decorate, stringToLength));
        final monadInstance = _returnMonad(helloWorld);

        expect(monadInstance.app(pureStringToLength).app(pureDecorate).value,
            monadInstance.app(pureComposition).value);
        final curried = curry<Function1<int, String>, Function1<String, int>,
            Function1<String, String>>(compose, decorate);
        expect(
            monadInstance
                .app(pureStringToLength.app(_returnMonad(curried)))
                .value,
            monadInstance.app(pureStringToLength).app(pureDecorate).value);
      });

      test('map apply', () {
        final pureStringToLength = _returnMonad(stringToLength);
        final monadInstance = _returnMonad(helloWorld);
        expect(monadInstance.app(pureStringToLength).value,
            monadInstance.map(stringToLength).value);
      });
    });

    test('map identity', () {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.map(identity);

      expect(bound.value, monadInstance.value);
    });

    test('map composition', () {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.map(stringToLength).map(decorate);
      final composedBound =
          monadInstance.map(compose(decorate, stringToLength));

      expect(bound.value, composedBound.value);
    });

    test('map flatMap composition', () {
      final monadInstance = _returnMonad(helloWorld);
      final flatMap =
          monadInstance.flatMap((s) => _returnMonad(stringToLength(s)));
      final map = monadInstance.map(stringToLength);

      expect(flatMap.value, map.value);
    });

    test('return flatMap f', () {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.flatMap(_f);

      expect(bound.value, _f(helloWorld).value);
    });

    test('m flatMap return', () {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.flatMap(_returnMonad);

      expect(bound.value, monadInstance.value);
    });

    test('composition', () {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.flatMap(_f).flatMap(_g);
      final composedBound = monadInstance.flatMap((s) => _f(s).flatMap(_g));

      expect(bound.value, composedBound.value);
    });
  });

  group('Some', () {
    Eval<int> eval;

    setUp(() {
      eval = new Now(7);
    });

    test('apply some', () {
      final ap = new Now<Function1<int, int>>((i) => i + 1);
      final apply = eval.app(ap);
      expect(apply.value, 8);
    });

    test('flatMap', () {
      final flatMap = eval.flatMap((i) => new Now<int>(i + 1));
      expect(flatMap.value, 8);
    });

    test('map', () {
      final map = eval.map((i) => i + 1);
      expect(map.value, 8);
    });

    test('composition with map and intermediary null', () {
      int fNull(int i) => null; // ignore: avoid_returning_null
      String constHello(int i) => 'Hello';
      final o = new Now<int>(0).map(fNull).map(constHello);
      expect(o.value, new Now('Hello').value);
    });
  });
}

Eval<int> _f(s) => new Now(stringToLength(s));

Eval<String> _g(s) => new Now(decorate(s));

Eval<T> _returnMonad<T>(T value) => new Now(value);
