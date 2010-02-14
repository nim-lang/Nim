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

type
  PSurface* = ref TSurface
  TSurface {.pure, final.} = object
    ... # internal data
  
  
  TRect* = tuple[x, y, width, height: int]
  TPoint* = tuple[x, y: int]
  
  TColor* = distinct int ## a color stored as RGB

proc `==` (a, b: TColor): bool {.borrow.}
# XXX maybe other operations for colors? What about saturated artithmetic?


const
  colRed* = TColor(0x00ff0000) # RGB
  colGreen* = ...
  colBlue* = ...
  colOrange* = ...
  
proc newSurface*(width, height: int): PSurface
  
proc color*(name: string): TColor
proc isColor*(name: string): bool

proc rgb*(r, g, b: range[0..255]): TColor


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


