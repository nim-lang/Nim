import std/[macros, reflection]
from std/algorithm import sorted

proc fn1*() = discard
proc fn2*() = discard
const s3* = 1
var s4* = 1

# private symbols won't be listed in moduleSymbols by default
var s5 = 1
proc fn6() = discard

template main =
  proc moduleSymbolsTestImpl(mymod: NimNode, enablePrivate: bool): auto =
    let children = mymod.moduleSymbols(enablePrivate)
    result = newTree(nnkBracket)
    for ai in children:
      result.add newLit $ai

  macro moduleSymbolsTest(mymod: typed, enablePrivate: static bool = false): untyped =
    result = moduleSymbolsTestImpl(mymod, enablePrivate)

  const symbols = moduleSymbolsTest(treflection)
  let public = @["fn1", "fn2", "s3", "s4"]
  doAssert symbols.sorted == public

  const symbols2 = moduleSymbolsTest(treflection, enablePrivate = true)
  for ai in public & @["fn6", "s5"]:
    doAssert ai in symbols2

static: main()
main()
