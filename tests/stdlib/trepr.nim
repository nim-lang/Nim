discard """
  targets: "c cpp js"
  matrix: ";--gc:arc"
"""

# if excessive, could remove 'cpp' from targets

from strutils import endsWith, contains, strip
from std/macros import newLit

macro deb(a): string = newLit a.repr.strip
macro debTyped(a: typed): string = newLit a.repr.strip

template main() =
  doAssert repr({3,5}) == "{3, 5}"

  block:
    type TEnum = enum a, b
    var val = {a, b}
    when nimvm:
      discard
      #[
      # BUG:
      {0, 1}
      {97..99, 65..67}
      ]#
    else:
      doAssert repr(val) == "{a, b}"
      doAssert repr({'a'..'c', 'A'..'C'}) == "{'A', 'B', 'C', 'a', 'b', 'c'}"

    type
      TObj {.pure, inheritable.} = object
        data: int
      TFoo = ref object of TObj
        d2: float
    var foo: TFoo
    new(foo)

  #[
  BUG:
  --gc:arc returns `"abc"`
  regular gc returns with address, e.g. 0x1068aae60"abc", but only 
  for c,cpp backends (not js, vm)
  ]#
  block:
    doAssert repr("abc").endsWith "\"abc\""
    var b: cstring = "def"
    doAssert repr(b).endsWith "\"def\""

  block:
    var c = @[1,2]
    when nimvm:
      discard # BUG: this shows [1, 2] instead of @[1, 2]
    else:
      # BUG (already mentioned above): some backends / gc show address, others don't
      doAssert repr(c).endsWith "@[1, 2]"

    let d = @["foo", "bar"]
    let s = repr(d)
    # depending on backend/gc, we get 0x106a1c350@[0x106a1c390"foo", 0x106a1c3c0"bar"]
    doAssert "\"foo\"," in s

  var arr = [1, 2, 3]
  doAssert repr(arr) == "[1, 2, 3]"

  block: # bug #7878
    proc reprOpenarray(variable: var openArray[int]): string = repr(variable)
    when defined(js): discard # BUG: doesn't work
    else:
      doAssert reprOpenarray(arr) == "[1, 2, 3]"

  block: # bug #17292 repr with `do`
    template foo(a, b, c, d) = discard
    block:
      let a = deb:
        foo(1, 2, 3, 4)
      doAssert a == "foo(1, 2, 3, 4)"
    block:
      let a = deb:
        foo(1, 2, 3): 4
      doAssert a == """
foo(1, 2, 3):
  4"""

    block:
      let a = deb:
        foo(1, 2): 3
        do: 4
      doAssert a == """
foo(1, 2):
  3
do:
  4"""

    block:
      let a = deb:
        foo(1): 3
        do: 3
        do: 4
      doAssert a == """
foo(1):
  3
do:
  3
do:
  4"""

    block:
      let a = deb:
        foo(1):
          3
        do:
          discard
          3
        do:
          discard
          4

      doAssert a == """
foo(1):
  3
do:
  discard
  3
do:
  discard
  4"""

    block:
      let a = deb:
        foo: 1
        do: 2
        do: 3
        do: 4
      doAssert a == """
foo:
  1
do:
  2
do:
  3
do:
  4"""

  block: # bug #17292 repr with `(discard)` (`discard` would result in illegal code)
    let a = deb:
      let f {.inject.} = () => (discard)
    doAssert a == """
let f {.inject.} = () =>
    (discard )"""

    let a2 = deb:
      block:
        discard
      discard

      block:
        when true: discard

      # let a = b => discard # illegal
      discard b => (discard) # legal

      block:
        return
    doAssert a2 == """
block:
  discard
discard
block:
  when true:
    discard
discard b =>
    (discard )
block:
  return"""

  block: # bug #17292 (bug 4)
    let a = deb:
      proc `=destroy`() = discard
      proc `'foo`(): int = discard
      proc `foo bar baz`(): int = discard
    let a2 = """
proc `=destroy`() =
  discard

proc `'foo`(): int =
  discard

proc `foo bar baz`(): int =
  discard"""
    doAssert a2 == a

  block: # setters: `foo=`
    let a = deb:
      proc `foo=`() = discard
    doAssert a == """
proc `foo=`() =
  discard"""

  block: # bug #14850
    block:
      let a = deb:
        template bar(): untyped =
          foo1:
            discard
            4
          foo2(1):
            discard
            4
          foo3(1):
            discard
            4
          do: 1
          do: 2
          x.add foo4
          x.add: foo5: 3
          x.add foo6 do: 4
          a.add(foo7 do:
            echo "baz"
            4)

      doAssert a == """
template bar(): untyped =
  foo1:
    discard
    4
  foo2(1):
    discard
    4
  foo3(1):
    discard
    4
  do:
    1
  do:
    2
  x.add foo4
  x.add:
    foo5:
      3
  x.add foo6 do:
    4
  a.add(foo7 do:
    echo "baz"
    4)"""

  block: # one liner doc comments
    let a1 = deb:
      func fn1(): int = 1  ## comment
      func fn2(): int = 1
        ## comment
    let a2 = debTyped:
      func fn1(): int = 1  ## comment
      func fn2(): int = 1
        ## comment
    doAssert a1 == """
func fn1(): int =
  ## comment
  1

func fn2(): int =
  ## comment
  1"""
    doAssert a2 == """
func fn1(): int =
  ## comment
  result = 1

func fn2(): int =
  ## comment
  result = 1"""

static: main()
main()
