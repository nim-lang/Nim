# Shapes the predicate grinder needs, in an IMPORTED module with STATEMENT-LIST
# bodies.
#
# Two constraints, both structural, both learned by measuring rather than
# guessing:
#
# 1. The main module's routines are built in-process and never arrive as a
#    deferred body, so nothing written in `grindme.nim` is graded at all.
#
# 2. `ast2nif` defers only bodies whose root is an `nkStmtList` (see the comment
#    at the placeholder site: 82.5% of bodies, with one-line `nkAsgn` bodies the
#    bulk of the rest). A `proc f(x: int): int = case x ...` has an `nkAsgn`
#    body and is loaded eagerly, so it is invisible to the grinder. Every proc
#    here therefore opens with a statement.

import std/strutils

proc risky*(x: int): int =
  if x < 0: raise newException(ValueError, "neg")
  result = x * 2

proc classifyChar*(c: char): string =
  ## `branchHasTooBigRange`, false side: char ranges are all under the limit.
  var r = ""
  case c
  of 'a'..'z': r = "lower"
  of 'A'..'Z': r = "upper"
  of '0'..'9', '_': r = "wordish"
  else: r = "other"
  result = r

proc bigRange*(x: int): int =
  ## `branchHasTooBigRange`, TRUE side: 100000 > RangeExpandLimit (256).
  var r = 0
  case x
  of 0..100000: r = 1
  of 100001..200000: r = 2
  else: r = 3
  result = r

proc smallRange*(x: int): int =
  var r = 0
  case x
  of 0..10: r = 1
  of 11..20: r = 2
  else: r = 3
  result = r

proc inSets*(c: char): bool =
  ## `fewCmps` true side: a narrow set of an int-based element type.
  discard
  result = c in {'a', 'e', 'i', 'o', 'u'} and c notin {'x'..'z'}

proc bigSet*(c: char): bool =
  ## `fewCmps` false side: wide enough that emitting the set wins.
  discard
  result = c in {'a'..'z', 'A'..'Z', '0'..'9', '_', '-', '.', '+', '/', '=', '%'}

proc sumOpen*(xs: openArray[int]): int =
  ## `reifiedOpenArray`: an openarray PARAM is the one shape answering false.
  result = 0
  for x in xs: result += x

proc viaOpen*(xs: seq[int]): int =
  result = 0
  result += sumOpen(xs)
  result += sumOpen([1, 2, 3])
  result += sumOpen(xs.toOpenArray(0, 0))

proc adder*(n: int): proc (x: int): int =
  ## A real closure — `isConstClosure` false side.
  discard
  result = proc (x: int): int = x + n

proc constClosure*(): proc (x: int): int =
  ## `isConstClosure` TRUE side: a top-level routine as a closure value pairs
  ## the sym with a nil environment.
  discard
  result = risky

proc tuples*(): (int, string) =
  discard
  result = (risky(2), classifyChar('q'))

proc noInitVar*(): int =
  ## `hasNoInit`: a call to a `.noinit.` routine.
  var t {.noinit.}: array[4, int]
  t[0] = 1
  result = t[0]

proc guardedLib*(x: int): string =
  ## `bodyCanRaise` through both a raising call and its arguments.
  try:
    result = $risky(x) & $risky(x + 1)
  except ValueError:
    result = "err"
  finally:
    discard

proc scanEnd*(x: int): int =
  ## `stmtsContainPragma(wLinearScanEnd)` and, through it, a NON-ZERO
  ## `ifSwitchSplitPoint`. Without this both answer the same thing at every node
  ## in the closure — the stdlib uses neither pragma — and the grinder grades
  ## two constants.
  var r = 0
  case x
  of 0:
    r = 1
  of 1:
    {.linearScanEnd.}
    r = 2
  of 2: r = 3
  else: r = 4
  result = r

type Op* = enum opAdd, opAdd2, opSub, opEnd

proc computedGotoLoop*(inp: openArray[Op]): int =
  ## `stmtsContainPragma(wComputedGoto)`, the other word the equivalence check
  ## against `getPragmaStmt` looks for. The operand is an ENUM because
  ## `computedGoto` requires an exhaustive case and rejects an `else`, and it
  ## jumps straight from the end of one branch to the next dispatch — the
  ## `while` condition is NOT re-evaluated, so termination has to come from an
  ## explicit op.
  var r = 0
  var i = 0
  while true:
    {.computedGoto.}
    let op = inp[i]
    case op
    of opAdd: r += 1
    of opAdd2: r += 2
    of opSub: r -= 1
    of opEnd: break
    inc i
  result = r
