import 'package:shuttlecock/shuttlecock.dart';
import 'package:test/test.dart';

import '../testing_functions.dart';

// TODO: Either<Null, A> === Option<A>
void main() {
  group('laws', () {
    group('applicative', () {
      test('pure identity', () {
        // ignore: omit_local_variable_types
        final Option<Function1<String, String>> pureIdentity =
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

  group('None', () {
    Option<int> option;

    setUp(() {
      option = new Option<int>(null);
    });

    test('constructor', () {
      expect(option is None, isTrue);
    });

    test('apply', () {
      final ap = new Option<Function1<int, int>>((i) => i + 1);
      expect(option.app(ap) is None, isTrue);
    });

    test('flatMap', () {
      expect(option.flatMap((i) => new Option<int>(i + 1)) is None, isTrue);
    });

    test('map', () {
      expect(option.map((i) => i + 1) is None, isTrue);
    });

    test('sum none', () {
      expect((option + new Option<int>(null)) is None, isTrue);
    });

    test('sum some', () {
      final some = new Option<int>(7);
      final monoid = option + some;
      expect(monoid, some);
    });
  });

  group('some', () {
    Option<int> option;

    setUp(() {
      option = new Option(7);
    });

    test('constructor', () {
      expect(option is Some, isTrue);
    });

    test('apply some', () {
      final ap = new Option<Function1<int, int>>((i) => i + 1);
      final Some<int> apply = option.app(ap);
      expect(apply.value, 8);
    });

    test('apply none', () {
      final ap = new Option<Function1<int, int>>(null);
      expect(option.app(ap) is None, isTrue);
    });

    test('flatMap', () {
      final Some<int> flatMap = option.flatMap((i) => new Option<int>(i + 1));
      expect(flatMap.value, 8);
    });

    test('map', () {
      final Some<int> map = option.map((i) => i + 1);
      expect(map.value, 8);
    });

    test('sum none', () {
      expect(option + new Option<int>(null), option);
    });

    test('sum some', () {
      final some = new Option<int>(7);
      final monoid = option + some;
      expect(monoid, option);
    });

    test('sheep example', () {
      final greatGrandFather = new Sheep();
      final grandFather = new Sheep(father: greatGrandFather);
      final mother = new Sheep(father: grandFather);
      final sheep = new Sheep(mother: mother);
      expect(sheep.father.flatMap((s) => s.mother) is None, isTrue);
      expect(sheep.grandParent, new Option(grandFather));
      expect(sheep.maternalGrandFather, new Option(greatGrandFather));
    });
  });
}

Option<int> _f(s) => new Option(stringToLength(s));

Option<String> _g(s) => new Option(decorate(s));

Option<T> _returnMonad<T>(T value) => new Option(value);

/// Example in https://wiki.haskell.org/All_About_Monads#An_example
class Sheep {
  /// The father if not a clone.
  final Option<Sheep> father;

  /// The mother if not a clone.
  final Option<Sheep> mother;

  /// Properly initializes the parents.
  Sheep({Sheep father, Sheep mother})
      : father = new Option(father),
        mother = new Option(mother);

  /// The first non null.
  Option<Sheep> get grandParent => parent.flatMap((s) => s.parent);

  /// What it says.
  Option<Sheep> get maternalGrandFather =>
      mother.flatMap((s) => s.father).flatMap((s) => s.father);

  /// Returns father + mother, i.e. the first not null.
  Option<Sheep> get parent => father + mother;
}
