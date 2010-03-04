#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements graphical output for Nimrod; the current
## implementation uses SDL but the interface is meant to support multiple
## backends some day. 

import colors
from sdl import PSurface # Bug

type
  TRect* = tuple[x, y, width, height: int]
  TPoint* = tuple[x, y: int]

  PSurface* = ref TSurface ## a surface to draw onto
  TSurface {.pure, final.} = object
    w, h: int
    s: sdl.PSurface
  
proc surfaceFinalizer(s: PSurface) = sdl.freeSurface(s.s)
  
proc newSurface*(width, height: int): PSurface =
  ## creates a new surface.
  new(result, surfaceFinalizer)
  result.w = width
  result.h = height
  result.s = SDL.CreateRGBSurface(SDL.SWSURFACE, width, height, 
      32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0)
   
  assert(not sdl.MustLock(result.s))

#proc textBounds*(text: string): tuple[len, height: int]
#proc drawText*(sur: PSurface, p: TPoint, text: string)

proc writeToBMP*(sur: PSurface, filename: string) =
  ## Saves the contents of the surface `sur` to the file `filename` as a 
  ## BMP file.
  if sdl.saveBMP(sur.s, filename) != 0:
    raise newException(EIO, "cannot write: " & filename)

type
  TPixels = array[0..1000_000-1, int32]
  PPixels = ptr TPixels

template setPix(video, pitch, x, y, col: expr): stmt =
  video[y * pitch + x] = int32(col)

template getPix(video, pitch, x, y: expr): expr = 
  colors.TColor(video[y * pitch + x])

const
  ColSize = 4

proc getPixel(sur: PSurface, x, y: Natural): colors.TColor =
  result = getPix(cast[PPixels](sur.s.pixels), sur.s.pitch div ColSize, x, y)

proc setPixel(sur: PSurface, x, y: Natural, col: colors.TColor) =
  var pixs = cast[PPixels](sur.s.pixels)
  #pixs[y * (sur.s.pitch div colSize) + x] = int(col)
  setPix(pixs, sur.s.pitch div ColSize, x, y, col)

proc `[]`*(sur: PSurface, p: TPoint): TColor =
  result = getPixel(sur, p.x, p.y)

#proc `[,]`*(sur: PSurface, x, y: int): TColor =
#  result = setPixel(sur, x, y)

proc `[]=`*(sur: PSurface, p: TPoint, col: TColor) = 
  setPixel(sur, p.x, p.y, col)

#proc `[,]=`*(sur: PSurface, x, y: int, col: TColor) =
#  setPixel(sur, x, y, col)

proc drawCircle*(sur: PSurface, p: TPoint, r: Natural, color: TColor) =
  ## draws a circle with center `p` and radius `r` with the given color
  ## onto the surface `sur`.
  var video = cast[PPixels](sur.s.pixels)
  var pitch = sur.s.pitch div ColSize
  var a = 1 - r
  var py = r
  var px = 0
  var x = p.x
  var y = p.y
  while px <= py + 1:
    setPix(video, pitch, x + px, y + py, color)
    setPix(video, pitch, x + px, y - py, color)
    setPix(video, pitch, x - px, y + py, color)
    setPix(video, pitch, x - px, y - py, color)

    setPix(video, pitch, x + py, y + px, color)
    setPix(video, pitch, x + py, y - px, color)
    setPix(video, pitch, x - py, y + px, color)
    setPix(video, pitch, x - py, y - px, color)

    if a < 0:
      a = a + (2 * px + 3)
    else:
      a = a + (2 * (px - py) + 5)
      py = py - 1
    px = px + 1

proc drawLine*(sur: PSurface, p1, p2: TPoint, color: TColor) =
  ## draws a line between the two points `p1` and `p2` with the given color
  ## onto the surface `sur`.
  var stepx, stepy: int = 0
  var x0: int = p1.x
  var x1: int = p2.x
  var y0: int = p1.y
  var y1: int = p2.y
  var dy: int = y1 - y0
  var dx: int = x1 - x0
  if dy < 0:
    dy = -dy 
    stepy = -1
  else:
    stepy = 1
  if dx < 0:
    dx = -dx
    stepx = -1
  else:
    stepx = 1
  dy = dy * 2 
  dx = dx * 2
  var video = cast[PPixels](sur.s.pixels)
  var pitch = sur.s.pitch div ColSize
  setPix(video, pitch, x0, y0, color)
  if dx > dy:
    var fraction = dy - (dx div 2)
    while x0 != x1:
      if fraction >= 0:
        y0 = y0 + stepy
        fraction = fraction - dx
      x0 = x0 + stepx
      fraction = fraction + dy
      setPix(video, pitch, x0, y0, color)
  else:
    var fraction = dx - (dy div 2)
    while y0 != y1:
      if fraction >= 0:
        x0 = x0 + stepx
        fraction = fraction - dy
      y0 = y0 + stepy
      fraction = fraction + dx
      setPix(video, pitch, x0, y0, color)

proc drawHorLine*(sur: PSurface, x, y, w: Natural, Color: TColor) =
  ## draws a horizontal line from (x,y) to (x+w-1, y).
  var video = cast[PPixels](sur.s.pixels)
  var pitch = sur.s.pitch div ColSize
  for i in 0 .. w-1: setPix(video, pitch, x + i, y, color)

proc drawVerLine*(sur: PSurface, x, y, h: Natural, Color: TColor) =
  ## draws a vertical line from (x,y) to (x, y+h-1).
  var video = cast[PPixels](sur.s.pixels)
  var pitch = sur.s.pitch div ColSize
  for i in 0 .. h-1: setPix(video, pitch, x, y + i, color)

proc fillCircle*(s: PSurface, p: TPoint, r: Natural, color: TColor) =
  ## draws a circle with center `p` and radius `r` with the given color
  ## onto the surface `sur` and fills it.
  var a = 1 - r
  var py: int = r
  var px = 0
  var x = p.x
  var y = p.y
  while px <= py:
    # Fill up the middle half of the circle
    DrawVerLine(s, x + px, y, py + 1, color)
    DrawVerLine(s, x + px, y - py, py, color)
    if px != 0:
      DrawVerLine(s, x - px, y, py + 1, color)
      DrawVerLine(s, x - px, y - py, py, color)
    if a < 0:
      a = a + (2 * px + 3)
    else:
      a = a + (2 * (px - py) + 5)
      py = py - 1
      # Fill up the left/right half of the circle
      if py >= px:
        DrawVerLine(s, x + py + 1, y, px + 1, color)
        DrawVerLine(s, x + py + 1, y - px, px, color)
        DrawVerLine(s, x - py - 1, y, px + 1, color)
        DrawVerLine(s, x - py - 1, y - px,  px, color)
    px = px + 1

proc drawRect*(sur: PSurface, r: TRect, color: TColor) =
  ## draws a rectangle.
  var video = cast[PPixels](sur.s.pixels)
  var pitch = sur.s.pitch div ColSize
  for i in 0 .. r.width-1:
    setPix(video, pitch, r.x + i, r.y, color)
  for i in 0 .. r.height-1:
    setPix(video, pitch, r.x, r.y + i, color)
    setPix(video, pitch, r.x + r.width - 1, r.y + i, color)
  for i in 0 .. r.width-1:
    setPix(video, pitch, r.x + i, r.y + r.height - 1, color)
    
proc fillRect*(sur: PSurface, r: TRect, col: TColor) =
  ## draws and fills a rectancle.
  var video = cast[PPixels](sur.s.pixels)
  assert video != nil
  var pitch = sur.s.pitch div ColSize
  for i in r.y..r.y+r.height-1:
    for j in r.x..r.x+r.width-1: 
      setPix(video, pitch, j, i, col)
      
if sdl.Init(sdl.INIT_VIDEO) < 0: 
  echo "init failed"
  
when isMainModule:
  var surf = newSurface(800, 600)
  var r: TRect = (0, 0, 200, 300)
  surf.fillRect(r, colBlue)
  surf.drawHorLine(5, 5, 60, colRed)
  surf.setPixel(70, 100, colWhite)
  surf.writeToBMP("test.bmp")
