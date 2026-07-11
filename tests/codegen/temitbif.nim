discard """
  output: "ok"
  targets: "c"
  matrix: "--emitBif:on"
"""

import std/[compilesettings, os]

let cache = querySetting(nimcacheDir)
var hasSemanticBif = false
for path in walkFiles(cache / "*.s.bif"):
  hasSemanticBif = true
doAssert hasSemanticBif
doAssert not fileExists(cache / "temitbif.abi.nif")
echo "ok"
