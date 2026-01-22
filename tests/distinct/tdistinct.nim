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

# Section: Borrowed field access for distinct object types.
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

# Section: Currency-style distinct types borrowing arithmetic and comparisons.
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

# Section: Distinct constants should preserve underlying literal values (bug #2641).
block tconsts:

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

# Section: Distinct tuple constants preserve field names (bug #2760).

type
  DistTup = distinct tuple
    foo, bar: string

const d: DistTup = DistTup((
  foo:"FOO", bar:"BAR"
))


# Section: Distinct range indexes can borrow comparisons for array iteration (bug #7167).

type Id = distinct range[0..3]

proc `<=`(a, b: Id): bool {.borrow.}

var xs: array[Id, bool]

for x in xs: echo x # type mismatch: got (T) but expected 'bool'

# Section: Distinct int with borrowed comparisons should support range literals (bug #11715).

type FooD = distinct int
proc `<=`(a, b: FooD): bool {.borrow.}

for f in [FooD(0): "Foo"]: echo f

# Section: `requiresInit` works correctly with distinct/borrowed types.
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

# Section: Borrowed access on distinct generic aliases mutates underlying string data (#17322).
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
  # Section: Run-time/VM regression coverage for borrowed string mutations (bug #12282).
  block: # bug #12282
    block:
      # Case: Direct string mutation through distinct alias.
      proc test() =
        var s: Foo
        s.string.add('c')
        doAssert s.string == "c" # was failing
      test()

    block:
      # Case: Borrowed proc on distinct type with string mutation.
      proc add(a: var Foo, b: char) {.borrow.}
      proc test() =
        var s: Foo
        s.add('c')
        doAssert s.string == "c" # was ok
      test()

    block:
      # Case: Borrowed proc invoked via UFCS on base string.
      proc add(a: var Foo, b: char) {.borrow.}
      proc test() =
        var s: string
        s.Foo.add('c')
        doAssert s.string == "c" # was failing
      test()
    # Section: Distinct range subtypes should accept casts and range bounds (#18061).
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


  # Section: Borrowed seq operations remain functional for distinct stacks (bug #9423).
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
