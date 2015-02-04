# Test the SDL interface:

import
  sdl, sdl_image, colors

var
  screen, greeting: PSurface
  r: TRect
  event: TEvent
  bgColor = colChocolate.int32

if init(INIT_VIDEO) != 0:
  quit "SDL failed to initialize!"

screen = setVideoMode(640, 480, 16, SWSURFACE or ANYFORMAT)
if screen.isNil:
  quit($sdl.getError())

greeting = imgLoad("tux.png")
if greeting.isNil:
  echo "Failed to load tux.png"
else:
  ## convert the image to alpha and free the old one
  var s = greeting.displayFormatAlpha()
  swap(greeting, s)
  s.freeSurface()

r.x = 0
r.y = 0

block game_loop:
  while true:

    while pollEvent(addr event) > 0:
      case event.kind
      of QUITEV:
        break game_loop
      of KEYDOWN:
        if evKeyboard(addr event).keysym.sym == K_ESCAPE:
          break game_loop
      else:
        discard

    discard fillRect(screen, nil, bgColor)
    discard blitSurface(greeting, nil, screen, addr r)
    discard flip(screen)

greeting.freeSurface()
screen.freeSurface()
sdl.quit()

## fowl wuz here 10/2012