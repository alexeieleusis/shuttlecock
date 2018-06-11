import 'package:shuttlecock/src/util/lens_case.dart';
import 'package:test/test.dart';

void main() {
  int counter;
  int getCounter() => counter++;

  group('LensCase', () {
    Iterable<B> bFromA(A a) => a.b;
    C cFromA(A a) => a.c;
    D dFromC(C c) => c.d;

    A setB(Iterable<B> b, A a) => a.copy(b: b);
    A setC(C c, A a) => a.copy(c: c);
    C setD(D d, C c) => c.copy(d: d);

    A initA;
    Iterable<B> initB;
    C initC;
    D initD;
    LensCase<A> parentState;
    LensCase<C> stateC;
    LensCase<D> stateD;

    setUp(() {
      counter = 0;
      initD = new D(getCounter());
      initB = new Iterable.generate(
              2 * getCounter(), (_) => new B(getCounter(), new D(getCounter())))
          .toList();
      initC = new C(getCounter(), initD);
      initA = new A(getCounter(), initB, initC);

      parentState = new LensCase.of(initA);
      stateC = parentState.getSight(cFromA, setC);
      stateD = stateC.getSight(dFromC, setD);
    });

    test('transformations', () async {
      final b1 = new B(2, new D(3));
      final b2 = new B(4, new D(5));
      final c1 = new C(6, new D(0));
      final a1 = new A(7, [b1, b2], c1);
      final c2 = c1.copy(d: c1.d.copy(tag: 8));
      final a2 = a1.copy(c: c2);
      final c3 = c2.copy(d: c2.d.copy(tag: 9));
      final a3 = a2.copy(c: c3);
      final c4 = c3.copy(d: c3.d.copy(tag: 10));
      final a4 = a3.copy(c: c4);

      final statesFuture = parentState.stream.take(4).toList();

      stateD
        ..update(initD.copy(tag: getCounter()))
        ..evolve((d) => d.copy(tag: getCounter()))
        ..evolve((d) => d.copy(tag: getCounter()));

      final states = await statesFuture;
      expect(states, [a1, a2, a3, a4]);
    });

    test('asynchronously', () async {
      final b1 = new B(2, new D(3));
      final b2 = new B(4, new D(5));
      final c1 = new C(6, new D(0));
      final a1 = new A(7, [b1, b2], c1);
      final a2 = a1.copy(b: [b1, b2.copy(tag: 8)]);

      final statesFuture = parentState.stream.take(2).toList();
      final bLenses = await parentState.getSightSequence(bFromA, setB).last;
      final lensCase = bLenses.last;
      lensCase.getSight((b) => b.tag, (newTag, b) => b.copy(tag: newTag))
        ..evolve((tag) => 2 * tag)
        ..evolve((tag) => 2 * tag);

      final states = await statesFuture;
      expect(states, [a1, a2]);

      // ignore: unawaited_futures
      parentState.stream.first.then((_) {
        fail('should not emit more events');
      });
    });
  });
}

class A {
  final int tag;

  final Iterable<B> b;

  final C c;

  A(this.tag, this.b, this.c);

  @override
  int get hashCode => tag.hashCode ^ b.hashCode ^ c.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! A) {
      return false;
    }
    final A a = other;
    if (tag != a.tag || c != a.c) {
      return false;
    }

    final thisBs = b.toList().asMap();
    final otherBs = a.b.toList().asMap();
    if (thisBs.length != otherBs.length) {
      return false;
    }

    return thisBs.keys.every((index) => thisBs[index] == otherBs[index]);
  }

  A copy({String tag, Iterable<B> b, C c}) =>
      new A(tag ?? this.tag, b ?? this.b, c ?? this.c);

  @override
  String toString() => 'A{tag: $tag, b: $b, c: $c}';
}

class B {
  final int tag;
  final D d;

  B(this.tag, this.d);

  @override
  int get hashCode => tag.hashCode ^ d.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is B && tag == other.tag && d == other.d;

  B copy({int tag, D d}) => new B(tag ?? this.tag, d ?? this.d);

  @override
  String toString() => 'B{tag: $tag, d: $d}\n';
}

class C {
  final int tag;

  final D d;

  C(this.tag, this.d);

  @override
  int get hashCode => tag.hashCode ^ d.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is C && tag == other.tag && d == other.d;

  C copy({String tag, D d}) => new C(tag ?? this.tag, d ?? this.d);

  @override
  String toString() => 'C{tag: $tag, d: $d}\n';
}

class D {
  final int tag;

  D(this.tag);

  @override
  int get hashCode => tag.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is D && tag == other.tag;

  D copy({int tag}) => new D(tag ?? this.tag);

  @override
  String toString() => 'D{tag: $tag}';
}
