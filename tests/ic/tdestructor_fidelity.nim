discard """
  description: '''IC vs `nim c`: destructor injection and move analysis must agree'''
"""

#? metamorphic

# Two whole classes of IC miscompilation are invisible to any IC-vs-IC check,
# because IC was *consistently* wrong: warm == cold == not what `nim c` does.
# The oracle is what catches them.
#
#  * `sfInjectDestructors` lives on the MODULE symbol, which the NIF loader
#    rebuilds from scratch — so `genTopLevelStmt` skipped the destructor pass
#    entirely and a module-level `block: let h = ...` never ran `=destroy`.
#  * `nfFirstWrite`/`nfLastRead` sit on `nkSym` nodes, which serialize as bare
#    NIF `SymUse` tokens with nowhere to put node flags — so the frontend's move
#    analysis never reached the backend and EVERY first assignment to a
#    destructor-bearing local became `=sink` over still-zeroed memory.

#!FILE res.nim
var log*: seq[string]

type R* = object
  tag*: string

proc `=destroy`*(r: R) = log.add "d(" & r.tag & ")"
proc `=copy`*(d: var R, s: R) = (log.add "c(" & s.tag & ")"; d.tag = s.tag)

proc mk*(t: string): R = R(tag: t)
proc mkVia*(t: string): R = (result = R(tag: t))
proc consume*(r: sink R): string = "u:" & r.tag

#!FILE main.nim
import res

# in a proc: worked before
proc inProc() =
  let a = mk("proc")
  discard a
inProc()

# module top level: the pass was skipped wholesale
block:
  let t = mk("toplevel")
  discard t

for i in 0 .. 1:
  let l = mk("loop" & $i)
  discard l

# every `result` shape: each must construct in place, not `=sink` over zeroes
block:
  let x = mk("direct")
  let y = mkVia("via")
  discard x
  discard y

# last read is a move, a re-read is a copy
proc moves(): string =
  var m = mk("moved")
  result = consume(m)
proc copies(): string =
  var k = mk("kept")
  result = consume(k) & "/" & k.tag
discard moves()
discard copies()

echo log
#!STEP expect: @["d(proc)", "d(toplevel)", "d(loop0)", "d(loop1)", "d(via)", "d(direct)", "d(moved)", "c(kept)", "d(kept)", "d(kept)"]
