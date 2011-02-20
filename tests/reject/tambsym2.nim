discard """
  file: "tambsym2.nim"
  line: 9
  errormsg: "undeclared identifier: \'CreateRGBSurface\'"
"""

from sdl import PSurface

discard SDL.CreateRGBSurface(SDL.SWSURFACE, 23, 34, 
      32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xff000000'i32)



