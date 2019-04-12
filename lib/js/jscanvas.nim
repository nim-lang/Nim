#
#
#            Nim's Runtime Library
#        (c) Copyright 2019 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module, which targets JavaScript, is a wrapper for the `Canvas API
## <https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API>`_.
##
## Currently only a subset of objects, method overloads and default parameters
## are interfaced. To aid the user in writing performant code, floating
## point coordinates are not supported.

when not defined(js) and not defined(Nimdoc):
  {.error: "This module only works on the JavaScript platform".}

import dom

type
  # https://developer.mozilla.org/en-US/docs/Web/API/HTMLCanvasElement
  CanvasElement* = ref CanvasObj
  CanvasObj {.importc.} = object of Element
    height*: int
    width*: int

  # https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D
  CanvasContext* = ref RenderingObj
  RenderingObj {.importc.} = object
    # Line styles
    lineWidth*: int
    lineCap*: cstring
    lineJoin*: cstring
    miterLimit*: int
    lineDashOffset*: float
    # Text styles
    font*: cstring
    textAlign*: cstring
    textBaseline*: cstring
    # Fill and stroke styles
    fillStyle*: cstring
    strokeStyle*: cstring
    # Compositing
    globalAlpha*: float
    globalCompositeOperation*: cstring

  LineCap* {.pure.} = enum
    Butt = "butt",
    Round = "round",
    Square = "square"

  LineJoin* {.pure.} = enum
    Bevel = "bevel",
    Round = "round",
    Miter = "miter"

  TextAlignment* {.pure.} = enum
    Left = "left",
    Right = "right",
    Center = "center",
    Start = "start",
    End = "end"

  TextBaseline* {.pure.} = enum
    Top = "top",
    Hanging = "hanging",
    Middle = "middle",
    Alphabetic = "alphabetic",
    Ideographic = "ideographic",
    Bottom = "bottom"

  CompositeOperation* {.pure.} = enum
    SourceOver = "source-over",
    SourceIn = "source-in",
    SourceOut = "source-out",
    SourceAtop = "source-atop",
    DestinationOver = "destination-over",
    DestinationIn = "destination-in",
    DestinationOut = "destination-out",
    DestinationAtop = "destination-atop",
    Lighter = "lighter",
    Copy = "copy",
    Xor = "xor",
    Multiply = "multiply",
    Screen = "screen",
    Overlay = "overlay",
    Darken = "darker",
    Lighten = "lighten",
    ColorDodge = "color-dodge",
    ColorBurn = "color-burn",
    HardLight = "hard-light",
    SoftLight = "soft-light",
    Difference = "difference",
    Exclusion = "exculsion",
    Hue = "hue",
    Saturation = "saturation",
    Color = "color",
    Luminosity = "luminosity"

# CanvasElement "methods"
proc getContext2d*(c: CanvasElement): CanvasContext {.
  importcpp: "#.getContext('2d')", nodecl.}

{.push importcpp.}

# Drawing images
proc drawImage*(ctx: CanvasContext, image: ImageElement, dx, dy: int)
proc drawImage*(ctx: CanvasContext, image: CanvasElement, dx, dy: int)

# CanvasContext "methods"
# Drawing rectangles
proc clearRect*(ctx: CanvasContext, x, y, width, height: int)
proc fillRect*(ctx: CanvasContext, x, y, width, height: int)
proc strokeRect*(ctx: CanvasContext, x, y, width, height: int)

# Drawing text
proc fillText*(ctx: CanvasContext, text: cstring, x, y: int)
proc strokeText*(ctx: CanvasContext, text: cstring, x, y: int)

# Line styles
proc setLineDash*(ctx: CanvasContext, segments: seq[int])

# Paths
proc beginPath*(ctx: CanvasContext)
proc closePath*(ctx: CanvasContext)
proc moveTo*(ctx: CanvasContext, x, y: int)
proc lineTo*(ctx: CanvasContext, x, y: int)
proc bezierCurveTo*(ctx: CanvasContext, cp1x, cp1y, cp2x, cp2y, x, y: int)
proc quadraticCurveTo*(ctx: CanvasContext, cpx, cpy, x, y: int)
proc arc*(ctx: CanvasContext, x, y, radius: int, startAngle, endAngle: float)
proc arcTo*(ctx: CanvasContext, x1, y1, x2, y2, radius: int)
proc ellipse*(ctx: CanvasContext, x, y, radiusX, radiusY: int, rotation, startAngle, endAngle: float)
proc rect*(ctx: CanvasContext, x, y, width, height: int)

# Drawing paths
proc fill*(ctx: CanvasContext)
proc stroke*(ctx: CanvasContext)
proc clip*(ctx: CanvasContext)

{.pop.}
