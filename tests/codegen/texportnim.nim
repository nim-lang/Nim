discard """
  output: "ok"
  targets: "c"
  matrix: "--emitAbiBif:on"
  ccodecheck: "'N_LIB_EXPORT N_NIMCALL\\(NI, _ZN10texportnim6chooseE3int\\)'"
  ccodecheck: "'N_LIB_EXPORT N_NIMCALL\\(NI, _ZN10texportnim6chooseE6string\\)'"
  ccodecheck: "'N_LIB_EXPORT N_NIMCALL\\(NI, _ZN10texportnim3tagE3BoxI3intE\\)'"
  ccodecheck: "'N_LIB_EXPORT N_NIMCALL\\(NI, _ZN10texportnim3tagE3BoxI6stringE\\)'"
"""

import std/[compilesettings, json, os]

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

let manifestPath = querySetting(nimcacheDir) / "texportnim.abi.json"
doAssert fileExists(manifestPath)

var hasSemanticBif = false
for path in walkFiles(querySetting(nimcacheDir) / "*.s.bif"):
  hasSemanticBif = true
doAssert hasSemanticBif

let manifest = parseFile(manifestPath)
doAssert manifest["format"].getStr == "nim-native-dynlib-backend-v1"
doAssert manifest["allocator"].getStr.len > 0
doAssert manifest["procs"].len == 4
doAssert manifest["procs"][2]["genericInstance"].getBool
doAssert manifest["procs"][3]["genericInstance"].getBool
echo "ok"
