import 'dart:async';

import 'package:shuttlecock/shuttlecock.dart';

/// Wraps a FutureMonad in the monad interface.
class StreamMonad<T> extends Monad<T> implements Stream<T> {
  final Stream<T> _stream;

  /// Wraps the provided future.
  StreamMonad(Stream<T> stream) : _stream = stream;

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

  @override
  FutureMonad<bool> contains(Object needle) =>
      new FutureMonad(_stream.contains(needle));

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
  FutureMonad<S> fold<S>(
          // ignore: avoid_annotating_with_dynamic
          dynamic initialValue, dynamic combine(dynamic previous, T element)) =>
      new FutureMonad(_stream.fold(initialValue, combine));

  @override
  FutureMonad forEach(void action(T element)) =>
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

  @override
  FutureMonad pipe(StreamConsumer<T> streamConsumer) =>
      new FutureMonad(_stream.pipe(streamConsumer));

  @override
  FutureMonad<T> reduce(T combine(T previous, T element)) =>
      new FutureMonad(_stream.reduce(combine));

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
