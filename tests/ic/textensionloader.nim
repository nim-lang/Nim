discard """
  description: "Deferred dynlib loaders from multiple IC modules share one entry point"
"""

#? metamorphic

#!FILE mextensionloader.nim
var loads*: int

proc implementation(): cint {.cdecl.} =
  42

proc otherImplementation(): cint {.cdecl.} =
  73

proc resolve*(name: cstring): pointer =
  if $name == "unavailable":
    quit("loaded an unused extension", 1)
  inc loads
  if $name == "other":
    cast[pointer](otherImplementation)
  else:
    cast[pointer](implementation)

proc imported*(): cint {.importc, dynlib: resolve("0").}
proc other*(): cint {.importc, dynlib: resolve("9").}
proc unavailable(): cint {.importc, dynlib: resolve("0").}

proc unusedWrapper*(): cint =
  unavailable()

proc callImported*(): cint =
  imported()

proc callOther*(): cint =
  other()

#!FILE mextensioncaller.nim
import mextensionloader

proc callFromAnotherModule*(): cint =
  imported()

#!FILE main.nim
import mextensionloader, mextensioncaller

proc load0() {.importc: "nimLoadProcs0".}
proc load9() {.importc: "nimLoadProcs9".}

doAssert loads == 0
load0()
let firstLoads = loads
doAssert firstLoads == 1
doAssert callImported() == 42
doAssert callFromAnotherModule() == 42
doAssert imported() == 42
doAssert loads == firstLoads
load9()
doAssert loads == 2
doAssert callOther() == 73
doAssert other() == 73
let allLoads = loads
load0()
doAssert loads == allLoads + firstLoads
echo "loaded"
#!STEP expect: loaded

# Reuse every module's loader metadata on an unchanged build.
#!STEP expect: loaded

# Regenerate one fragment while retaining the other modules from the cache.
#!FILE mextensioncaller.nim
import mextensionloader

proc callFromAnotherModule*(): cint =
  imported() + 0

#!STEP expect: loaded

# Removing the caller's fragment must remove it from the shared entry point.
#!FILE mextensioncaller.nim
proc callFromAnotherModule*(): cint =
  42

#!STEP expect: loaded

# Main need not have a fragment of its own to provide the shared entry points.
#!FILE main.nim
import mextensionloader, mextensioncaller

proc load0() {.importc: "nimLoadProcs0".}
proc load9() {.importc: "nimLoadProcs9".}

doAssert loads == 0
load0()
load9()
doAssert callImported() == 42
doAssert callOther() == 73
doAssert callFromAnotherModule() == 42
echo "loaded"
#!STEP expect: loaded
