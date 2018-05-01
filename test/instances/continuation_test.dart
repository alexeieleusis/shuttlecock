import 'package:shuttlecock/shuttlecock.dart';
import 'package:test/test.dart';

import '../testing_functions.dart';

void main() {
  group('laws', () {
    group('applicative', () {
      test('pure identity', () {
        // ignore: omit_local_variable_types
        final Continuation<String, Function1<String, String>> pureIdentity =
            _returnMonad(identity);
        final monadInstance = _returnMonad(helloWorld);

        expect(monadInstance.app(pureIdentity)(_twice), monadInstance(_twice));
      });

      test('pure f app pure x', () {
        final pureStringToLength = _returnMonad(stringToLength);
        final monadInstance = _returnMonad(helloWorld);

        expect(monadInstance.app(pureStringToLength)(_twice),
            _returnMonad(stringToLength(helloWorld))(_twice));
      });

      test('interchange', () {
        final pureStringToLength = _returnMonad(stringToLength);
        final pureEval = _returnMonad(eval(helloWorld));
        final monadInstance = _returnMonad(helloWorld);

        expect(monadInstance.app(pureStringToLength)(_twice),
            pureStringToLength.app(pureEval)(_twice));
      });

      test('composition', () {
        final pureStringToLength = _returnMonad(stringToLength);
        final pureDecorate = _returnMonad(decorate);
        final pureComposition = _returnMonad(compose(decorate, stringToLength));
        final monadInstance = _returnMonad(helloWorld);

        expect(monadInstance.app(pureStringToLength).app(pureDecorate)(_twice),
            monadInstance.app(pureComposition)(_twice));
        final curried = curry<Function1<int, String>, Function1<String, int>,
            Function1<String, String>>(compose, decorate);
        expect(
            monadInstance
                .app(pureStringToLength.app(_returnMonad(curried)))(_twice),
            monadInstance.app(pureStringToLength).app(pureDecorate)(_twice));
      });

      test('map apply', () {
        final pureStringToLength = _returnMonad(stringToLength);
        final monadInstance = _returnMonad(helloWorld);
        expect(monadInstance.app(pureStringToLength)(_twice),
            monadInstance.map(stringToLength)(_twice));
      });
    });

    test('map identity', () {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.map(identity);

      expect(bound(_twice), monadInstance(_twice));
    });

    test('map composition', () {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.map(stringToLength).map(decorate);
      final composedBound =
          monadInstance.map(compose(decorate, stringToLength));

      expect(bound(_twice), composedBound(_twice));
    });

    test('map flatMap composition', () {
      final monadInstance = _returnMonad(helloWorld);
      final flatMap =
          monadInstance.flatMap((s) => _returnMonad(stringToLength(s)));
      final map = monadInstance.map(stringToLength);

      expect(flatMap(decorate), map(decorate));
    });

    test('return flatMap f', () {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.flatMap(_f);

      expect(bound(decorate), _f(helloWorld)(decorate));
    });

    test('m flatMap return', () {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.flatMap(_returnMonad);

      expect(bound(_twice), monadInstance(_twice));
    });

    test('composition', () {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.flatMap(_f).flatMap(_g);
      final composedBound = monadInstance.flatMap((s) => _f(s).flatMap(_g));

      expect(bound(_twice), composedBound(_twice));
    });
  });

  group('https://en.wikibooks.org/wiki/Haskell/Continuation_passing_style', () {
    test('pythagoras', () {
      int add(int x, int y) => x + y;
      int square(int x) => x * x;
      // return<int, int>
      Continuation<int, int> addCont(int x, int y) =>
          new Continuation(eval(add(x, y)));
      Continuation<int, int> squareCont(int x) =>
          new Continuation(eval(square(x)));

      // pythagoras_cont :: Int -> Int -> Cont r Int
      // pythagoras_cont x y = do
      //   x_squared <- square_cont x
      //   y_squared <- square_cont y
      //   add_cont x_squared y_squared
      Continuation<int, int> pythagorasCont(int x, int y) => squareCont(x)
          .flatMap((x1) => squareCont(y).flatMap((y1) => addCont(x1, y1)));

      expect(pythagorasCont(3, 4)(identity as Function1<int, int>), 25);
      expect(pythagorasCont(3, 4)(_timesTwo), 50);
      expect(pythagorasCont(5, 12)(identity as Function1<int, int>), 169);
    });
  });

  group('callCC', () {
    test('square', () {
      Continuation<int, int> _callCCSquare(int n) =>
          Continuation.callCC<int, int, int>((f) => f(n * n));

      expect(_callCCSquare(2)(identity as Function1<int, int>), 4);
      expect(_callCCSquare(3)(_timesTwo), 18);
    });
  });
}

Continuation<String, int> _f(String s) =>
    new Continuation<String, int>(eval(stringToLength(s)));

Continuation<String, String> _g(int s) =>
    new Continuation<String, String>(eval(decorate(s)));

Continuation<String, T> _returnMonad<T>(T value) =>
    new Continuation<String, T>(eval(value));

int _timesTwo(int x) => 2 * x;

String _twice(s) => '$s$s';
