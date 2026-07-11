discard """
  output: "ok"
  targets: "c"
  matrix: "--experimental:abi --emitBif:on"
  ccodecheck: "'N_LIB_EXPORT N_NIMCALL\\(NI, _ZN10texportnim6chooseE3int\\)'"
  ccodecheck: "'N_LIB_EXPORT N_NIMCALL\\(NI, _ZN10texportnim6chooseE6string\\)'"
  ccodecheck: "'N_LIB_EXPORT N_NIMCALL\\(NI, _ZN10texportnim3tagE3BoxI3intE\\)'"
  ccodecheck: "'N_LIB_EXPORT N_NIMCALL\\(NI, _ZN10texportnim3tagE3BoxI6stringE\\)'"
"""

import std/[compilesettings, os, strutils, syncio]

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

discard tag(Box[int](value: 3))
discard tag(Box[string](value: "nim"))

let manifestPath = querySetting(nimcacheDir) / "texportnim.abi.nif"
doAssert fileExists(manifestPath)

var hasSemanticBif = false
for path in walkFiles(querySetting(nimcacheDir) / "*.s.bif"):
  hasSemanticBif = true
doAssert hasSemanticBif

let manifest = readFile(manifestPath)
doAssert manifest.startsWith("(.nif27)")
doAssert manifest.contains("(.dialect \"nim-native-dynlib\")")
doAssert manifest.count("(proc \"") == 4
doAssert manifest.count(" true)") == 2
doAssert manifest.count(" false)") == 2
echo "ok"
