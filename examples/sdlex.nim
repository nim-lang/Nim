# Test the SDL interface:

import
  SDL

var
  screen, greeting: PSurface
  r: TRect

if Init(INIT_VIDEO) == 0:
  screen = SetVideoMode(640, 480, 16, SWSURFACE or ANYFORMAT)
  if screen == nil:
    write(stdout, "screen is nil!\n")
  else:
    greeting = LoadBmp("backgrnd.bmp")
    if greeting == nil:
      write(stdout, "greeting is nil!")
    r.x = 0'i16
    r.y = 0'i16
    discard blitSurface(greeting, nil, screen, addr(r))
    discard flip(screen)
    Delay(3000)
else:
  write(stdout, "SDL_Init failed!\n")

sdl.Quit()
