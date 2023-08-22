import strutils, math

proc degrees*(rad: float): float =
  return rad * 180.0 / PI
proc radians*(deg: float): float =
  return deg * PI / 180.0

## V not math, sue me
proc ff*(f: float, precision = 2): string {.inline.} =
  return formatFloat(f, ffDecimal, precision)
