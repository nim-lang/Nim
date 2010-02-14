#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements graphical output for Nimrod; the current
## implementation uses Cairo under the surface. 

import cairo

type
  PSurface* = ref TSurface
  TSurface {.pure, final.} = object
    c: cairo.PSurface
    
    ... # internal data
  
  
  TRect* = tuple[x, y, width, height: int]
  TPoint* = tuple[x, y: int]
  
  TColor* = distinct int ## a color stored as RGB

proc `==` *(a, b: TColor): bool {.borrow.}
  ## compares two colors.
  
template extract(a: TColor, r, g, b: expr) =
  var r = a shr 16 and 0xff
  var g = a shr 8 and 0xff
  var b = a and 0xff
  
template rawRGB(r, g, b: expr): expr =
  TColor(r shl 16 or g shl 8 or b)
  
template colorOp(op: expr) =
  extract(a, ar, ag, ab)
  extract(b, br, bg, bb)
  result = rawRGB(op(ar, br), op(ag, bg), op(ab, bb))
  
template satPlus(a, b: expr): expr =
  # saturated plus:
  block:
    var result = a +% b
    if result > 255: result = 255
    result

template satMinus(a, b: expr): expr =
  block:
    var result = a -% b
    if result < 0: result = 0
    result
  
proc `+`*(a, b: TColor): TColor =
  ## adds two colors: This uses saturated artithmetic, so that each color
  ## component cannot overflow (255 is used as a maximum).
  colorOp(satPlus)
  
proc `-`*(a, b: TColor): TColor =
  ## substracts two colors: This uses saturated artithmetic, so that each color
  ## component cannot overflow (255 is used as a maximum).
  colorOp(satMinus)
  
template mix*(a, b: TColor, fn: expr): expr =
  ## uses `fn` to mix the colors `a` and `b`. `fn` is invoked for each component
  ## R, G, and B. This is a template because `fn` should be inlined and the
  ## compiler cannot inline proc pointers yet. If `fn`'s result is not in the
  ## range[0..255], it will be saturated to be so.
  template `><` (x: expr): expr =
    # keep it in the range 0..255
    block:
      var xx = x # eval only once
      if xx >% 255:
        xx = if xx < 0: 0 else: 255
      xx
  
  extract(a, ar, ag, ab)
  extract(b, br, bg, bb)
  rawRGB(><fn(ar, br), ><fn(ag, bg), ><fn(ab, bb))


const
  colRed* = TColor(0x00ff0000) # RGB
  colGreen* = TColor(0x0000ff00)
  colBlue* = TColor(0x000000ff)
  colOrange* = TColor()
  
proc newSurface*(width, height: int): PSurface
  
proc toColor*(name: string): TColor
proc isColor*(name: string): bool

proc rgb*(r, g, b: range[0..255]): TColor =
  ## constructs a color from RGB values.
  result = rawRGB(r, g, b)

proc drawRect*(sur: PSurface, r: TRect, col: TColor)
proc fillRect*(sur: PSurface, r: TRect, col: TColor)

proc drawCircle*(sur: PSurface, mid: TPoint, radius: int)
proc drawCircle*(sur: PSurface, r: TRect)

proc fillCircle*(sur: PSurface, mid: TPoint, radius: int)
proc fillCircle*(sur: PSurface, r: TRect)

proc drawElipse*(sur: PSurface, r: TRect)
proc fillElipse*(sur: PSurface, r: TRect)


proc textBounds*(text: string): tuple[len, height: int]
proc drawText*(sur: PSurface, p: TPoint, text: string)

proc drawLine*(sur: PSurface, a, b: TPoint)

proc `[]`*(sur: PSurface, p: TPoint): TColor
proc `[,]`*(sur: PSurface, x, y: int): TColor
proc `[]=`*(sur: PSurface, p: TPoint, col: TColor)
proc `[,]=`*(sur: PSurface, x, y: int, col: TColor)

proc writeToPNG*(sur: PSurface, filename: string)


