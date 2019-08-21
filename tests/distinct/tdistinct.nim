discard """
  output: '''
tdistinct
25
false
false
false
false
Foo
'''
"""

echo "tdistinct"

block tborrowdot:
  type
    Foo = object
      a, b: int
      s: string

    Bar {.borrow: `.`.} = distinct Foo

  var bb: ref Bar
  new bb
  bb.a = 90
  bb.s = "abc"

block tcurrncy:
  template Additive(typ: untyped) =
    proc `+`(x, y: typ): typ {.borrow.}
    proc `-`(x, y: typ): typ {.borrow.}

    # unary operators:
    proc `+`(x: typ): typ {.borrow.}
    proc `-`(x: typ): typ {.borrow.}

  template Multiplicative(typ, base: untyped) =
    proc `*`(x: typ, y: base): typ {.borrow.}
    proc `*`(x: base, y: typ): typ {.borrow.}
    proc `div`(x: typ, y: base): typ {.borrow.}
    proc `mod`(x: typ, y: base): typ {.borrow.}

  template Comparable(typ: untyped) =
    proc `<`(x, y: typ): bool {.borrow.}
    proc `<=`(x, y: typ): bool {.borrow.}
    proc `==`(x, y: typ): bool {.borrow.}

  template DefineCurrency(typ, base: untyped) =
    type
      typ = distinct base
    Additive(typ)
    Multiplicative(typ, base)
    Comparable(typ)

    proc `$`(t: typ): string {.borrow.}

  DefineCurrency(TDollar, int)
  DefineCurrency(TEuro, int)
  echo($( 12.TDollar + 13.TDollar )) #OUT 25

block tconsts:
  # bug #2641

  type MyChar = distinct char
  const c:MyChar = MyChar('a')

  type MyBool = distinct bool
  const b:MyBool = MyBool(true)

  type MyBoolSet = distinct set[bool]
  const bs:MyBoolSet = MyBoolSet({true})

  type MyCharSet= distinct set[char]
  const cs:MyCharSet = MyCharSet({'a'})

  type MyBoolSeq = distinct seq[bool]
  const bseq:MyBoolSeq = MyBoolSeq(@[true, false])

  type MyBoolArr = distinct array[3, bool]
  const barr:MyBoolArr = MyBoolArr([true, false, true])

# bug #2760

type
  DistTup = distinct tuple
    foo, bar: string

const d: DistTup = DistTup((
  foo:"FOO", bar:"BAR"
))


# bug #7167

type Id = distinct range[0..3]

proc `<=`(a, b: Id): bool {.borrow.}

var xs: array[Id, bool]

for x in xs: echo x # type mismatch: got (T) but expected 'bool'

# bug #11715

type FooD = distinct int
proc `<=`(a, b: FooD): bool {.borrow.}

for f in [FooD(0): "Foo"]: echo f
