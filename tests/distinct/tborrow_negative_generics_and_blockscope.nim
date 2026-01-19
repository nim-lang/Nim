##[
This testcase checks several things:

1. It checks the negative case that a distinct type that does not borrow the
  `[]` operator does not have access to it.
2. It checks that multiple distinct types can be declared from the same parent
   type and can borrow the same function from the parent.
3. It checks that you can borrow from a generic parent type and borrow generic
   functions from that parent type.
4. It checks that bracket operators can be borrowed when in block scope.
]##


# See 1.
type A0 = distinct array[3, int]
type A1 = distinct array[3, int]
type A0GetOnly[T] = distinct array[3, T]

proc `[]`*(a: A0, i: int): int {.borrow.}
proc `[]`*(a: var A0, i: int): var int {.borrow.}
proc `[]=`*(a: var A0, i: int, val: int) {.borrow.}
proc `[]`*[T](a: A0GetOnly[T], i: int): T {.borrow.}

var a0: A0
doAssert compiles(a0[0] == 0)

var a1: A1
doAssert not compiles(a1[0] == 0)

# Only borrowed the non-var `[]` should not allow mutation.
block:
  var a0GetOnly: A0GetOnly[int]
  doAssert compiles(a0GetOnly[0] == 0)
  doAssert not compiles(a0GetOnly[0] = 10)

# See 2. and 3.
type A2[T] = distinct array[3, T]
type A3[T] = distinct array[3, T]

proc `[]`*[T](a: A2[T], i: int): T {.borrow.}
proc `[]`*[T](a: var A2[T], i: int): var T {.borrow.}
proc `[]=`*[T](a: var A2[T], i: int, val: T) {.borrow.}

var a2: A2[int]
doAssert compiles(a2[0] == 0)

var a3: A3[int]
doAssert not compiles(a3[0] == 0)

# See 4.
block BLOCK_TEST:
  type A4[T] = distinct array[3, T]
  type A5[T] = distinct array[3, T]

  proc `[]`[T](a: A4[T], i: int): T {.borrow.}
  proc `[]`[T](a: var A4[T], i: int): var T {.borrow.}
  proc `[]=`[T](a: var A4[T], i: int, val: T) {.borrow.}

  var a4: A4[float]
  doAssert compiles(a4[0] == 0)

  var a5: A5[float]
  doAssert not compiles(a5[0] == 0)
