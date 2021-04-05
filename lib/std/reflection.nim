##[
This module implements some reflection API's.
It is supported in c, cpp, js backends.

Experimental API, subject to change.
]##

runnableExamples:
  # `getOwnerName`
  proc fn1(a: int, b = 'x') =
    assert getOwnerName() == "fn1"
    static: assert getOwnerName(withType = true) == "fn1: proc (a: int; b: char)"
  fn1(1)

  iterator fn3[T](a: T): string =
    static: doAssert getOwnerName() == "fn3"
    yield getOwnerName(withType = true)

  from std/sequtils import toSeq
  assert toSeq(fn3(1.5)) == @["fn3: proc (a: float64): string"]

runnableExamples:
  # `getBackendProcName`
  from std/strutils import contains
  proc fn1 =
    assert "fn1" in getBackendProcName() # implementation defined, e.g. `fn1_reflection95examples49_1`
  fn1()

  proc fn2: auto {.exportc.} = getBackendProcName()
  assert fn2() == "fn2"

  iterator fn3[T](a: T): string {.closure.} =
    yield getBackendProcName()

  from std/sequtils import toSeq
  let s1 = toSeq(fn3(1.5))[0]
  let s2 = toSeq(fn3(1))[0]
  assert "fn3" in s1
  assert s2 != s1

import std/macros

template getBackendProcName*(): string =
  ## Returns the name of the function containing the caller scope after codegen.
  ## This is only valid inside a proc/func/method/closure iterator.
  ## See also `getOwnerName`.
  ##
  ## .. note:: not supported in VM.
  block:
    var name {.inject.}: cstring
    when defined(js):
      {.emit: "`name` = arguments.callee.name;".}
    else:
      # C cast needed for cpp.
      {.emit: "`name` = (char*)__func__;".}
    $name

macro getOwnerNameImpl(a: typed, withType: static bool): string =
  let n = a.owner
  var ret = n.repr
  case n.symKind
  of nskModule:
    discard
  elif withType:
    ret.add ": " 
    ret.add n.getTypeInst.repr
  newLit ret

template getOwnerName*(withType = false): string =
  ## Returns the name of proc/func/iterator/method/macro in which caller is running.
  ## When `withType = true`, the result contains an implementation defined
  ## representation of the type of the routine.
  ##
  ## .. note:: at the top-level, it returns the module name.
  ## .. note:: this cannot be used to retrieve the name of an enclosing template,
  ##   they are expanded early.
  block:
    template dummy(a: int) = discard
    const result = getOwnerNameImpl(dummy, withType)
    result
