discard """
disabled: windows
"""

{.passL: "-lm".} # not sure how to do this on windows

import strutils

proc nextafter(a,b: float64): float64 {.importc: "nextafter", header: "<math.h>".}

var myFloat = 2.5

for i in 0 .. 100:
  let newFloat = nextafter(myFloat, Inf)
  let oldStr = $myFloat
  let newStr = $newFloat
  doAssert parseFloat(newStr) == newFloat
  doAssert oldStr != newStr
  myFloat = newFloat
