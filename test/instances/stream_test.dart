import 'dart:async';

import 'package:shuttlecock/shuttlecock.dart';
import 'package:shuttlecock/src/instances/stream_monad.dart';
import 'package:test/test.dart';
import 'package:tuple/tuple.dart';

import '../testing_functions.dart';

/// These tests are a bit different because of asynchronicity. Structure is the
/// same as in other monad instances.
void main() {
  // For some weird reason this has to go first, otherwise laws group fails.
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
      final pureStringToLength =
          _returnMonad(stringToLength).asBroadcastStream();
      final pureDecorate = _returnMonad(decorate).asBroadcastStream();
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

  group('reactive extensions api', () {
    group('combineLatest', () {
      test('happy path 1', () async {
        // From http://reactivex.io/rxjs/class/es6/Observable.js~Observable.html#instance-method-combineLatest
        final weightsController = new StreamController<num>.broadcast();
        final weight = new StreamMonad(weightsController.stream);
        final heightsController = new StreamController<num>.broadcast();
        final height = new StreamMonad(heightsController.stream);
        final weights = [70, 72, 76, 79, 75];
        final heights = [1.76, 1.77, 1.78];

        final bmi = weight.combineLatest(height, (w, h) => w / (h * h));
        final actualFuture = bmi.toList();
        final bmis = [
          24.212293388429753,
          23.93948099205209,
          23.671253629592222
        ];

        await weightsController.addStream(new Stream.fromIterable(weights));
        await heightsController.addStream(new Stream.fromIterable(heights));
        // ignore: unawaited_futures, awaited below.
        weightsController.close();
        // ignore: unawaited_futures, awaited below.
        heightsController.close();

        final actual = await actualFuture;
        expect(actual, bmis);
      });

      test('happy path 2', () async {
        // From http://reactivex.io/rxjs/class/es6/Observable.js~Observable.html#instance-method-combineLatest
        Function buildSideEffect(String value, StreamController controller) =>
            () {
              controller.add(value);
            };

        final leftController = new StreamController<String>.broadcast();
        final rightController = new StreamController<String>.broadcast();
        final left = new StreamMonad(leftController.stream);
        final right = new StreamMonad(rightController.stream);

        final combined = left.combineLatest(right, (l, r) => '$l$r');
        final actualFuture = combined.toList();

        new Future.delayed(const Duration(microseconds: 1),
            buildSideEffect('a', leftController));
        new Future.delayed(const Duration(microseconds: 2),
            buildSideEffect('1', rightController));
        new Future.delayed(const Duration(microseconds: 3),
            buildSideEffect('b', leftController));
        new Future.delayed(const Duration(microseconds: 4),
            buildSideEffect('2', rightController));
        new Future.delayed(const Duration(microseconds: 5),
            buildSideEffect('3', rightController));
        new Future.delayed(const Duration(microseconds: 6),
            buildSideEffect('4', rightController));
        new Future.delayed(const Duration(microseconds: 7),
            buildSideEffect('c', leftController));
        new Future.delayed(const Duration(microseconds: 8),
            buildSideEffect('d', leftController));
        await new Future.delayed(const Duration(microseconds: 9),
            buildSideEffect('e', leftController));
        // ignore: unawaited_futures, awaited one line below.
        leftController.close();
        final actual = await actualFuture;

        expect(actual, ['a1', 'b1', 'b2', 'b3', 'b4', 'c4', 'd4', 'e4']);
      });
    });

    group('Timer', () {
      test('Wait and start', () async {
        var flag = 0;
        final timer = new StreamMonad.timer(
                generator: identity, delay: const Duration(microseconds: 200))
            .take(1);
        await new Future.delayed(const Duration(microseconds: 300));
        expect(flag, 0);
        await timer.toList().then((_) {
          flag = 1;
        });
        expect(flag, 1);
      });
    });

    group('merge', () {
      test('from docs', () async {
        final firstSource = new Stream.periodic(
            const Duration(microseconds: 200), (i) => 200 * i);
        final secondSource = new Stream.periodic(
            const Duration(microseconds: 300), (i) => 300 * i);
        final first = new StreamMonad(firstSource.take(5));
        final second = new StreamMonad(secondSource.take(3));

        final merged = first.merge(second);

        expect(await merged.toList(), [0, 0, 200, 300, 400, 600, 600, 800]);
      });
    });

    group('debounce', () {
      test('something', () async {
        final periodic = new Stream.periodic(
            const Duration(milliseconds: 6), (index) => index).take(10);

        final stream = new StreamMonad(periodic)
            .debounce(const Duration(milliseconds: 10));
        final actual = await stream.toList();

        // 3 and 8 might not be due to the async nature of streams.
        expect(actual, containsAllInOrder([0, 2, 5, 7, 9]));
      });
    });

    group('debounceTime', () {
      test('something', () async {
        final controller = new StreamController<int>.broadcast();
        new Stream.periodic(
                const Duration(milliseconds: 40), (index) => 4 * index)
            .take(10)
            .listen(controller.add);
        new Stream.periodic(
                const Duration(milliseconds: 50), (index) => 5 * index)
            .take(8)
            .listen(controller.add);

        final stream = new StreamMonad(controller.stream)
            .debounceTime(const Duration(milliseconds: 19));
        new Timer(const Duration(milliseconds: 430), controller.close);

        // 15 and 16 can be emitted in any order, same for 35 and 36.
        expect(
            await stream.toList(), containsAllInOrder([0, 8, 12, 20, 28, 32]));
      });
    });

    group('scan', () {
      test('Gauss sums', () {
        final stream = new StreamMonad(
            new Stream.fromIterable([1, 2, 3, 4]).asBroadcastStream());
        stream.scan(0, (f, s) => f + s).toList().then((list) {
          expect(list, [1, 3, 6, 10]);
        });
      });
    });

    group('replay', () {
      test('simple case', () async {
        final collected = [];
        final controller = new StreamController<int>.broadcast();
        final original = new StreamMonad(controller.stream);
        final subscription = original.replay().listen(collected.add);

        await controller.addStream(new Stream.fromIterable([0, 1, 2, 3]));
        // ignore: unawaited_futures
        await controller.close();

        expect(collected, [0, 1, 2, 3]);

        // ignore: unawaited_futures
        subscription.cancel();
      });

      test('buffer', () async {
        final collected = [];
        final controller = new StreamController<int>.broadcast();
        final original = new StreamMonad(controller.stream);

        final replay = original.replay(buffer: 2)
          // replay is always broadcasting but will not start listening the
          // underlying stream until a first subscription happens.
          ..listen((_) {});
        await controller.addStream(new Stream.fromIterable([0, 1, 2, 3]));
        final subscription = replay.listen(collected.add);
        // ignore: unawaited_futures
        await controller.close();

        expect(collected, [2, 3]);

        // ignore: unawaited_futures
        subscription.cancel();
      });

      test('window', () async {
        final collected = [];
        final controller = new StreamController<int>();
        final original = new StreamMonad(controller.stream);

        final replay = original.replay(window: const Duration(milliseconds: 18))
          // replay is always broadcasting but will not start listening the
          // underlying stream until a first subscription happens.
          ..listen((_) {});
        // ignore: unawaited_futures
        controller.addStream(
            new Stream.periodic(const Duration(milliseconds: 8), (i) => i)
                .take(4));
        await new Future.delayed(const Duration(milliseconds: 40));
        replay.listen(collected.add);
        await controller.close();

        expect(collected, [2, 3]);
      });
    });

    group('unfold', () {
      test('constructor unfoldOf taking 0', () async {
        final streamMonad =
            new StreamMonad.unfoldOf(1, (one) => new Option(one));
        final ones = await streamMonad.take(0).toList();
        expect(ones, []);
      });

      test('constructor unfoldOf taking 1', () async {
        final streamMonad =
            new StreamMonad.unfoldOf(1, (one) => new Option(one));
        final ones = await streamMonad.take(1).toList();
        expect(ones, [1]);
      });

      test('constructor unfoldOf taking 5', () async {
        final streamMonad =
            new StreamMonad.unfoldOf(1, (one) => new Option(one));
        final ones = await streamMonad.take(5).toList();
        expect(ones, [1, 1, 1, 1, 1]);
      });

      test('unfoldOf with map', () async {
        final streamMonad =
            new StreamMonad.unfoldOf(1, (one) => new Option(one));
        final ones = await streamMonad.map((n) => n * 2).take(1).toList();
        expect(ones, [2]);
      });

      test('unfoldOf with flatmap', () async {
        final ones = await new StreamMonad.unfoldOf(1, (one) => new Option(one))
            .flatMap((n) => new StreamMonad.of(n * 2))
            .take(1)
            .toList();
        expect(ones, [2]);
      });

      test('happy path', () async {
        final original = new StreamMonad(new Stream.fromIterable([1]));
        final unfolded = await original
            .unfold((i) => i == 8 ? new None() : new Some(2 * i))
            .toList();

        expect(unfolded, [1, 2, 4, 8]);
      });
    });

    group('flatMap', () {
      test('vanilla from single subscription stream that closes', () async {
        final ones = await new StreamMonad(new Stream.fromIterable([1, 1]))
            .flatMap((n) => new StreamMonad.of(n * 2))
            .toList();
        expect(ones, [2, 2]);
      });
    });

    group('zip', () {
      test('canonical example', () async {
        final first = new StreamMonad.generate(3);
        final second = new StreamMonad.generate(3, (i) => '$i $i');

        final zip = first.zip(second);

        expect(await zip.toList(), [
          const Tuple2(0, '0 0'),
          const Tuple2(1, '1 1'),
          const Tuple2(2, '2 2')
        ]);
      });
    });

    group('bufferCount', () {
      test('canonical example', () async {
        final first = new StreamMonad.generate(5);

        final buffered = first.bufferCount(size: 2);

        expect(await buffered.toList(), [
          new IterableMonad.fromIterable([0, 1]),
          new IterableMonad.fromIterable([2, 3]),
          new IterableMonad.fromIterable([4]),
        ]);
      });
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
          .asBroadcastStream()
          .flatMap((s) => _returnMonad(stringToLength(s)))
          .asBroadcastStream();
      final map =
          _returnMonad(helloWorld).map(stringToLength).asBroadcastStream();

      await Future.wait([flatMap.toList(), map.toList()]);
      expect(await flatMap.toList(), await map.toList());
    });

    test('return flatMap f', () async {
      final monadInstance = _returnMonad(helloWorld).asBroadcastStream();
      final bound = monadInstance.flatMap(_f);

      expect(await bound.toList(), await _f(helloWorld).toList());
    });

    test('m flatMap return', () async {
      final bound =
          _returnMonad(helloWorld).asBroadcastStream().flatMap(_returnMonad);

      expect(await bound.toList(), await _returnMonad(helloWorld).toList());
    });

    test('composition', () async {
      final bound =
          _returnMonad(helloWorld).asBroadcastStream().flatMap(_f).flatMap(_g);
      final composedBound = _returnMonad(helloWorld)
          .asBroadcastStream()
          .flatMap((s) => _f(s).asBroadcastStream().flatMap(_g));

      // composedBound requires to go through two cycles in the event loop.
      scheduleMicrotask(() async {
        expect(await bound.toList(), await composedBound.toList());
      });
    });
  });
}

StreamMonad<int> _f(s) =>
    new StreamMonad<int>(new Stream.fromIterable([stringToLength(s)]));

StreamMonad<String> _g(s) =>
    new StreamMonad<String>(new Stream.fromIterable([decorate(s)]));

StreamMonad<T> _returnMonad<T>(T value) =>
    new StreamMonad<T>(new Stream.fromIterable([value]));
