discard """
  output: "ok"
  targets: "c"
  matrix: "--genBif:on"
"""

import std/[compilesettings, os]

let cache = querySetting(nimcacheDir)
var hasSemanticBif = false
for path in walkFiles(cache / "*.s.bif"):
  hasSemanticBif = true
doAssert hasSemanticBif
echo "ok"
