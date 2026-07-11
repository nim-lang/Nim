discard """
  output: "ok"
  targets: "c"
  matrix: "--experimental:abi"
  ccodecheck: "'N_LIB_EXPORT N_NIMCALL\\(NI, _ZN10texportabi6chooseE3int\\)'"
  ccodecheck: "'N_LIB_EXPORT N_NIMCALL\\(NI, _ZN10texportabi6chooseE6string\\)'"
  ccodecheck: "'N_LIB_EXPORT N_NIMCALL\\(NI, _ZN10texportabi3tagE3BoxI3intE\\)'"
  ccodecheck: "'N_LIB_EXPORT N_NIMCALL\\(NI, _ZN10texportabi3tagE3BoxI6stringE\\)'"
"""

import std/[compilesettings, os, strutils, syncio]
import mexportabi_support

type
  Box[T] = object
    value: T

proc choose(x: int): int {.exportabi.} =
  x

proc choose(x: string): int {.exportabi.} =
  x.len

proc tag[T](box: Box[T]): int {.exportabi.} =
  when T is int:
    box.value
  else:
    box.value.len

proc consumeImportedHook(value: CustomHooked) {.exportabi.} =
  discard value

discard tag(Box[int](value: 3))
discard tag(Box[string](value: "nim"))
doAssert exportedFromSupport(1) == 2
consumeImportedHook(CustomHooked(value: 1))
discard makeMoveOnly(2)

let manifestPath = querySetting(nimcacheDir) / "texportabi.abi.nif"
doAssert fileExists(manifestPath)

let manifest = readFile(manifestPath)
doAssert manifest.startsWith("(.nif27)")
doAssert manifest.contains("(.dialect \"nim-native-dynlib\")")
doAssert manifest.contains("(format 3)")
doAssert manifest.contains("(library \"")
doAssert manifest.contains("(modules\n  (module \"")
doAssert manifest.contains("\" \"texportabi\")")
doAssert manifest.contains("\" \"mexportabi_support\")")
doAssert manifest.count("(module \"") == 2
doAssert manifest.count("(hook \"") == 3
doAssert manifest.count(" custom \"") == 2
doAssert manifest.count(" forbidden .)") == 1
doAssert manifest.count("(proc \"") == 7
doAssert manifest.count(" true)") == 2
doAssert manifest.count(" false)") == 5
echo "ok"
