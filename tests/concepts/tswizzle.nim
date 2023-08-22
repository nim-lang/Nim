discard """
  output: '''3
[1, 3]
[2, 1, 2]
'''
  disabled: "true"
"""

import macros, strutils

template accept(e: expr) =
  static: assert(compiles(e))

template reject(e: expr) =
  static: assert(not compiles(e))

proc swizzleIdx(c: char): int =
  return case c
    of 'x': 0
    of 'y': 1
    of 'z': 2
    of 'w': 3
    of 'r': 0
    of 'g': 1
    of 'b': 2
    of 'a': 3
    else: 0

proc isSwizzle(s: string): bool {.compileTime.} =
  template trySet(name, set) =
    block search:
      for c in s:
        if c notin set:
          break search
      return true

  trySet coords, {'x', 'y', 'z', 'w'}
  trySet colors, {'r', 'g', 'b', 'a'}

  return false

type
  StringIsSwizzle = concept value
    value.isSwizzle

  SwizzleStr = static[string] and StringIsSwizzle

proc foo(x: SwizzleStr) =
  echo "sw"

#foo("xx")
reject foo("xe")

type
  Vec[N: static[int]; T] = array[N, T]

when false:
  proc card(x: Vec): int = x.N
  proc `$`(x: Vec): string = x.repr.strip

  macro `.`(x: Vec, swizzle: SwizzleStr): expr =
    var
      cardinality = swizzle.len
      values = newNimNode(nnkBracket)
      v = genSym()

    for c in swizzle:
      values.add newNimNode(nnkBracketExpr).add(
        v, c.swizzleIdx.newIntLitNode)

    return quote do:
      let `v` = `x`
      Vec[`cardinality`, `v`.T](`values`)

var z = Vec([1, 2, 3])

#echo z.card
#echo z.xz
#echo z.yxy

