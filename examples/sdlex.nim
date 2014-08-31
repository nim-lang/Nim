# Test the SDL interface:

import
  sdl, sdl_image, colors

var
  screen, greeting: PSurface
  r: TRect
  event: TEvent
  bgColor = colChocolate.int32

if Init(INIT_VIDEO) != 0:
  quit "SDL failed to initialize!"

screen = SetVideoMode(640, 480, 16, SWSURFACE or ANYFORMAT)
if screen.isNil:
  quit($sdl.GetError())

greeting = IMG_load("tux.png")
if greeting.isNil:
  echo "Failed to load tux.png"
else:
  ## convert the image to alpha and free the old one
  var s = greeting.DisplayFormatAlpha()
  swap(greeting, s)
  s.FreeSurface()

r.x = 0
r.y = 0

block game_loop:
  while true:
    
    while PollEvent(addr event) > 0:
      case event.kind
      of QUITEV:
        break game_loop
      of KEYDOWN:
        if EvKeyboard(addr event).keysym.sym == K_ESCAPE:
          break game_loop
      else:
        discard
    
    discard FillRect(screen, nil, bgColor) 
    discard BlitSurface(greeting, nil, screen, addr r)
    discard Flip(screen)

greeting.FreeSurface()
screen.FreeSurface()
sdl.Quit()

## fowl wuz here 10/2012