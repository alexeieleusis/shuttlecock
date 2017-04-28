import 'package:shuttlecock/shuttlecock.dart';
import 'package:test/test.dart';

import '../testing_functions.dart';

void main() {
  group('laws', () {
    group('applicative', () {
      test('pure identity', () {
        // ignore: omit_local_variable_types
        final Writer<StringMonoid, Function1<String, String>> pureIdentity =
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
}

Writer<StringMonoid, int> _f(String s) =>
    new Writer<StringMonoid, int>(stringToLength(s), new StringMonoid(' _f '));

Writer<StringMonoid, String> _g(int s) =>
    new Writer<StringMonoid, String>(decorate(s), new StringMonoid(' _g '));

Writer<StringMonoid, T> _returnMonad<T>(T value) =>
    new Writer<StringMonoid, T>(value, new StringMonoid(''));
