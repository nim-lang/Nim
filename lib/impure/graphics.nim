#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf, Dominik Picheta
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements graphical output for Nim; the current
## implementation uses SDL but the interface is meant to support multiple
## backends some day. There is no need to init SDL as this module does that
## implicitly.

import colors, math
from sdl import PSurface # Bug
from sdl_ttf import openFont, closeFont

type
  TRect* = tuple[x, y, width, height: int]
  TPoint* = tuple[x, y: int]

  PSurface* = ref TSurface ## a surface to draw onto
  TSurface* {.pure, final.} = object
    w*, h*: Natural
    s*: sdl.PSurface

  EGraphics* = object of IOError

  TFont {.pure, final.} = object
    f: sdl_ttf.PFont
    color: sdl.TColor
  PFont* = ref TFont ## represents a font

proc toSdlColor*(c: Color): sdl.TColor =
  ## Convert colors.TColor to sdl.TColor
  var x = c.extractRGB
  result.r = x.r and 0xff
  result.g = x.g and 0xff
  result.b = x.b and 0xff

proc createSdlColor*(sur: PSurface, c: Color, alpha: int = 0): int32 =
  ## Creates a color using ``sdl.MapRGBA``.
  var x = c.extractRGB
  return sdl.mapRGBA(sur.s.format, x.r and 0xff, x.g and 0xff,
                     x.b and 0xff, alpha and 0xff)

proc toSdlRect*(r: TRect): sdl.TRect =
  ## Convert ``graphics.TRect`` to ``sdl.TRect``.
  result.x = int16(r.x)
  result.y = int16(r.y)
  result.w = uint16(r.width)
  result.h = uint16(r.height)

proc raiseEGraphics =
  raise newException(EGraphics, $sdl.getError())

proc surfaceFinalizer(s: PSurface) = sdl.freeSurface(s.s)

proc newSurface*(width, height: int): PSurface =
  ## creates a new surface.
  new(result, surfaceFinalizer)
  result.w = width
  result.h = height
  result.s = sdl.createRGBSurface(sdl.SWSURFACE, width, height,
      32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0)
  if result.s == nil:
    raiseEGraphics()

  assert(not sdl.mustLock(result.s))

proc fontFinalizer(f: PFont) = closeFont(f.f)

proc newFont*(name = "VeraMono.ttf", size = 9, color = colBlack): PFont =
  ## Creates a new font object. Raises ``EIO`` if the font cannot be loaded.
  new(result, fontFinalizer)
  result.f = openFont(name, size.cint)
  if result.f == nil:
    raise newException(IOError, "Could not open font file: " & name)
  result.color = toSdlColor(color)

var
  defaultFont*: PFont ## default font that is used; this needs to initialized
                      ## by the client!

proc initDefaultFont*(name = "VeraMono.ttf", size = 9, color = colBlack) =
  ## initializes the `defaultFont` var.
  defaultFont = newFont(name, size, color)

proc newScreenSurface*(width, height: int): PSurface =
  ## Creates a new screen surface
  new(result, surfaceFinalizer)
  result.w = width
  result.h = height
  result.s = sdl.setVideoMode(width, height, 0, 0)
  if result.s == nil:
    raiseEGraphics()

proc writeToBMP*(sur: PSurface, filename: string) =
  ## Saves the contents of the surface `sur` to the file `filename` as a
  ## BMP file.
  if sdl.saveBMP(sur.s, filename) != 0:
    raise newException(IOError, "cannot write: " & filename)

type
  TPixels = array[0..1000_000-1, int32]
  PPixels = ptr TPixels

template setPix(video, pitch, x, y, col: expr): stmt =
  video[y * pitch + x] = int32(col)

template getPix(video, pitch, x, y: expr): expr =
  colors.Color(video[y * pitch + x])

const
  ColSize = 4

proc getPixel(sur: PSurface, x, y: Natural): colors.Color {.inline.} =
  assert x <% sur.w
  assert y <% sur.h
  result = getPix(cast[PPixels](sur.s.pixels), sur.s.pitch.int div ColSize,
                  x, y)

proc setPixel(sur: PSurface, x, y: Natural, col: colors.Color) {.inline.} =
  assert x <% sur.w
  assert y <% sur.h
  var pixs = cast[PPixels](sur.s.pixels)
  #pixs[y * (sur.s.pitch div colSize) + x] = int(col)
  setPix(pixs, sur.s.pitch.int div ColSize, x, y, col)

proc `[]`*(sur: PSurface, p: TPoint): Color =
  ## get pixel at position `p`. No range checking is done!
  result = getPixel(sur, p.x, p.y)

proc `[]`*(sur: PSurface, x, y: int): Color =
  ## get pixel at position ``(x, y)``. No range checking is done!
  result = getPixel(sur, x, y)

proc `[]=`*(sur: PSurface, p: TPoint, col: Color) =
  ## set the pixel at position `p`. No range checking is done!
  setPixel(sur, p.x, p.y, col)

proc `[]=`*(sur: PSurface, x, y: int, col: Color) =
  ## set the pixel at position ``(x, y)``. No range checking is done!
  setPixel(sur, x, y, col)

proc blit*(destSurf: PSurface, destRect: TRect, srcSurf: PSurface,
           srcRect: TRect) =
  ## Copies ``srcSurf`` into ``destSurf``
  var destTRect, srcTRect: sdl.TRect

  destTRect.x = int16(destRect.x)
  destTRect.y = int16(destRect.y)
  destTRect.w = uint16(destRect.width)
  destTRect.h = uint16(destRect.height)

  srcTRect.x = int16(srcRect.x)
  srcTRect.y = int16(srcRect.y)
  srcTRect.w = uint16(srcRect.width)
  srcTRect.h = uint16(srcRect.height)

  if sdl.blitSurface(srcSurf.s, addr(srcTRect), destSurf.s, addr(destTRect)) != 0:
    raiseEGraphics()

proc textBounds*(text: string, font = defaultFont): tuple[width, height: int] =
  var w, h: cint
  if sdl_ttf.sizeUTF8(font.f, text, w, h) < 0: raiseEGraphics()
  result.width = int(w)
  result.height = int(h)

proc drawText*(sur: PSurface, p: TPoint, text: string, font = defaultFont) =
  ## Draws text with a transparent background, at location ``p`` with the given
  ## font.
  var textSur: PSurface # This surface will have the text drawn on it
  new(textSur, surfaceFinalizer)

  # Render the text
  textSur.s = sdl_ttf.renderTextBlended(font.f, text, font.color)
  # Merge the text surface with sur
  sur.blit((p.x, p.y, sur.w, sur.h), textSur, (0, 0, sur.w, sur.h))

proc drawText*(sur: PSurface, p: TPoint, text: string,
               bg: Color, font = defaultFont) =
  ## Draws text, at location ``p`` with font ``font``. ``bg``
  ## is the background color.
  var textSur: PSurface # This surface will have the text drawn on it
  new(textSur, surfaceFinalizer)
  textSur.s = sdl_ttf.renderTextShaded(font.f, text, font.color, toSdlColor(bg))
  # Merge the text surface with sur
  sur.blit((p.x, p.y, sur.w, sur.h), textSur, (0, 0, sur.w, sur.h))

proc drawCircle*(sur: PSurface, p: TPoint, r: Natural, color: Color) =
  ## draws a circle with center `p` and radius `r` with the given color
  ## onto the surface `sur`.
  var video = cast[PPixels](sur.s.pixels)
  var pitch = sur.s.pitch.int div ColSize
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

proc drawLine*(sur: PSurface, p1, p2: TPoint, color: Color) =
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
  var pitch = sur.s.pitch.int div ColSize
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

proc drawHorLine*(sur: PSurface, x, y, w: Natural, color: Color) =
  ## draws a horizontal line from (x,y) to (x+w-1, y).
  var video = cast[PPixels](sur.s.pixels)
  var pitch = sur.s.pitch.int div ColSize

  if y >= 0 and y <= sur.s.h:
    for i in 0 .. min(sur.s.w-x, w)-1:
      setPix(video, pitch, x + i, y, color)

proc drawVerLine*(sur: PSurface, x, y, h: Natural, color: Color) =
  ## draws a vertical line from (x,y) to (x, y+h-1).
  var video = cast[PPixels](sur.s.pixels)
  var pitch = sur.s.pitch.int div ColSize

  if x >= 0 and x <= sur.s.w:
    for i in 0 .. min(sur.s.h-y, h)-1:
      setPix(video, pitch, x, y + i, color)

proc fillCircle*(s: PSurface, p: TPoint, r: Natural, color: Color) =
  ## draws a circle with center `p` and radius `r` with the given color
  ## onto the surface `sur` and fills it.
  var a = 1 - r
  var py: int = r
  var px = 0
  var x = p.x
  var y = p.y
  while px <= py:
    # Fill up the middle half of the circle
    drawVerLine(s, x + px, y, py + 1, color)
    drawVerLine(s, x + px, y - py, py, color)
    if px != 0:
      drawVerLine(s, x - px, y, py + 1, color)
      drawVerLine(s, x - px, y - py, py, color)
    if a < 0:
      a = a + (2 * px + 3)
    else:
      a = a + (2 * (px - py) + 5)
      py = py - 1
      # Fill up the left/right half of the circle
      if py >= px:
        drawVerLine(s, x + py + 1, y, px + 1, color)
        drawVerLine(s, x + py + 1, y - px, px, color)
        drawVerLine(s, x - py - 1, y, px + 1, color)
        drawVerLine(s, x - py - 1, y - px,  px, color)
    px = px + 1

proc drawRect*(sur: PSurface, r: TRect, color: Color) =
  ## draws a rectangle.
  var video = cast[PPixels](sur.s.pixels)
  var pitch = sur.s.pitch.int div ColSize
  if (r.x >= 0 and r.x <= sur.s.w) and (r.y >= 0 and r.y <= sur.s.h):
    var minW = min(sur.s.w - r.x, r.width)
    var minH = min(sur.s.h - r.y, r.height)

    # Draw Top
    for i in 0 .. minW - 1:
      setPix(video, pitch, r.x + i, r.y, color)
      setPix(video, pitch, r.x + i, r.y + minH - 1, color) # Draw bottom

    # Draw left side
    for i in 0 .. minH - 1:
      setPix(video, pitch, r.x, r.y + i, color)
      setPix(video, pitch, r.x + minW - 1, r.y + i, color) # Draw right side

proc fillRect*(sur: PSurface, r: TRect, col: Color) =
  ## Fills a rectangle using sdl's ``FillRect`` function.
  var rect = toSdlRect(r)
  if sdl.fillRect(sur.s, addr(rect), sur.createSdlColor(col)) == -1:
    raiseEGraphics()

proc plot4EllipsePoints(sur: PSurface, cx, cy, x, y: Natural, col: Color) =
  var video = cast[PPixels](sur.s.pixels)
  var pitch = sur.s.pitch.int div ColSize
  if cx+x <= sur.s.w-1:
    if cy+y <= sur.s.h-1: setPix(video, pitch, cx+x, cy+y, col)
    if cy-y <= sur.s.h-1: setPix(video, pitch, cx+x, cy-y, col)
  if cx-x <= sur.s.w-1:
    if cy+y <= sur.s.h-1: setPix(video, pitch, cx-x, cy+y, col)
    if cy-y <= sur.s.h-1: setPix(video, pitch, cx-x, cy-y, col)

proc drawEllipse*(sur: PSurface, cx, cy, xRadius, yRadius: Natural,
                  col: Color) =
  ## Draws an ellipse, ``CX`` and ``CY`` specify the center X and Y of the
  ## ellipse, ``XRadius`` and ``YRadius`` specify half the width and height
  ## of the ellipse.
  var
    x, y: Natural
    xChange, yChange: int
    ellipseError: Natural
    twoASquare, twoBSquare: Natural
    stoppingX, stoppingY: Natural

  twoASquare = 2 * xRadius * xRadius
  twoBSquare = 2 * yRadius * yRadius
  x = xRadius
  y = 0
  xChange = yRadius * yRadius * (1 - 2 * xRadius)
  yChange = xRadius * xRadius
  ellipseError = 0
  stoppingX = twoBSquare * xRadius
  stoppingY = 0

  while stoppingX >=  stoppingY: # 1st set of points, y` > - 1
    sur.plot4EllipsePoints(cx, cy, x, y, col)
    inc(y)
    inc(stoppingY, twoASquare)
    inc(ellipseError, yChange)
    inc(yChange, twoASquare)
    if (2 * ellipseError + xChange) > 0 :
      dec(x)
      dec(stoppingX, twoBSquare)
      inc(ellipseError, xChange)
      inc(xChange, twoBSquare)

  # 1st point set is done; start the 2nd set of points
  x = 0
  y = yRadius
  xChange = yRadius * yRadius
  yChange = xRadius * xRadius * (1 - 2 * yRadius)
  ellipseError = 0
  stoppingX = 0
  stoppingY = twoASquare * yRadius
  while stoppingX <= stoppingY:
    sur.plot4EllipsePoints(cx, cy, x, y, col)
    inc(x)
    inc(stoppingX, twoBSquare)
    inc(ellipseError, xChange)
    inc(xChange,twoBSquare)
    if (2 * ellipseError + yChange) > 0:
      dec(y)
      dec(stoppingY, twoASquare)
      inc(ellipseError, yChange)
      inc(yChange,twoASquare)


proc plotAA(sur: PSurface, x, y: int, c: float, color: Color) =
  if (x > 0 and x < sur.s.w) and (y > 0 and y < sur.s.h):
    var video = cast[PPixels](sur.s.pixels)
    var pitch = sur.s.pitch.int div ColSize

    var pixColor = getPix(video, pitch, x, y)

    setPix(video, pitch, x, y,
           pixColor.intensity(1.0 - c) + color.intensity(c))


template ipart(x: expr): expr = floor(x)
template cround(x: expr): expr = ipart(x + 0.5)
template fpart(x: expr): expr = x - ipart(x)
template rfpart(x: expr): expr = 1.0 - fpart(x)

proc drawLineAA*(sur: PSurface, p1, p2: TPoint, color: Color) =
  ## Draws a anti-aliased line from ``p1`` to ``p2``, using Xiaolin Wu's
  ## line algorithm
  var (x1, x2, y1, y2) = (p1.x.toFloat(), p2.x.toFloat(),
                          p1.y.toFloat(), p2.y.toFloat())
  var dx = x2 - x1
  var dy = y2 - y1

  var ax = dx
  if ax < 0'f64:
    ax = 0'f64 - ax
  var ay = dy
  if ay < 0'f64:
    ay = 0'f64 - ay

  if ax < ay:
    swap(x1, y1)
    swap(x2, y2)
    swap(dx, dy)

  template doPlot(x, y: int, c: float, color: Color): stmt =
    if ax < ay:
      sur.plotAA(y, x, c, color)
    else:
      sur.plotAA(x, y, c, color)

  if x2 < x1:
    swap(x1, x2)
    swap(y1, y2)

  var gradient = dy / dx
  # handle first endpoint
  var xend = cround(x1)
  var yend = y1 + gradient * (xend - x1)
  var xgap = rfpart(x1 + 0.5)
  var xpxl1 = int(xend) # this will be used in the main loop
  var ypxl1 = int(ipart(yend))
  doPlot(xpxl1, ypxl1, rfpart(yend)*xgap, color)
  doPlot(xpxl1, ypxl1 + 1, fpart(yend)*xgap, color)
  var intery = yend + gradient # first y-intersection for the main loop

  # handle second endpoint
  xend = cround(x2)
  yend = y2 + gradient * (xend - x2)
  xgap = fpart(x2 + 0.5)
  var xpxl2 = int(xend) # this will be used in the main loop
  var ypxl2 = int(ipart(yend))
  doPlot(xpxl2, ypxl2, rfpart(yend) * xgap, color)
  doPlot(xpxl2, ypxl2 + 1, fpart(yend) * xgap, color)

  # main loop
  var x = xpxl1 + 1
  while x <= xpxl2-1:
    doPlot(x, int(ipart(intery)), rfpart(intery), color)
    doPlot(x, int(ipart(intery)) + 1, fpart(intery), color)
    intery = intery + gradient
    inc(x)

proc fillSurface*(sur: PSurface, color: Color) =
  ## Fills the entire surface with ``color``.
  if sdl.fillRect(sur.s, nil, sur.createSdlColor(color)) == -1:
    raiseEGraphics()

template withEvents*(surf: PSurface, event: expr, actions: stmt): stmt {.
  immediate.} =
  ## Simple template which creates an event loop. ``Event`` is the name of the
  ## variable containing the TEvent object.
  while true:
    var event: sdl.TEvent
    if sdl.waitEvent(addr(event)) == 1:
      actions

if sdl.init(sdl.INIT_VIDEO) < 0: raiseEGraphics()
if sdl_ttf.init() < 0: raiseEGraphics()

when isMainModule:
  var surf = newScreenSurface(800, 600)

  surf.fillSurface(colWhite)

  # Draw the shapes
  surf.drawLineAA((150, 170), (400, 471), colTan)
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

  surf.fillRect((50, 50, 100, 100), colFuchsia)
  surf.fillRect((150, 50, 100, 100), colGreen)
  surf.drawRect((50, 150, 100, 100), colGreen)
  surf.drawRect((150, 150, 100, 100), colAqua)
  surf.drawRect((250, 150, 100, 100), colBlue)
  surf.drawHorLine(250, 150, 100, colRed)

  surf.drawLineAA((592, 160), (592, 280), colPurple)

  #surf.drawText((300, 300), "TEST", colMidnightBlue)
  #var textSize = textBounds("TEST")
  #surf.drawText((300, 300 + textSize.height), $textSize.width & ", " &
  #  $textSize.height, colDarkGreen)

  var mouseStartX = -1
  var mouseStartY = -1
  withEvents(surf, event):
    var eventp = addr(event)
    case event.kind:
    of sdl.QUITEV:
      break
    of sdl.KEYDOWN:
      var evk = sdl.evKeyboard(eventp)
      if evk.keysym.sym == sdl.K_LEFT:
        surf.drawHorLine(395, 300, 50, colBlack)
        echo("Drawing")
      elif evk.keysym.sym == sdl.K_ESCAPE:
        break
      else:
        echo(evk.keysym.sym)
    of sdl.MOUSEBUTTONDOWN:
      var mbd = sdl.evMouseButton(eventp)
      if mouseStartX == -1 or mouseStartY == -1:
        mouseStartX = int(mbd.x)
        mouseStartY = int(mbd.y)
      else:
        surf.drawLineAA((mouseStartX, mouseStartY), (int(mbd.x), int(mbd.y)), colPurple)
        mouseStartX = -1
        mouseStartY = -1

    of sdl.MOUSEMOTION:
      var mm = sdl.evMouseMotion(eventp)
      if mouseStartX != -1 and mouseStartY != -1:
        surf.drawLineAA((mouseStartX, mouseStartY), (int(mm.x), int(mm.y)), colPurple)
      #echo(mm.x, " ", mm.y, " ", mm.yrel)

    else:
      discard "echo(event.kind)"

    sdl.updateRect(surf.s, 0, 0, 800, 600)

  surf.writeToBMP("test.bmp")
  sdl.quit()
