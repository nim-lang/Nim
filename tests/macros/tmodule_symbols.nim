import macros
from algorithm import sorted

proc fun1*() = discard
proc fun2*() = discard
const s3* = 1
var s4* = 1

# private symbols won't be listed in moduleSymbols by default
var s5 = 1
proc fun6() = discard

proc moduleSymbolsTestImpl(mymod: NimNode, enablePrivate: bool): auto =
  let children = mymod.moduleSymbols(enablePrivate)
  result = newTree(nnkBracket)
  for ai in children:
    result.add newLit $ai

macro moduleSymbolsTest(mymod: typed, enablePrivate: static bool = false): untyped =
  result = moduleSymbolsTestImpl(mymod, enablePrivate)

when isMainModule:
  const symbols = moduleSymbolsTest(tmodule_symbols)
  let public = @["fun1", "fun2", "s3", "s4"]
  doAssert symbols.sorted == public

  const symbols2 = moduleSymbolsTest(tmodule_symbols, enablePrivate = true)
  doAssert "fun6" in symbols2
  for ai in public & @["fun6", "s5"]:
    doAssert ai in symbols2
