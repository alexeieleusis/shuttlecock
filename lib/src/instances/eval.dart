import 'package:meta/meta.dart';
import 'package:shuttlecock/src/category_theory/functions.dart';
import 'package:shuttlecock/src/category_theory/monad.dart';

typedef T EvalComputation<T>();

class Always<T> extends _WithComputation<T> {
  Always(EvalComputation<T> computation) : super(computation);

  @override
  T get value => computation();

  @override
  Eval<S> app<S>(Eval<Function1<T, S>> app) =>
      new Always(() => app.value(value));

  @override
  Eval<S> flatMap<S>(Function1<T, Eval<S>> f) =>
      new Always(() => f(value).value);

  @override
  Eval<S> map<S>(Function1<T, S> f) => new Always(() => f(value));
}

abstract class Eval<T> extends Monad<T> {
  factory Eval.defer(Eval e) => new Later(() => e.value);

  Eval._();

  T get value;

  @override
  Eval<S> app<S>(Eval<Function1<T, S>> app) =>
      new Later(() => app.value(value));

  @override
  Eval<S> flatMap<S>(Function1<T, Eval<S>> f) => new Eval.defer(f(value));

  @override
  Eval<S> map<S>(Function1<T, S> f) => new Later(() => f(value));
}

class Later<T> extends _WithComputation<T> {
  T _value;

  Later(EvalComputation<T> computation) : super(computation);

  @override
  T get value => _value ??= computation();
}

class Now<T> extends Eval<T> {
  @override
  final T value;

  Now(this.value) : super._();
}

abstract class _WithComputation<T> extends Eval<T> {
  @protected
  final EvalComputation<T> computation;

  _WithComputation(this.computation) : super._();
}
