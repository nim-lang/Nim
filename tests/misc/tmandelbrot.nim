discard """
  cmd: "nimrod $target --hints:on -d:release $options $file"
"""

# -*- nimrod -*-

import math
import os
import strutils

type TComplex = tuple[re, im: float]

proc `+` (a, b: TComplex): TComplex =
    return (a.re + b.re, a.im + b.im)

proc `*` (a, b: TComplex): TComplex =
    result.re = a.re * b.re - a.im * b.im
    result.im = a.re * b.im + a.im * b.re

proc abs2 (a: TComplex): float =
    return a.re * a.re + a.im * a.im

var size    = parseInt (paramStr (1))
var bit     = 128
var byteAcc = 0

stdout.writeln ("P4")
stdout.write ($size)
stdout.write (" ")
stdout.writeln ($size)

var fsize = float (size)
for y in 0 .. size-1:
    var fy = 2.0 * float (y) / fsize - 1.0
    for x in 0 .. size-1:
        var z = (0.0, 0.0)
        var c = (float (2*x) / fsize - 1.5, fy)

        block iter:
            for i in 0 .. 49:
                z = z*z + c
                if abs2 (z) >= 4.0:
                    break iter
            byteAcc = byteAcc + bit

        if bit > 1:
            bit = bit div 2
        else:
            stdout.write (chr (byteAcc))
            bit     = 128
            byteAcc = 0

    if bit != 128:
        stdout.write (chr (byteAcc))
        bit     = 128
        byteAcc = 0

