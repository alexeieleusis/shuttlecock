import 'package:shuttlecock/src/category_theory/functions.dart';
import 'package:shuttlecock/src/instances/state.dart';
import 'package:test/test.dart';
import 'package:tuple/tuple.dart';

import '../testing_functions.dart';

void main() {
  group('laws', () {
    group('applicative', () {
      test('pure identity', () {
        // ignore: omit_local_variable_types
        final State<int, Function1<String, String>> pureIdentity =
            _returnMonad(identity);
        final monadInstance = _returnMonad(helloWorld);

        expect(monadInstance.app(pureIdentity)(0), monadInstance(0));
      });

      test('pure f app pure x', () {
        final pureStringToLength = _returnMonad(stringToLength);
        final monadInstance = _returnMonad(helloWorld);

        expect(monadInstance.app(pureStringToLength)(0),
            _returnMonad(stringToLength(helloWorld))(0));
      });

      test('interchange', () {
        final pureStringToLength = _returnMonad(stringToLength);
        final pureEval = _returnMonad(eval(helloWorld));
        final monadInstance = _returnMonad(helloWorld);

        expect(monadInstance.app(pureStringToLength)(0),
            pureStringToLength.app(pureEval)(0));
      });

      test('composition', () {
        final pureStringToLength = _returnMonad(stringToLength);
        final pureDecorate = _returnMonad(decorate);
        final pureComposition = _returnMonad(compose(decorate, stringToLength));
        final monadInstance = _returnMonad(helloWorld);

        expect(monadInstance.app(pureStringToLength).app(pureDecorate)(0),
            monadInstance.app(pureComposition)(0));
        final curried = curry<Function1<int, String>, Function1<String, int>,
            Function1<String, String>>(compose, decorate);
        expect(
            monadInstance.app(pureStringToLength.app(_returnMonad(curried)))(0),
            monadInstance.app(pureStringToLength).app(pureDecorate)(0));
      });

      test('map apply', () {
        final pureStringToLength = _returnMonad(stringToLength);
        final monadInstance = _returnMonad(helloWorld);
        expect(monadInstance.app(pureStringToLength)(0),
            monadInstance.map(stringToLength)(0));
      });
    });

    test('map identity', () {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.map(identity);

      expect(bound(5).item1, monadInstance(5).item1);
      expect(bound(5).item2, monadInstance(5).item2);
      expect(bound(5).item1, helloWorld);
      expect(bound(5).item2, 5);
    });

    test('map composition', () {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.map(stringToLength).map(decorate);
      final composedBound =
          monadInstance.map(compose(decorate, stringToLength));

      expect(bound(5).item1, composedBound(5).item1);
      expect(bound(5).item2, composedBound(5).item2);
    });

    test('map flatMap composition', () {
      final monadInstance = _returnMonad(helloWorld);
      final flatMap =
          monadInstance.flatMap((s) => _returnMonad(stringToLength(s)));
      final map = monadInstance.map(stringToLength);

      expect(flatMap(5).item1, map(5).item1);
      expect(flatMap(5).item2, map(5).item2);
    });

    test('return flatMap f', () {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.flatMap(_f);

      expect(bound(5).item1, _f(helloWorld)(5).item1);
      expect(bound(5).item2, _f(helloWorld)(5).item2);
      expect(bound(5).item1, stringToLength(helloWorld));
      expect(bound(5).item2, 5);
    });

    test('m flatMap return', () {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.flatMap(_returnMonad);

      expect(bound(5).item1, monadInstance(5).item1);
      expect(bound(5).item2, monadInstance(5).item2);
      expect(bound(5).item1, helloWorld);
      expect(bound(5).item2, 5);
    });

    test('composition', () {
      final monadInstance = _returnMonad(helloWorld);
      final bound = monadInstance.flatMap(_f).flatMap(_g);
      final composedBound = monadInstance.flatMap((s) => _f(s).flatMap(_g));

      expect(bound(5).item1, composedBound(5).item1);
      expect(bound(5).item2, composedBound(5).item2);
    });
  });

  // From http://learnyouahaskell.com/for-a-few-monads-more#state
  group('state stack', () {
    final pop = new State(_popH);

    const expected = const Tuple2<int, List<int>>(1, const [5, 8, 2]);
    const stack = const [5, 8, 2, 1];

    test('by hand', () {
      final newStack1 = _pushH(3, stack);
      final newStack2 = _popH(newStack1.item2);
      final actual = _popH(newStack2.item2);

      expect(actual.item1, expected.item1);
      expect(actual.item2, expected.item2);
    });

    test('with monads', () {
      final stackManip = new State(_buildPushRunState(3))
          .flatMap((stack) => pop)
          .flatMap((stack) => pop);

      final actual = stackManip(stack);

      expect(actual.item1, expected.item1);
      expect(actual.item2, expected.item2);
    });
  });
}

RunState<List<int>, Null> _buildPushRunState(int a) =>
    (stack) => _pushH(a, stack);

State<int, int> _f(s) => new State.returnState(stringToLength(s));

State<int, String> _g(s) => new State.returnState(decorate(s));

Tuple2<int, List<int>> _popH(List<int> stack) {
  final newStack = new List<int>.from(stack);
  final top = newStack.removeLast();
  return new Tuple2<int, List<int>>(top, newStack);
}

Tuple2<Null, List<int>> _pushH(int newTop, List<int> stack) =>
    new Tuple2<Null, List<int>>(null, new List<int>.from(stack)..add(newTop));

State<int, T> _returnMonad<T>(T value) => new State.returnState(value);
