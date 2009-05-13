# Test the SDL interface:

import
  SDL

var
  screen, greeting: PSDL_Surface
  r: TSDL_Rect

if SDL_Init(SDL_INIT_VIDEO) == 0:
  screen = SDL_SetVideoMode(640, 480, 16, SDL_SWSURFACE or SDL_ANYFORMAT)
  if screen == nil:
    write(stdout, "screen is nil!\n")
  else:
    greeting = SDL_LoadBmp("backgrnd.bmp")
    if greeting == nil:
      write(stdout, "greeting is nil!")
    r.x = 0'i16
    r.y = 0'i16
    discard SDL_blitSurface(greeting, nil, screen, addr(r))
    discard SDL_flip(screen)
    SDL_Delay(3000)
else:
  write(stdout, "SDL_Init failed!\n")

SDL_Quit()
