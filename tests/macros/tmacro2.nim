discard """
  output: "ta-da Your value sir: 'HE!!!!o Wor!!d'"
"""

import macros, strutils

proc testBlock(): string {.compileTime.} =
  block myBlock:
    while true:
      echo "inner block"
      break myBlock
    echo "outer block"
  result = "ta-da"

macro mac(n: typed): string =
  let n = callsite()
  expectKind(n, nnkCall)
  expectLen(n, 2)
  expectKind(n[1], nnkStrLit)
  var s: string = n[1].strVal
  s = s.replace("l", "!!")
  result = newStrLitNode("Your value sir: '$#'" % [s])

const s = testBlock()
const t = mac("HEllo World")
echo s, " ", t


#-----------------------------------------------------------------------------
# issue #15326
macro m(n:typed):auto =
  result = n

proc f[T](x:T): T {.m.} = x

discard f(3)