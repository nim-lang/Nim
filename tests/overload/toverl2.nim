discard """
  file: "toverl2.nim"
  output: "true012innertrue"
"""
# Test new overloading resolution rules

import strutils

proc toverl2(x: int): string = return $x
proc toverl2(x: bool): string = return $x

iterator toverl2(x: int): int =
  var res = 0
  while res < x:
    yield res
    inc(res)

var
  pp: proc (x: bool): string {.nimcall.} = toverl2

stdout.write(pp(true))

for x in toverl2(3):
  stdout.write(toverl2(x))

block:
  proc toverl2(x: int): string = return "inner"
  stdout.write(toverl2(5))
  stdout.write(true)

stdout.write("\n")
#OUT true012innertrue

