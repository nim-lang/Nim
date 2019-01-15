discard """
action: compile
"""

import os
import sdl

if sdl.init(INIT_VIDEO) == -1:
  quit("Couldn't initialise SDL")

var window: SdlWindowPtr
var renderer: SdlRendererPtr
if createWindowAndRenderer(640, 480, 0, window, renderer) == -1:
  quit("Couldn't create a window or renderer")

discard pollEvent(nil)
renderer.setDrawColor 29, 64, 153, 255
renderer.clear
renderer.setDrawColor 255, 255, 255, 255
var points = [
  (260.cint, 320.cint),
  (260.cint, 110.cint),
  (360.cint, 320.cint),
  (360.cint, 110.cint)
]

renderer.drawLines(addr points[0], points.len.cint)

renderer.present
sleep(5000)
