discard """
  cmd: "nim check --hints:off $options $file"
  action: "reject"
  nimout:'''
tunexpanded_macros.nim(19, 16) Error: type mismatch: got <int64> but expected 'float'
tunexpanded_macros.nim(22, 40) Error: expression 'await doOtherThing()' has no type (or is ambiguous)
tunexpanded_macros.nim(29, 23) Error: type mismatch: got <string> but expected 'float'
tunexpanded_macros.nim(32, 29) Error: type mismatch: got <int> but expected 'string'
tunexpanded_macros.nim(37, 22) Error: type mismatch: got <proc (): Future[system.void]{.gcsafe, locks: <unknown>.}> but expected 'proc (){.closure.}'
'''
"""
## For ensuring templates/macros show unexpanded messages where it makes sense

template doThing(a: int): untyped =
  case a:
  of 100: 300i64
  of 200: 400i64
  else: a
var a: float = doThing(300)
import std/asyncdispatch
proc doOtherThing {.async.} = discard
proc doThing {.async.} = discard await doOtherThing()

import std/macros

macro doStuff(a: untyped): untyped = a
macro doOtherStuff(a: typedesc): untyped = newCall("default" , a)

var b: float = doStuff("hello")
discard doStuff("world")

var c: string = doOtherStuff(int)


proc someAsync: Future[void] {.async.} = discard

var myProc: proc() = someAsync # Ensures we dont get a confusing `'async(proc())' expected`

