##[
internal API for now, subject to change
]##

#[
see also:
$nim/testament/lib/stdtest/unittest_light.nim
]#

import macros
import std/strutils

proc isPureLit*(a: NimNode): bool =
  if a.len > 0:
    for ai in a:
      if not isPureLit(ai): return false
    return true
  else:
    case a.kind
    of nnkLiterals:
      return true
    else: return false

macro conditionToStr*(cond: untyped, msg = ""): string =
  result = newStmtList()
  let cond2 = cond.repr
  let ret = genSym(nskVar, "ret")
  result.add quote do:
    # `ret`.add "expected: '$1'" % [`cond2`]
    var `ret`: string
    `ret`.add "expected: "
  case cond.kind
  of nnkInfix:
    let infix = cond[0].repr
    let lhs = cond[1]
    let lhsLit = lhs.repr
    let rhs = cond[2]
    result.add quote do:
      `ret`.add "'$#' ($#) $# $#" % [`lhsLit`, $`lhs`, `infix`,  $`rhs`]
    # let lhsInfo = lhs.info
    # let lhsInfo = lhs.lineInfo
    
    # if not lhs.isPureLit:
    #   result.add quote do:
    #     # `ret`.add " lhs: '$1' defined at $2" % [$`lhs`, ]
    #     `ret`.add " lhs: '$1'" % [$`lhs`, ]
    # if not rhs.isPureLit:
    #   result.add quote do:
    #     `ret`.add " rhs: '$1' " % [$`rhs`]
  else:
    # eg: nnkDotExpr for foo.bar.isAbsolute
    let cond2 = cond.repr
    # we could also provide context info here, eg for `nnkDotExpr`, check
    # whether `lhs` is printable
    result.add quote do:
      `ret`.add `cond2`

  echo msg.kind
  if msg.kind in nnkStrLit..nnkTripleStrLit:
    let msg2 = msg.strVal
    if msg2.len > 0:
      result.add quote do:
        `ret`.add "; " & `msg2`
  else:
    let msg2 = msg.repr
    result.add quote do:
      `ret`.add "; " & `msg2` & ": " & `msg`
  result.add quote do:
    `ret`

when isMainModule:
  template chk(cond: untyped, msg = "") =
    if not cond:
      let ret = conditionToStr(cond, msg)
      # doAssert false, ret
      echo ret

  proc main() =
    block:
      var i=1
      chk 1+i == 3
    block:
      var c = "foo"
      var c2 = "foo3"
      chk c in ["foo1", "foo2", c2]
      chk c != "foo"
      chk c == "bar"
      chk c == "bar", "gook1"
      var msg = "gook2"
      chk c == "bar", msg
      var x = [12,13]
      chk c == "bar", $x
  main()
