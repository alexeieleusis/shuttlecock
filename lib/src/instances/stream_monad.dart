import 'dart:async';

import 'package:shuttlecock/shuttlecock.dart';
import 'package:tuple/tuple.dart';

/// Wraps a Stream in the monad interface.
class StreamMonad<T> extends Monad<T> implements Stream<T> {
  final Stream<T> _stream;

  /// Wraps the provided stream.
  StreamMonad(Stream<T> stream) : _stream = stream;

  /// Creates an empty stream.
  StreamMonad.empty() : _stream = const Stream.empty();

  /// Creates a Stream that immediately emits an error without emitting.
  StreamMonad.error([Exception exception, StackTrace stackTrace])
      : _stream = new StreamMonad(
            (new Future.error(exception, stackTrace).asStream()));

  /// Creates a stream that generates its elements dynamically from the same
  /// constructor in the Iterable class.
  StreamMonad.generate(int count, [T generator(int source)])
      : _stream =
            new Stream.fromIterable(new Iterable.generate(count, generator));

  /// Creates a stream that will never complete.
  StreamMonad.never() : _stream = (new Completer<T>().future).asStream();

  /// Creates a stream that emits only the provided value and completes.
  StreamMonad.of(T value)
      : _stream = new StreamMonad((new Future.value(value)).asStream());

  /// Creates a single subscription controller that emits after the specified
  /// delay periodically with the specified period.
  ///
  /// Default period is one second.
  factory StreamMonad.timer(
      {Duration period: const Duration(seconds: 1),
      T generator(int index),
      Duration delay: const Duration()}) {
    // Controller is single subscription and will never close itself.
    // ignore: close_sinks
    final controller = new StreamController();
    controller.onListen = () {
      new Future.delayed(delay).then((_) {
        controller.addStream(new Stream.periodic(delay, generator));
      });
    };
    return new StreamMonad(controller.stream);
  }

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
    controller.onListen = () {
      final appListFuture = app.toList();
      final listFuture = toList();
      Future.wait([appListFuture, listFuture]).then((_) {
        final iterable =
            new IterableMonad<T>.fromIterable(_.last as Iterable<T>);
        final appIterable = new IterableMonad<Function1<T, S>>.fromIterable(
            _.first as Iterable<Function1<T, S>>);
        controller
            .addStream(new Stream.fromIterable(iterable.app(appIterable)))
            .then((_) {
          if (!controller.isClosed) {
            controller.close();
          }
        });
      });
    };
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

  /// Buffers the events in this stream and emits then in batches of the
  /// specified size. Default value is a noop.
  StreamMonad<IterableMonad<T>> bufferCount({int size: 1}) {
    final controller = _stream.isBroadcast
        ? new StreamController<IterableMonad<T>>.broadcast()
        : new StreamController<IterableMonad<T>>();
    controller.onListen = () {
      var event = <T>[];
      listen((t) {
        event.add(t);
        if (event.length == size) {
          controller.add(new IterableMonad.fromIterable(event));
          event = <T>[];
        }
      }, onError: (error, stackTrace) {
        controller.addError(error, stackTrace);
        if (!controller.isClosed) {
          controller.close();
        }
      }, onDone: () {
        controller
          ..add(new IterableMonad.fromIterable(event))
          ..close();
      });
    };
    return new StreamMonad(controller.stream);
  }

  /// Combines this and another to create an stream whose events are
  /// calculated from the latest values of each stream.
  StreamMonad<E> combineLatest<S, E>(
      StreamMonad<S> other, E combine(T element, S otherElement)) {
    final controller = _stream.isBroadcast
        ? new StreamController<E>.broadcast()
        : new StreamController<E>();

    T firstElement;
    S otherFirstElement;
    StreamSubscription<T> thisSubscription;
    StreamSubscription<S> otherSubscription;

    // ignore: type_annotate_public_apis, This is not public!
    void onError(error, StackTrace stacktrace) {
      if (controller.isClosed) {
        return;
      }
      controller
        ..addError(error, stacktrace)
        ..close();
    }

    void onDone() {
      thisSubscription.cancel();
      otherSubscription.cancel();
      controller.close();
    }

    void processT(T element) {
      firstElement = element;
      if (controller.isClosed || otherFirstElement == null) {
        return;
      }
      controller.add(combine(firstElement, otherFirstElement));
    }

    void processS(S element) {
      otherFirstElement = element;
      if (controller.isClosed || firstElement == null) {
        return;
      }
      controller.add(combine(firstElement, otherFirstElement));
    }

    controller.onListen = () {
      thisSubscription = listen(processT, onError: onError, onDone: onDone);
      otherSubscription =
          other.listen(processS, onError: onError, onDone: onDone);
    };

    return new StreamMonad(controller.stream);
  }

  @override
  FutureMonad<bool> contains(Object needle) =>
      new FutureMonad(_stream.contains(needle));

  /// Emits a value from this only after a particular time span
  /// determined by the specified duration has passed without another source
  /// emission.
  StreamMonad<T> debounce(Duration duration) {
    final controller = _stream.isBroadcast
        ? new StreamController<T>.broadcast()
        : new StreamController<T>();

    controller.onListen = () {
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
    };

    return new StreamMonad(controller.stream);
  }

  /// Emits an event from this only after a particular time span
  /// has passed without another emission.
  StreamMonad<T> debounceTime(Duration duration) {
    final controller = _stream.isBroadcast
        ? new StreamController<T>.broadcast()
        : new StreamController<T>();
    Timer timer;
    controller.onListen = () {
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
    };

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
    var count = 0;
    var done = false;

    final controller = _stream.isBroadcast
        ? new StreamController<S>.broadcast()
        : new StreamController<S>();

    void _onError(error, stackTrace) {
      controller.addError(error, stackTrace);
      done = true;
      scheduleMicrotask(controller.close);
    }

    void _onData(T t) {
      // We don't want to do more work if already closed.
      if (controller.isClosed) {
        return;
      }
      // Count this event.
      count++;

      void _onDone() {
        count--;
        if (done && count == 0) {
          scheduleMicrotask(controller.close);
        }
      }

      // We start listening as we get the data.
      f(t).listen(controller.add,
          onError: controller.addError, onDone: _onDone, cancelOnError: true);
    }

    void _sourceDone() {
      done = true;
    }

    controller.onListen = () {
      _stream.listen(_onData, onError: _onError, onDone: _sourceDone);
    };
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
  FutureMonad<String> join([String separator = '']) =>
      new FutureMonad(_stream.join(separator));

  @override
  FutureMonad lastWhere(bool test(T element), {Object defaultValue()}) =>
      new FutureMonad(_stream.lastWhere(test, defaultValue: defaultValue));

  @override
  StreamSubscription<T> listen(void onData(T event),
          {Function onError, void onDone(), bool cancelOnError = true}) =>
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

  /// Subscribes to each this and the provided stream, and simply
  /// forwards (without doing any transformation) all the values from both to
  /// the output stream. The output stream only completes once both streams have
  /// completed. Any error delivered by any of the streams will be immediately
  /// emitted on the output stream.
  StreamMonad<T> merge(StreamMonad<T> other) {
    final merged = _stream.isBroadcast
        ? new StreamController<T>.broadcast()
        : new StreamController<T>();

    StreamSubscription<T> thisSubscription;
    StreamSubscription<T> otherSubscription;
    var thisIsDone = false;
    var otherIsDone = false;

    merged.onListen = () {
      thisSubscription =
          listen(merged.add, onError: merged.addError, onDone: () {
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
    };

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

  /// Returns a stream that emits items based on applying a function that
  /// you supply to each item emitted by the source stream, where that
  /// function returns an option, and then merging those resulting
  /// streams and emitting the results of this merger. Expand will re-emit
  /// on the output stream every source value. Then, each output value is
  /// given to the project function which returns an inner stream to be
  /// merged on the output stream. Those output values resulting from the
  /// projection are also given to the project function to produce new output
  /// values. This is how expand behaves recursively.
  StreamMonad<T> unfold(Function1<T, Option<T>> projection) {
    final controller = _stream.isBroadcast
        ? new StreamController<T>.broadcast()
        : new StreamController<T>();
    StreamSubscription<T> subscription;

    controller.onListen = () {
      subscription = listen((event) {
        controller.add(event);
        var option = projection(event);
        while (option.isNotEmpty) {
          final value = option.first;
          controller.add(value);
          option = projection(value);
        }
        controller.close();
        subscription.cancel();
      }, onError: (exception, stackTrace) {
        controller
          ..addError(exception, stackTrace)
          ..close();
      }, onDone: () {
        controller.close();
        subscription.cancel();
      });
    };

    return new StreamMonad(controller.stream);
  }

  @override
  StreamMonad<T> where(bool test(T event)) =>
      new StreamMonad(_stream.where(test));

  /// Creates a stream that emits the events produced by this and the provided
  /// stream in tuples.
  StreamMonad<Tuple2<T, S>> zip<S>(StreamMonad<S> other) {
    final controller = _stream.isBroadcast
        ? new StreamController<Tuple2<T, S>>.broadcast()
        : new StreamController<Tuple2<T, S>>();

    final ts = <T>[];
    final ss = <S>[];

    StreamSubscription<T> thisSubscription;
    StreamSubscription<S> otherSubscription;

    void onError(Exception error, StackTrace stacktrace) {
      if (controller.isClosed) {
        return;
      }
      controller.addError(error, stacktrace);
    }

    void onDone() {
      thisSubscription.cancel();
      otherSubscription.cancel();
      controller.close();
    }

    void addEvent(List ts, List ss, StreamController<Tuple2> controller) {
      final t = ts.removeAt(0);
      final s = ss.removeAt(0);
      controller.add(new Tuple2(t, s));
    }

    void processT(T element) {
      ts.add(element);
      if (controller.isClosed || ss.isEmpty) {
        return;
      }
      addEvent(ts, ss, controller);
    }

    void processS(S element) {
      ss.add(element);
      if (controller.isClosed || ts.isEmpty) {
        return;
      }
      addEvent(ts, ss, controller);
    }

    controller.onListen = () {
      thisSubscription = listen(processT, onError: onError, onDone: onDone);
      otherSubscription =
          other.listen(processS, onError: onError, onDone: onDone);
    };

    return new StreamMonad(controller.stream);
  }
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
