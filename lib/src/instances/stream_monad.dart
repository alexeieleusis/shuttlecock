import 'dart:async';

import 'package:shuttlecock/shuttlecock.dart';

/// Wraps a FutureMonad in the monad interface.
class StreamMonad<T> extends Monad<T> implements Stream<T> {
  final Stream<T> _stream;

  /// Wraps the provided future.
  StreamMonad(Stream<T> stream) : _stream = stream;

  /// Created an empty stream.
  StreamMonad.empty() : _stream = const Stream.empty();

  /// Creates a Stream that emits no items immediately emits an error
  /// notification.
  StreamMonad.error([Exception exception, StackTrace stackTrace])
      : _stream = new StreamMonad(
            (new Future.error(exception, stackTrace).asStream()));

  /// Creates a stream that will never complete.
  StreamMonad.never() : _stream = (new Completer<T>().future).asStream();

  /// Creates a stream that emits only the provided value and completes.
  StreamMonad.of(T value)
      : _stream = new StreamMonad((new Future.value(value)).asStream());

  @override
  FutureMonad<T> get first => new FutureMonad(_stream.first);

  @override
  bool get isBroadcast => _stream.isBroadcast;

  @override
  FutureMonad<bool> get isEmpty => new FutureMonad(_stream.isEmpty);

  @override
  FutureMonad<T> get last => new FutureMonad(_stream.last);

  @override
  FutureMonad<int> get length => new FutureMonad(_stream.length);

  @override
  FutureMonad<T> get single => new FutureMonad(_stream.single);

  @override
  FutureMonad<bool> any(bool test(T element)) =>
      new FutureMonad(_stream.any(test));

  @override
  StreamMonad<S> app<S>(StreamMonad<Function1<T, S>> app) {
    final controller = _stream.isBroadcast
        ? new StreamController<S>.broadcast()
        : new StreamController<S>();

    final appListFuture = app.toList();
    final listFuture = toList();
    Future.wait([appListFuture, listFuture]).then((_) {
      final appIterable = new IterableMonad<Function1<T, S>>.fromIterable(
          _.first as Iterable<Function1<T, S>>);
      final iterable = new IterableMonad<T>.fromIterable(_.last as Iterable<T>);
      controller
          .addStream(new Stream.fromIterable(iterable.app(appIterable)))
          .then((_) {
        controller.close();
      });
    });

    return new StreamMonad(controller.stream);
  }

  @override
  StreamMonad<T> asBroadcastStream(
          {void onListen(StreamSubscription<T> subscription),
          void onCancel(StreamSubscription<T> subscription)}) =>
      new StreamMonad(
          _stream.asBroadcastStream(onListen: onListen, onCancel: onCancel));

  @override
  StreamMonad<E> asyncExpand<E>(Stream<E> convert(T event)) =>
      new StreamMonad(_stream.asyncExpand(convert));

  @override
  StreamMonad<E> asyncMap<E>(FutureOr convert(T event)) =>
      new StreamMonad(_stream.asyncMap(convert));

  /// Combines multiple Observables to create an Observable whose values are
  /// calculated from the latest values of each of its input Observables.
  StreamMonad<E> combineLatest<S, E>(
      StreamMonad<S> other, E combine(T element, S otherElement)) {
    final combined = new StreamController<E>.broadcast();

    T firstElement;
    S otherFirstElement;
    StreamSubscription<T> thisSubscription;
    StreamSubscription<S> otherSubscription;

    // ignore: type_annotate_public_apis, This is not public!
    void onError(error, StackTrace stacktrace) {
      if (combined.isClosed) {
        return;
      }
      combined.addError(error, stacktrace);
    }

    void onDone() {
      thisSubscription.cancel();
      otherSubscription.cancel();
      combined.close();
    }

    void processT(T element) {
      firstElement = element;
      if (combined.isClosed || otherFirstElement == null) {
        return;
      }
      combined.add(combine(firstElement, otherFirstElement));
    }

    void processS(S element) {
      otherFirstElement = element;
      if (combined.isClosed || firstElement == null) {
        return;
      }
      combined.add(combine(firstElement, otherFirstElement));
    }

    thisSubscription = listen(processT, onError: onError, onDone: onDone);
    otherSubscription =
        other.listen(processS, onError: onError, onDone: onDone);

    return new StreamMonad(combined.stream);
  }

  @override
  FutureMonad<bool> contains(Object needle) =>
      new FutureMonad(_stream.contains(needle));

  /// Emits a value from the source Observable only after a particular time span
  /// determined by another Observable has passed without another source
  /// emission.
  StreamMonad<T> debounce(Duration duration) {
    final controller = new StreamController<T>.broadcast();
    var shouldClose = false;
    var emitted = false;
    T latest;
    listen(
        (data) {
          latest = data;
          emitted = true;
        },
        onError: controller.addError,
        onDone: () {
          shouldClose = true;
        });
    new Stream.periodic(duration, (index) => index).listen((index) {
      if (shouldClose) {
        scheduleMicrotask(controller.close);
      }
      if (!emitted) {
        return;
      }

      controller.add(latest);
      emitted = false;
    });

    return new StreamMonad(controller.stream);
  }

  /// Emits a value from the source Observable only after a particular time span
  /// has passed without another source emission.
  StreamMonad<T> debounceTime(Duration duration) {
    final controller = new StreamController<T>.broadcast();
    Timer timer;
    listen(
        (data) {
          timer?.cancel();
          timer = new Timer(duration, () {
            controller.add(data);
          });
        },
        onError: controller.addError,
        onDone: () {
          new Timer(duration, controller.close);
        });
    return new StreamMonad(controller.stream);
  }

  @override
  StreamMonad<T> distinct([bool equals(T previous, T next)]) =>
      new StreamMonad(_stream.distinct(equals));

  @override
  // ignore: avoid_annotating_with_dynamic
  FutureMonad<E> drain<E>([dynamic futureValue]) =>
      new FutureMonad(_stream.drain(futureValue));

  @override
  FutureMonad<T> elementAt(int index) =>
      new FutureMonad(_stream.elementAt(index));

  @override
  FutureMonad<bool> every(bool test(T element)) => _stream.every(test);

  @override
  StreamMonad<S> expand<S>(Iterable<S> convert(T value)) =>
      new StreamMonad(_stream.expand(convert));

  @override
  FutureMonad firstWhere(bool test(T element), {Object defaultValue()}) =>
      new FutureMonad(_stream.firstWhere(test, defaultValue: defaultValue));

  @override
  StreamMonad<S> flatMap<S>(Function1<T, StreamMonad<S>> f) {
    final controller = _stream.isBroadcast
        ? new StreamController<S>.broadcast()
        : new StreamController<S>();

    void _onError(error, stackTrace) {
      controller.addError(error, stackTrace);
    }

    void onData(T t) {
      f(t).toList().then((list) {
        list.forEach(controller.add);
      }, onError: _onError);
    }

    _stream
      ..listen(onData, onError: _onError, cancelOnError: false)
      ..last.then((_) {
        // If stream is sync we need to wait for one more event to be received
        // in the onData callback above.
        scheduleMicrotask(controller.close);
      });
    return new StreamMonad(controller.stream);
  }

  @override
  FutureMonad<S> fold<S>(S initialValue, S combine(S previous, T element)) =>
      scan(initialValue, combine).last;

  @override
  FutureMonad<Null> forEach(void action(T element)) =>
      new FutureMonad(_stream.forEach(action));

  @override
  // ignore: avoid_annotating_with_dynamic
  StreamMonad<T> handleError(Function onError, {bool test(dynamic error)}) =>
      new StreamMonad(_stream.handleError(onError, test: test));

  @override
  FutureMonad<String> join([String separator = ""]) =>
      new FutureMonad(_stream.join(separator));

  @override
  FutureMonad lastWhere(bool test(T element), {Object defaultValue()}) =>
      new FutureMonad(_stream.lastWhere(test, defaultValue: defaultValue));

  @override
  StreamSubscription<T> listen(void onData(T event),
          {Function onError, void onDone(), bool cancelOnError}) =>
      _stream.listen(onData, onError: onError, onDone: onDone);

  /// Creates a new stream that converts each element of this stream to a new
  /// value using the [f] function.
  ///
  /// For each data event, `o`, in this stream, the returned stream
  /// provides a data event with the value `convert(o)`.
  /// If [f] throws, the returned stream reports the exception as an error
  /// event instead.
  ///
  /// Error and done events are passed through unchanged to the returned stream.
  ///
  /// The returned stream is a broadcast stream if this stream is.
  /// The [f] function is called once per data event per listener.
  /// If a broadcast stream is listened to more than once, each subscription
  /// will individually call [f] on each data event.
  @override
  StreamMonad<S> map<S>(Function1<T, S> f) => new StreamMonad(_stream.map(f));

  /// subscribes to each given input Observable (as arguments), and simply
  /// forwards (without doing any transformation) all the values from all the
  /// input Observables to the output Observable. The output Observable only
  /// completes once all input Observables have completed. Any error delivered
  /// by an input Observable will be immediately emitted on the output
  /// Observable.
  StreamMonad<T> merge(StreamMonad<T> other) {
    final merged = new StreamController<T>.broadcast();

    StreamSubscription<T> thisSubscription;
    StreamSubscription<T> otherSubscription;
    var thisIsDone = false;
    var otherIsDone = false;

    thisSubscription = listen(merged.add, onError: merged.addError, onDone: () {
      thisIsDone = true;
      thisSubscription.cancel();
      if (!otherIsDone) {
        return;
      }
      merged.close();
    });
    otherSubscription =
        other.listen(merged.add, onError: merged.addError, onDone: () {
      otherIsDone = true;
      otherSubscription.cancel();
      if (!thisIsDone) {
        return;
      }
      merged.close();
    });

    return new StreamMonad(merged.stream);
  }

  @override
  FutureMonad pipe(StreamConsumer<T> streamConsumer) =>
      new FutureMonad(_stream.pipe(streamConsumer));

  @override
  FutureMonad<T> reduce(T combine(T previous, T element)) =>
      new FutureMonad(_stream.reduce(combine));

  /// Builds a special stream that captures all of the items that have been
  /// emitted, and re-emits them as the first items to any new
  /// listener.
  StreamMonad<T> replay({int buffer: 0, Duration window}) =>
      new _ReplayStream(_stream, buffer: buffer, window: window);

  /// Applies an accumulator function over the this stream, and returns each
  /// intermediate result. Similar to what fold does on Iterable but eatch
  /// step is emitted.
  StreamMonad<S> scan<S>(S initialValue, S combine(S previous, T element)) {
    var acc = initialValue;
    return map((t) => acc = combine(acc, t));
  }

  @override
  FutureMonad<T> singleWhere(bool test(T element)) =>
      new FutureMonad(_stream.singleWhere(test));

  @override
  StreamMonad<T> skip(int count) => new StreamMonad(_stream.skip(count));

  @override
  StreamMonad<T> skipWhile(bool test(T element)) =>
      new StreamMonad(_stream.skipWhile(test));

  @override
  StreamMonad<T> take(int count) => new StreamMonad(_stream.take(count));

  @override
  StreamMonad<T> takeWhile(bool test(T element)) =>
      new StreamMonad(_stream.takeWhile(test));

  @override
  StreamMonad<T> timeout(Duration timeLimit,
          {void onTimeout(EventSink<T> sink)}) =>
      new StreamMonad(_stream.timeout(timeLimit, onTimeout: onTimeout));

  @override
  FutureMonad<List<T>> toList() => new FutureMonad(_stream.toList());

  @override
  FutureMonad<Set<T>> toSet() => new FutureMonad(_stream.toSet());

  @override
  StreamMonad<S> transform<S>(StreamTransformer streamTransformer) =>
      new StreamMonad(_stream.transform(streamTransformer));

  @override
  StreamMonad<T> where(bool test(T event)) =>
      new StreamMonad(_stream.where(test));
}

class _ReplayStream<T> extends StreamMonad<T> {
  final _replayElements = <T>[];

  _ReplayStream(Stream stream, {int buffer: 0, Duration window})
      : super(stream) {
    StreamSubscription<T> subscription;
    subscription = stream.listen((event) {
      _replayElements.add(event);
      while (buffer > 0 && _replayElements.length > buffer) {
        _replayElements.removeAt(0);
      }
      if (window != null) {
        new Timer(window, () {
          _replayElements.remove(event);
        });
      }
    }, onDone: () {
      _replayElements.clear();
      subscription.cancel();
    });
  }

  @override
  StreamSubscription<T> listen(void onData(T event),
      {Function onError, void onDone(), bool cancelOnError}) {
    _replayElements.forEach(onData);
    return super.listen(onData, onError: onError, onDone: onDone);
  }
}
