when defined(windows):
  const libName* = "SDL2.dll"
elif defined(linux) or defined(freebsd) or defined(netbsd):
  const libName* = "libSDL2.so"
elif defined(macosx):
  const libName* = "libSDL2.dylib"
elif defined(openbsd):
  const libName* = "libSDL2.so.0.6"
else:
  {.error: "SDL library name not set for this platform".}

type
  SdlWindow = object
  SdlWindowPtr* = ptr SdlWindow
  SdlRenderer = object
  SdlRendererPtr* = ptr SdlRenderer

const INIT_VIDEO* = 0x00000020

{.push dynlib: libName.}
proc init*(flags: uint32): cint {.importc: "SDL_Init".}

proc createWindowAndRenderer*(width, height: cint, window_flags: cuint,
    window: var SdlWindowPtr, renderer: var SdlRendererPtr): cint
    {.importc: "SDL_CreateWindowAndRenderer".}

proc pollEvent*(event: pointer): cint {.importc: "SDL_PollEvent".}

proc setDrawColor*(renderer: SdlRendererPtr, r, g, b, a: uint8): cint
    {.importc: "SDL_SetRenderDrawColor", discardable.}

proc present*(renderer: SdlRendererPtr) {.importc: "SDL_RenderPresent".}

proc clear*(renderer: SdlRendererPtr) {.importc: "SDL_RenderClear".}

proc drawLines*(renderer: SdlRendererPtr, points: ptr tuple[x, y: cint],
    count: cint): cint {.importc: "SDL_RenderDrawLines", discardable.}
{.pop.}
