discard """
  targets: "c js"
  output: '''
tdistinct
25
false
false
false
false
Foo
foo
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

block tRequiresInit:
  template accept(x) =
    static: doAssert compiles(x)

  template reject(x) =
    static: doAssert not compiles(x)

  type
    Foo = object
      x: string

    DistinctFoo {.requiresInit, borrow: `.`.} = distinct Foo
    DistinctString {.requiresInit.} = distinct string

  reject:
    var foo: DistinctFoo
    foo.x = "test"
    doAssert foo.x == "test"

  accept:
    let foo = DistinctFoo(Foo(x: "test"))
    doAssert foo.x == "test"

  reject:
    var s: DistinctString
    s = "test"
    doAssert string(s) == "test"

  accept:
    let s = DistinctString("test")
    doAssert string(s) == "test"

block: #17322
  type
    A[T] = distinct string

  proc foo(a: var A) =
    a.string.add "foo"

  type
    B = distinct A[int]

  var b: B
  foo(A[int](b))
  echo A[int](b).string
  b.string.add "bar"
  assert b.string == "foobar"

type Foo = distinct string

proc main() = # proc instead of template because of MCS/UFCS.
  # xxx put everything here to test under RT + VM
  block: # bug #12282
    block:
      proc test() =
        var s: Foo
        s.string.add('c')
        doAssert s.string == "c" # was failing
      test()

    block:
      proc add(a: var Foo, b: char) {.borrow.}
      proc test() =
        var s: Foo
        s.add('c')
        doAssert s.string == "c" # was ok
      test()

    block:
      proc add(a: var Foo, b: char) {.borrow.}
      proc test() =
        var s: string
        s.Foo.add('c')
        doAssert s.string == "c" # was failing
      test()
    block: #18061
      type
        A = distinct (0..100)
        B = A(0) .. A(10)
      proc test(b: B) = discard
      let
        a = A(10)
        b = B(a)
      test(b)

      proc test(a: A) = discard
      discard cast[B](A(1))
      var c: B


  block: # bug #9423
    block:
      type Foo = seq[int]
      type Foo2 = distinct Foo
      template fn() =
        var a = Foo2(@[1])
        a.Foo.add 2
        doAssert a.Foo == @[1, 2]
      fn()

    block:
      type Stack[T] = distinct seq[T]
      proc newStack[T](): Stack[T] =
        Stack[T](newSeq[T]())
      proc push[T](stack: var Stack[T], elem: T) =
        seq[T](stack).add(elem)
      proc len[T](stack: Stack[T]): int =
        seq[T](stack).len
      proc fn() = 
        var stack = newStack[int]()
        stack.push(5)
        doAssert stack.len == 1
      fn()

static: main()
main()
