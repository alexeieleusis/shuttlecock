import 'package:shuttlecock/src/util/lens_case.dart';
import 'package:test/test.dart';

void main() {
  group('guitarreando', () {
    test('oh si', () {
      // Use case example

      D initD = new D('1');
      B initB = new B('1');
      C initC = new C('1', initD);
      A initA = new A('1', initB, initC);

      B bFromA(A a) => a.b;
      C cFromA(A a) => a.c;
      D dFromC(C c) => c.d;

      A setB(B b, A a) => a.copy(b: b);
      A setC(C c, A a) => a.copy(c: c);
      C setD(D d, C c) => c.copy(d: d);

      final parentState = new LensCase.of(initA);
      parentState.stream.forEach(print);

      final stateB = parentState.getSight(bFromA, setB);
      final stateC = parentState.getSight(cFromA, setC);

      final stateD = stateC.getSight(dFromC, setD);
      stateD.stream.forEach((e) => print('stateD $e'));

      stateD.update(initD.copy(tag: '2'));
      stateD.evolve((d) => d.copy(tag: '3'));
    });
  });
}

class A {
  final String tag;

  final B b;

  final C c;

  A(this.tag, this.b, this.c);

  @override
  String toString() {
    return 'A{tag: $tag, b: $b, c: $c}';
  }

  A copy({String tag, B b, C c}) {
    print('A.copy tag $tag b $b c $c');
    return new A(tag ?? this.tag, b ?? this.b, c ?? this.c);
  }
}

class B {
  final String tag;

  B(this.tag);

  @override
  String toString() {
    return 'B{tag: $tag}';
  }

  B copy({String tag}) => new B(tag ?? this.tag);
}

class C {
  final String tag;

  final D d;

  C(this.tag, this.d);

  @override
  String toString() {
    return 'C{tag: $tag, d: $d}';
  }

  C copy({String tag, D d}) {
    print('C.copy tag $tag d $d');
    return new C(tag ?? this.tag, d ?? this.d);
  }
}

class D {
  final String tag;

  D(this.tag);

  @override
  String toString() {
    return 'D{tag: $tag}';
  }

  D copy({String tag}) {
    print('D.copy $tag');
    return new D(tag ?? this.tag);
  }
}
