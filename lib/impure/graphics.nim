#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf, Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements graphical output for Nimrod; the current
## implementation uses SDL but the interface is meant to support multiple
## backends some day. 

import colors, math
from sdl import PSurface # Bug
from sdl_ttf import OpenFont, closeFont

type
  TRect* = tuple[x, y, width, height: int]
  TPoint* = tuple[x, y: int]

  PSurface* = ref TSurface ## a surface to draw onto
  TSurface {.pure, final.} = object
    w, h: int
    s: sdl.PSurface
  
  EGraphics* = object of EBase

  TFont {.pure, final.} = object
    f: sdl_ttf.PFont
    color: SDL.TColor
  PFont* = ref TFont ## represents a font

proc toSdlColor(c: TColor): Sdl.TColor =
  # Convert colors.TColor to SDL.TColor
  var x = c.extractRGB  
  result.r = toU8(x.r)
  result.g = toU8(x.g)
  result.b = toU8(x.b)

proc raiseEGraphics = 
  raise newException(EGraphics, $SDL.GetError())
  
proc surfaceFinalizer(s: PSurface) = sdl.freeSurface(s.s)
  
proc newSurface*(width, height: int): PSurface =
  ## creates a new surface.
  new(result, surfaceFinalizer)
  result.w = width
  result.h = height
  result.s = SDL.CreateRGBSurface(SDL.SWSURFACE, width, height, 
      32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0)
   
  assert(not sdl.MustLock(result.s))

proc fontFinalizer(f: PFont) = closeFont(f.f)

proc newFont*(name = "VeraMono.ttf", size = 9, color = colBlack): PFont =  
  ## Creates a new font object. Raises ``EIO`` if the font cannot be loaded.
  new(result, fontFinalizer)
  result.f = OpenFont(name, size)
  if result.f == nil:
    raise newException(EIO, "Could not open font file: " & name)
  result.color = toSdlColor(color)

var
  defaultFont*: PFont ## default font that is used; this needs to initialized
                      ## by the client!

proc initDefaultFont*(name = "VeraMono.ttf", size = 9, color = colBlack) = 
  ## initializes the `defaultFont` var.
  defaultFont = newFont(name, size, color)

proc newScreenSurface(width, height: int): PSurface =
  ## Creates a new screen surface
  new(result, surfaceFinalizer)
  result.w = width
  result.h = height
  result.s = SDL.SetVideoMode(width, height, 0, 0)

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

proc getPixel(sur: PSurface, x, y: Natural): colors.TColor {.inline.} =
  assert x <% sur.w
  assert y <% sur.h
  result = getPix(cast[PPixels](sur.s.pixels), sur.s.pitch div ColSize, x, y)

proc setPixel(sur: PSurface, x, y: Natural, col: colors.TColor) {.inline.} =
  assert x <% sur.w
  assert y <% sur.h
  var pixs = cast[PPixels](sur.s.pixels)
  #pixs[y * (sur.s.pitch div colSize) + x] = int(col)
  setPix(pixs, sur.s.pitch div ColSize, x, y, col)

proc `[]`*(sur: PSurface, p: TPoint): TColor =
  ## get pixel at position `p`. No range checking is done!
  result = getPixel(sur, p.x, p.y)

proc `[,]`*(sur: PSurface, x, y: int): TColor = 
  ## get pixel at position ``(x, y)``. No range checking is done!
  result = getPixel(sur, x, y)

proc `[]=`*(sur: PSurface, p: TPoint, col: TColor) = 
  ## set the pixel at position `p`. No range checking is done!
  setPixel(sur, p.x, p.y, col)

proc `[,]=`*(sur: PSurface, x, y: int, col: TColor) =
  ## set the pixel at position ``(x, y)``. No range checking is done!
  setPixel(sur, x, y, col)

proc blit*(destSurf: PSurface, destRect: TRect, srcSurf: PSurface, 
           srcRect: TRect) =
  ## Copies ``srcSurf`` into ``destSurf``
  var destTRect, srcTRect: SDL.TRect

  destTRect.x = int16(destRect.x)
  destTRect.y = int16(destRect.y)
  destTRect.w = int16(destRect.width)
  destTRect.h = int16(destRect.height)

  srcTRect.x = int16(srcRect.x)
  srcTRect.y = int16(srcRect.y)
  srcTRect.w = int16(srcRect.width)
  srcTRect.h = int16(srcRect.height)

  if SDL.blitSurface(srcSurf.s, addr(srcTRect), destSurf.s, addr(destTRect)) != 0:
    raiseEGraphics()

proc textBounds*(text: string, font = defaultFont): tuple[width, height: int] =
  var w, h: cint
  if sdl_ttf.SizeUTF8(font.f, text, w, h) < 0: raiseEGraphics()
  result.width = int(w)
  result.height = int(h)

proc drawText*(sur: PSurface, p: TPoint, text: string, font = defaultFont) =
  ## Draws text with a transparent background, at location ``p`` with the given
  ## font.
  var textSur: PSurface # This surface will have the text drawn on it
  new(textSur, surfaceFinalizer)
  
  # Render the text
  textSur.s = sdl_ttf.RenderTextBlended(font.f, text, font.color)
  # Merge the text surface with sur
  sur.blit((p.x, p.y, sur.w, sur.h), textSur, (0, 0, sur.w, sur.h))
  # Free the surface
  SDL.FreeSurface(sur.s)

proc drawText*(sur: PSurface, p: TPoint, text: string,
               bg: TColor, font = defaultFont) =
  ## Draws text, at location ``p`` with font ``font``. ``bg`` 
  ## is the background color.
  var textSur: PSurface # This surface will have the text drawn on it
  new(textSur, surfaceFinalizer)
  textSur.s = sdl_ttf.RenderTextShaded(font.f, text, font.color, toSdlColor(bg))
  # Merge the text surface with sur
  sur.blit((p.x, p.y, sur.w, sur.h), textSur, (0, 0, sur.w, sur.h))
  # Free the surface
  SDL.FreeSurface(sur.s)
  
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
    if x+px <% sur.w:
      if y+py <% sur.h: setPix(video, pitch, x+px, y+py, color)
      if y-py <% sur.h: setPix(video, pitch, x+px, y-py, color)
    
    if x-px <% sur.w:
      if y+py <% sur.h: setPix(video, pitch, x-px, y+py, color)
      if y-py <% sur.h: setPix(video, pitch, x-px, y-py, color)

    if x+py <% sur.w:
      if y+px <% sur.h: setPix(video, pitch, x+py, y+px, color)
      if y-px <% sur.h: setPix(video, pitch, x+py, y-px, color)
      
    if x-py <% sur.w:
      if y+px <% sur.h: setPix(video, pitch, x-py, y+px, color)
      if y-px <% sur.h: setPix(video, pitch, x-py, y-px, color)

    if a < 0:
      a = a + (2 * px + 3)
    else:
      a = a + (2 * (px - py) + 5)
      py = py - 1
    px = px + 1

proc `>-<`(val: int, s: PSurface): int {.inline.} = 
  return if val < 0: 0 elif val >= s.w: s.w-1 else: val

proc `>|<`(val: int, s: PSurface): int {.inline.} = 
  return if val < 0: 0 elif val >= s.h: s.h-1 else: val

proc drawLine*(sur: PSurface, p1, p2: TPoint, color: TColor) =
  ## draws a line between the two points `p1` and `p2` with the given color
  ## onto the surface `sur`.
  var stepx, stepy: int = 0
  var x0 = p1.x >-< sur
  var x1 = p2.x >-< sur
  var y0 = p1.y >|< sur
  var y1 = p2.y >|< sur
  var dy = y1 - y0
  var dx = x1 - x0
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

  if y >= 0 and y <= sur.s.h:
    for i in 0 .. min(sur.s.w-x, w)-1:
      setPix(video, pitch, x + i, y, color)

proc drawVerLine*(sur: PSurface, x, y, h: Natural, Color: TColor) =
  ## draws a vertical line from (x,y) to (x, y+h-1).
  var video = cast[PPixels](sur.s.pixels)
  var pitch = sur.s.pitch div ColSize

  if x >= 0 and x <= sur.s.w:
    for i in 0 .. min(sur.s.h-y, h)-1:
      setPix(video, pitch, x, y + i, color)

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
  if (r.x >= 0 and r.x <= sur.s.w) and (r.y >= 0 and r.y <= sur.s.h):
    var minW = min(sur.s.w - r.x, r.width - 1)
    var minH = min(sur.s.h - r.y, r.height - 1)
    
    # Draw Top
    for i in 0 .. minW - 1:
      setPix(video, pitch, r.x + i, r.y, color)
      setPix(video, pitch, r.x + i, r.y + minH - 1, color) # Draw bottom
      
    # Draw left side    
    for i in 0 .. minH - 1:
      setPix(video, pitch, r.x, r.y + i, color)
      setPix(video, pitch, r.x + minW - 1, r.y + i, color) # Draw right side
    
proc fillRect*(sur: PSurface, r: TRect, col: TColor) =
  ## draws and fills a rectangle.
  var video = cast[PPixels](sur.s.pixels)
  assert video != nil
  var pitch = sur.s.pitch div ColSize

  for i in r.y..min(sur.s.h, r.y+r.height-1)-1:
    for j in r.x..min(sur.s.w, r.x+r.width-1)-1:
      setPix(video, pitch, j, i, col)

proc Plot4EllipsePoints(sur: PSurface, CX, CY, X, Y: Natural, col: TColor) =
  var video = cast[PPixels](sur.s.pixels)
  var pitch = sur.s.pitch div ColSize
  if CX+X <= sur.s.w-1:
    if CY+Y <= sur.s.h-1: setPix(video, pitch, CX+X, CY+Y, col)
    if CY-Y <= sur.s.h-1: setPix(video, pitch, CX+X, CY-Y, col)    
  if CX-X <= sur.s.w-1:
    if CY+Y <= sur.s.h-1: setPix(video, pitch, CX-X, CY+Y, col)
    if CY-Y <= sur.s.h-1: setPix(video, pitch, CX-X, CY-Y, col)

proc drawEllipse*(sur: PSurface, CX, CY, XRadius, YRadius: Natural, 
                  col: TColor) =
  ## Draws an ellipse, ``CX`` and ``CY`` specify the center X and Y of the 
  ## ellipse, ``XRadius`` and ``YRadius`` specify half the width and height
  ## of the ellipse.
  var 
    X, Y: Natural
    XChange, YChange: Natural
    EllipseError: Natural
    TwoASquare, TwoBSquare: Natural
    StoppingX, StoppingY: Natural
    
  TwoASquare = 2 * XRadius * XRadius
  TwoBSquare = 2 * YRadius * YRadius
  X = XRadius
  Y = 0
  XChange = YRadius * YRadius * (1 - 2 * XRadius)
  YChange = XRadius * XRadius
  EllipseError = 0
  StoppingX = TwoBSquare * XRadius
  StoppingY = 0
  
  while StoppingX >=  StoppingY: # 1st set of points, y` > - 1
    sur.Plot4EllipsePoints(CX, CY, X, Y, col)
    inc(Y)
    inc(StoppingY, TwoASquare)
    inc(EllipseError, YChange)
    inc(YChange, TwoASquare)
    if (2 * EllipseError + XChange) > 0 :
      dec(x)
      dec(StoppingX, TwoBSquare)
      inc(EllipseError, XChange)
      inc(XChange, TwoBSquare)
      
  # 1st point set is done; start the 2nd set of points
  X = 0
  Y = YRadius
  XChange = YRadius * YRadius
  YChange = XRadius * XRadius * (1 - 2 * YRadius)
  EllipseError = 0
  StoppingX = 0
  StoppingY = TwoASquare * YRadius
  while StoppingX <= StoppingY:
    sur.Plot4EllipsePoints(CX, CY, X, Y, col)
    inc(X)
    inc(StoppingX, TwoBSquare)
    inc(EllipseError, XChange)
    inc(XChange,TwoBSquare)
    if (2 * EllipseError + YChange) > 0:
      dec(Y)
      dec(StoppingY, TwoASquare)
      inc(EllipseError, YChange)
      inc(YChange,TwoASquare)
  

proc plotAA(sur: PSurface, x, y, c: float, color: TColor) =
  if (x.toInt() > 0 and x.toInt() < sur.s.w) and (y.toInt() > 0 and 
      y.toInt() < sur.s.h):
    var video = cast[PPixels](sur.s.pixels)
    var pitch = sur.s.pitch div ColSize

    var pixColor = getPix(video, pitch, x.toInt, y.toInt)

    setPix(video, pitch, x.toInt(), y.toInt(), 
           pixColor.intensity(1.0 - c) + color.intensity(c))
         
proc ipart(x: float): float = return x.trunc()
proc fpart(x: float): float = return x - ipart(x)
proc rfpart(x: float): float = return 1.0 - fpart(x)

proc drawLineAA(sur: PSurface, p1, p2: TPoint, color: TColor) =
  ## Draws a anti-aliased line from ``p1`` to ``p2``, using Xiaolin Wu's 
  ## line algorithm
  var (x1, x2, y1, y2) = (p1.x.toFloat(), p2.x.toFloat(), 
                          p1.y.toFloat(), p2.y.toFloat())
  var dx = x2 - x1
  var dy = y2 - y1
  if abs(dx) < abs(dy):
    swap(x1, y1)
    swap(x2, y2)
  if x2 < x1:
    swap(x1, x2)
    swap(y1, y2)

  var gradient = dy / dx
  # handle first endpoint
  var xend = x1  # Should be round(x1), but since this is an int anyway..
  var yend = y1 + gradient * (xend - x1)
  var xgap = rfpart(x1 + 0.5)
  var xpxl1 = xend # this will be used in the main loop
  var ypxl1 = ipart(yend)
  sur.plotAA(xpxl1, ypxl1, rfpart(yend) * xgap, color)
  sur.plotAA(xpxl1, ypxl1 + 1.0, fpart(yend) * xgap, color)
  var intery = yend + gradient # first y-intersection for the main loop
  # handle second endpoint
  xend = x2 # Should be round(x1), but since this is an int anyway..
  yend = y2 + gradient * (xend - x2)
  xgap = fpart(x2 + 0.5)
  var xpxl2 = xend  # this will be used in the main loop
  var ypxl2 = ipart(yend)
  sur.plotAA(xpxl2, ypxl2, rfpart(yend) * xgap, color)
  sur.plotAA(xpxl2, ypxl2 + 1.0, fpart(yend) * xgap, color)  
  # main loop
  for x in xpxl1.toInt + 1..xpxl2.toInt - 1:
    sur.plotAA(x.toFloat(), ipart(intery), rfpart(intery), color)
    sur.plotAA(x.toFloat(), ipart(intery) + 1.0, fpart(intery), color)
    intery = intery + gradient

template withEvents(surf: PSurface, event: expr, actions: stmt): stmt =
  while True:
    var event: SDL.TEvent
    if SDL.PollEvent(addr(event)) == 1:
      actions

if sdl.Init(sdl.INIT_VIDEO) < 0: raiseEGraphics()
if sdl_ttf.Init() < 0: raiseEGraphics()

when isMainModule:
  var surf = newScreenSurface(800, 600)
  var r: TRect = (0, 0, 900, 900)
    
  # Draw the shapes
  surf.fillRect(r, colWhite)
  surf.drawLineAA((100, 170), (400, 471), colTan)
  surf.drawLine((100, 170), (400, 471), colRed)
  
  surf.drawEllipse(200, 300, 200, 30, colSeaGreen)
  surf.drawHorLine(1, 300, 400, colViolet) 
  # Check if the ellipse is the size it's suppose to be.
  surf.drawVerLine(200, 300 - 30 + 1, 60, colViolet) # ^^ | i suppose it is
  
  surf.drawEllipse(400, 300, 300, 300, colOrange)
  surf.drawEllipse(5, 5, 5, 5, colGreen)
  
  surf.drawHorLine(5, 5, 900, colRed)
  surf.drawVerLine(5, 60, 800, colRed)
  surf.drawCircle((600, 500), 60, colRed)
  
  #surf.drawText((300, 300), "TEST", colMidnightBlue)
  #var textSize = textBounds("TEST")
  #surf.drawText((300, 300 + textSize.height), $textSize.width & ", " &
  #  $textSize.height, colDarkGreen)
  
  var mouseStartX = 0
  var mouseStartY = 0
  withEvents(surf, event):
    case event.kind:
    of SDL.QUITEV:
      break
    of SDL.KEYDOWN:
      if event.sym == SDL.K_LEFT:
        echo(event.sym)
        surf.drawHorLine(395, 300, 5, colPaleGoldenRod)
        echo("Drawing")
      else:
        echo(event.sym)
    of SDL.MOUSEBUTTONDOWN:
      # button.x/y is F* UP!
      echo("MOUSEDOWN ", event.x)
      mouseStartX = event.x
      mouseStartY = event.y
      
    of SDL.MOUSEBUTTONUP:
      echo("MOUSEUP ", mouseStartX)
      if mouseStartX != 0 and mouseStartY != 0:
        echo(mouseStartX, "->", int(event.x))
        surf.drawLineAA((mouseStartX, MouseStartY), 
          (int(event.x), int(event.y)), colPaleGoldenRod)
        mouseStartX = 0
        mouseStartY = 0
      
    else:
      #echo(event.theType)
      
    SDL.UpdateRect(surf.s, int32(0), int32(0), int32(800), int32(600))
    
  surf.writeToBMP("test.bmp")
  SDL.Quit()
