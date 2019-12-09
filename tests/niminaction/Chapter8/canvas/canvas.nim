discard """
action: compile
"""

import dom

type
  CanvasRenderingContext* = ref object
    fillStyle* {.importc.}: cstring
    strokeStyle* {.importc.}: cstring

{.push importcpp.}

proc getContext*(canvasElement: Element,
    contextType: cstring): CanvasRenderingContext

proc fillRect*(context: CanvasRenderingContext, x, y, width, height: int)

proc moveTo*(context: CanvasRenderingContext, x, y: int)

proc lineTo*(context: CanvasRenderingContext, x, y: int)

proc stroke*(context: CanvasRenderingContext)
