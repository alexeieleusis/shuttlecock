import 'package:shuttlecock/shuttlecock.dart';
import 'package:test/test.dart';

void main() {
  group('identity', () {
    test('is endofunction', () {
      expect(identity is EndoFunction, isTrue);
    });

    test('is function of arity 1', () {
      expect(identity is Function1, isTrue);
    });

    test('after function does nothing', () {
      num halves(int x) => x / 2;
      expect(halves is Function1, isTrue);
      final idAfterHalves = compose(identity, halves);
      for (var i = 0; i < 100; i++) {
        expect(halves(i), equals(idAfterHalves(i)));
      }
    });

    test('before function does nothing', () {
      num halves(int x) => x / 2;
      expect(halves is Function1, isTrue);
      // ignore: omit_local_variable_types
      final Function1<int, num> idBeforeHalves = compose(identity, halves);
      for (var i = 0; i < 100; i++) {
        expect(halves(i), equals(idBeforeHalves(i)));
      }
    });
  });

  group('memoize', () {
    test('only invokes original function once', () {
      var counter = 0;
      int twice(int x) {
        // Side effect to verify number of invocations.
        counter++;
        return 2 * x;
      }

      final memoized = memoize(twice);

      for (var i = 0; i < 2; i++) {
        for (var j = 0; j < 50; j++) {
          expect(memoized(j), twice(j));
        }
      }

      expect(counter, equals(150));
    });
  });
}
