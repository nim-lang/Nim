discard """
  output: "ok"
  targets: "c"
  matrix: "--genBif:on"
"""

import std/[compilesettings, os, strutils]

proc bifGenericArguments(values: seq[int], fixed: array[4, int]) =
  discard values
  discard fixed

let cache = querySetting(nimcacheDir)
var hasSemanticBif = false
var hasGenericArgs = false
for path in walkFiles(cache / "*.s.bif"):
  hasSemanticBif = true
  hasGenericArgs = hasGenericArgs or "genericargs" in readFile(path)
doAssert hasSemanticBif
doAssert hasGenericArgs
echo "ok"
