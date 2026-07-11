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

  Variant* = object
    padding*: array[4, int]
    case textMode*: bool
    of false:
      number*: int
    of true:
      text*: string

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

proc makeVariant(text: string): Variant {.exportabi.} =
  Variant(textMode: true, text: text)

proc variantLength(value: Variant): int {.exportabi.} =
  if value.textMode: value.text.len
  else: value.number

discard tag(Box[int](value: 3))
discard tag(Box[string](value: "nim"))
doAssert exportedFromSupport(1) == 2
consumeImportedHook(CustomHooked(value: 1))
discard makeMoveOnly(2)
doAssert variantLength(makeVariant("layout")) == 6

let manifestPath = querySetting(nimcacheDir) / "texportabi.abi.nif"
doAssert fileExists(manifestPath)

let manifest = readFile(manifestPath)
doAssert manifest.startsWith("(.nif27)")
doAssert manifest.contains("(.dialect \"nim-native-dynlib\")")
doAssert manifest.contains("(format 4)")
doAssert manifest.contains("(abiid \"")
doAssert manifest.contains("(runtime ")
doAssert manifest.contains("(library \"")
doAssert manifest.contains("(modules\n  (module \"")
doAssert manifest.contains("\" \"texportabi\")")
doAssert manifest.contains("\" \"mexportabi_support\")")
doAssert manifest.contains("\" \"system\")")
doAssert manifest.count("(module \"") == 3
doAssert manifest.contains("(types\n  (type \"")
doAssert manifest.contains(" discriminant)")
doAssert manifest.contains("(branch 0 of")
doAssert manifest.count("(hook \"") == 3
doAssert manifest.count(" custom \"") == 2
doAssert manifest.count(" forbidden .)") == 1
doAssert manifest.count("(proc \"") == 9
doAssert manifest.count("(lowering") == 9
doAssert manifest.contains(" indirect)")
doAssert manifest.count(" true\n   (lowering") == 2
doAssert manifest.count(" false\n   (lowering") == 7
echo "ok"
