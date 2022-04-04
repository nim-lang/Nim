import std/macros
import stdtest/testutils

macro test1(prc: untyped): untyped =
  assertAll:
    prc.params.len == 2
    prc.params[1].len == 4
    prc.pragma.len == 2

  prc.params = nnkFormalParams.newTree(
    ident("int")
  )
  prc.pragma = newEmptyNode()

  assertAll:
    prc.params.len == 1
    prc.pragma.len == 0
  prc

proc test(a, b: int): int {.gcsafe, raises: [], test1.} = 5

type hello = proc(a, b: int): int {.gcsafe, raises: [], test1.}
