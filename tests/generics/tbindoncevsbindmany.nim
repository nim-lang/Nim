template accept(x) =
  static: assert(compiles(x))

template reject(x) =
  static: assert(not compiles(x))

type
  ObjectWithNumber = concept obj
    obj.number is int

  Foo[T] = object
    x: T

type A = object
  anumber: int

type B = object
  bnumber: int

proc number(a: A): int = a.anumber
proc number(b: B): int = b.bnumber

proc notDistincConcept1(a: ObjectWithNumber, b: ObjectWithNumber) = discard
proc notDistincConcept2(a, b: ObjectWithNumber) = discard
proc distinctConcept1(a, b: distinct ObjectWithNumber) = discard
proc distinctConcept2(a: ObjectWithNumber, b: distinct ObjectWithNumber) = discard
proc distinctConcept3(a: distinct ObjectWithNumber, b: ObjectWithNumber) = discard
proc distinctConcept4(a: distinct ObjectWithNumber, b: distinct ObjectWithNumber) = discard

var a = A(anumber: 5)
var b = B(bnumber: 6)

accept notDistincConcept1(a, a)
accept notDistincConcept1(b, b)
reject notDistincConcept2(a, b)

accept notDistincConcept2(a, a)
accept notDistincConcept2(b, b)
reject notDistincConcept2(a, b)

accept distinctConcept1(a, b)
accept distinctConcept2(a, b)
accept distinctConcept3(a, b)
accept distinctConcept4(a, b)

proc nonDistincGeneric1(a: Foo, b: Foo) = discard
proc nonDistincGeneric2(a, b: Foo) = discard
proc distinctGeneric1(a, b: distinct Foo) = discard
proc distinctGeneric2(a: distinct Foo, b: Foo) = discard
proc distinctGeneric3(a: Foo, b: distinct Foo) = discard
proc distinctGeneric4(a: distinct Foo, b: distinct Foo) = discard

var f1 = Foo[int](x: 10)
var f2 = Foo[string](x: "x")

accept nonDistincGeneric1(f1, f1)
accept nonDistincGeneric1(f2, f2)
reject nonDistincGeneric1(f1, f2)

accept nonDistincGeneric2(f1, f1)
accept nonDistincGeneric2(f2, f2)
reject nonDistincGeneric2(f1, f2)

accept distinctGeneric1(f1, f1)
accept distinctGeneric2(f1, f1)
accept distinctGeneric3(f1, f1)
accept distinctGeneric4(f1, f1)

