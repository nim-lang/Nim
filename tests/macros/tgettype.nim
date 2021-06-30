import std/macros
import stdtest/testutils

# getType

block:
  type
    Model = object of RootObj
    User = object of Model
      name : string
      password : string

  macro testUser: string =
    result = newLit(User.getType.lispRepr)

  macro testGeneric(T: typedesc[Model]): string=
    result = newLit(T.getType.lispRepr)

  doAssert testUser == """(ObjectTy (Empty) (Sym "Model") (RecList (Sym "name") (Sym "password")))"""
  doAssert User.testGeneric == """(BracketExpr (Sym "typeDesc") (Sym "User"))"""

  macro assertVoid(e: typed): untyped =
    assert(getTypeInst(e).typeKind == ntyVoid)

  proc voidProc() = discard

  assertVoid voidProc()

block:
  # refs #18220; not an actual solution (yet) but at least shows what's currently
  # possible

  type Callable1[R, T, U] = concept fn
    fn(default(T)) is R
    fn is U

  # note that typetraits.arity doesn't work
  macro arity(a: typed): int =
    # number of params
    # this is not production code!
    let a2 = a.getType[1] # this used to crash nim, with: `vmdeps.nim(292, 25) `false``
    newLit a2.len - 1

  type Callable2[R, T, U] = concept fn
    fn(default(T)) is R
    fn is U
    arity(U) == 2

  proc map1[T, R, U](a: T, fn: Callable1[R, T, U]): R =
    let fn = U(fn)
      # `cast[U](fn)` would also work;
      # this is currently needed otherwise, sigmatch errors with:
      # Error: attempting to call routine: 'fn'
      #  found 'fn' [param declared in tgettype.nim(53, 28)]
      # this can be fixed in future work
    fn(a)

  proc map2[T, R, U](a: T, fn: Callable2[R, T, U]): R =
    let fn = U(fn)
    fn(a)

  proc fn1(a: int, a2 = 'x'): string = $(a, a2, "fn1")
  proc fn2(a: int, a2 = "zoo"): string = $(a, a2, "fn2")
  proc fn3(a: int, a2 = "zoo2"): string = $(a, a2, "fn3")
  proc fn4(a: int): string {.inline.} = $(a, "fn4")
  proc fn5(a: int): string = $(a, "fn5")

  assertAll:
    # Callable1
    1.map1(fn1) == """(1, 'x', "fn1")"""
    1.map1(fn2) == """(1, "zoo", "fn2")"""
    1.map1(fn3) == """(1, "zoo", "fn3")"""
      # fn3's optional param is not honored, because fn3 and fn2 yield same
      # generic instantiation; this is a caveat with this approach
      # There are several possible ways to improve things in future work.
    1.map1(fn4) == """(1, "fn4")"""
    1.map1(fn5) == """(1, "fn5")"""

    # Callable2; prevents passing procs with optional params to avoid above
    # mentioned caveat, but more restrictive
    not compiles(1.map2(fn1))
    not compiles(1.map2(fn2))
    not compiles(1.map2(fn3))
    1.map2(fn4) == """(1, "fn4")"""
    1.map2(fn5) == """(1, "fn5")"""
