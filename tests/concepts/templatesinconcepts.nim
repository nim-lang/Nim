import typetraits

template typeLen(x): int = x.type.name.len

template bunchOfChecks(x) =
  x.typeLen > 3
  x != 10 is bool

template stmtListExprTmpl(x: untyped): untyped =
  x is int
  x

type
  Obj = object
    x: int

  Gen[T] = object
    x: T

  Eq = concept x, y
    (x == y) is bool

  NotEq = concept x, y
    (x != y) is bool

  ConceptUsingTemplate1 = concept x
    echo x
    sizeof(x) is int
    bunchOfChecks x

  ConceptUsingTemplate2 = concept x
    stmtListExprTmpl x

template ok(x) =
  static: assert(x)

template no(x) =
  static: assert(not(x))

ok int is Eq
ok int is NotEq
ok string is Eq
ok string is NotEq
ok Obj is Eq
ok Obj is NotEq
ok Gen[string] is Eq
ok Gen[int] is NotEq

no int is ConceptUsingTemplate1
ok float is ConceptUsingTemplate1
no string is ConceptUsingTemplate1

ok int is ConceptUsingTemplate2
no float is ConceptUsingTemplate2
no string is ConceptUsingTemplate2

