import macros
from algorithm import sorted

proc fun1*() = discard
proc fun2*() = discard
const s3* = 1
var s4* = 1

# private symbols won't be listed in moduleSymbols
var s5 = 1

proc moduleSymbolsTestImpl(mymod: NimNode): auto =
  let children = mymod.moduleSymbols
  result = newTree(nnkBracket)
  for ai in children:
    result.add newLit $ai

macro moduleSymbolsTest(mymod: typed): untyped =
  result = moduleSymbolsTestImpl(mymod)

when isMainModule:
  const symbols = moduleSymbolsTest(tmodule_symbols)
  doAssert symbols.sorted == @["fun1", "fun2", "s3", "s4", "tmodule_symbols"]
