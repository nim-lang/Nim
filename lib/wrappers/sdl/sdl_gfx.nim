
#
#  $Id: sdl_gfx.pas,v 1.3 2007/05/29 21:31:04 savage Exp $
#
#
#
#  $Log: sdl_gfx.pas,v $
#  Revision 1.3  2007/05/29 21:31:04  savage
#  Changes as suggested by Almindor for 64bit compatibility.
#
#  Revision 1.2  2007/05/20 20:30:18  savage
#  Initial Changes to Handle 64 Bits
#
#  Revision 1.1  2005/01/03 19:08:32  savage
#  Header for the SDL_Gfx library.
#
#
#
#

import
  sdl

when defined(windows):
  const SDLgfxLibName = "SDL_gfx.dll"
elif defined(macosx):
  const SDLgfxLibName = "libSDL_gfx.dylib"
else:
  const SDLgfxLibName = "libSDL_gfx.so"

const                         # Some rates in Hz
  FPS_UPPER_LIMIT* = 200
  FPS_LOWER_LIMIT* = 1
  FPS_DEFAULT* = 30           # ---- Defines
  SMOOTHING_OFF* = 0
  SMOOTHING_ON* = 1

type 
  PFPSmanager* = ptr TFPSmanager
  TFPSmanager*{.final.} = object  # ---- Structures
    framecount*: Uint32
    rateticks*: float32
    lastticks*: Uint32
    rate*: Uint32

  PColorRGBA* = ptr TColorRGBA
  TColorRGBA*{.final.} = object 
    r*: Uint8
    g*: Uint8
    b*: Uint8
    a*: Uint8

  PColorY* = ptr TColorY
  TColorY*{.final.} = object  #
                              #
                              # SDL_framerate: framerate manager
                              #
                              # LGPL (c) A. Schiffler
                              #
                              #
    y*: Uint8


proc SDL_initFramerate*(manager: PFPSmanager){.cdecl, importc, dynlib: SDLgfxLibName.}
proc SDL_setFramerate*(manager: PFPSmanager, rate: int): int{.cdecl, 
    importc, dynlib: SDLgfxLibName.}
proc SDL_getFramerate*(manager: PFPSmanager): int{.cdecl, importc, dynlib: SDLgfxLibName.}
proc SDL_framerateDelay*(manager: PFPSmanager){.cdecl, importc, dynlib: SDLgfxLibName.}
  #
  #
  # SDL_gfxPrimitives: graphics primitives for SDL
  #
  # LGPL (c) A. Schiffler
  #
  #
  # Note: all ___Color routines expect the color to be in format 0xRRGGBBAA 
  # Pixel 
proc pixelColor*(dst: PSDL_Surface, x: Sint16, y: Sint16, color: Uint32): int{.
    cdecl, importc, dynlib: SDLgfxLibName.}
proc pixelRGBA*(dst: PSDL_Surface, x: Sint16, y: Sint16, r: Uint8, g: Uint8, 
                b: Uint8, a: Uint8): int{.cdecl, importc, dynlib: SDLgfxLibName.}
  # Horizontal line 
proc hlineColor*(dst: PSDL_Surface, x1: Sint16, x2: Sint16, y: Sint16, 
                 color: Uint32): int{.cdecl, importc, dynlib: SDLgfxLibName.}
proc hlineRGBA*(dst: PSDL_Surface, x1: Sint16, x2: Sint16, y: Sint16, r: Uint8, 
                g: Uint8, b: Uint8, a: Uint8): int{.cdecl, importc, dynlib: SDLgfxLibName.}
  # Vertical line 
proc vlineColor*(dst: PSDL_Surface, x: Sint16, y1: Sint16, y2: Sint16, 
                 color: Uint32): int{.cdecl, importc, dynlib: SDLgfxLibName.}
proc vlineRGBA*(dst: PSDL_Surface, x: Sint16, y1: Sint16, y2: Sint16, r: Uint8, 
                g: Uint8, b: Uint8, a: Uint8): int{.cdecl, importc, dynlib: SDLgfxLibName.}
  # Rectangle 
proc rectangleColor*(dst: PSDL_Surface, x1: Sint16, y1: Sint16, x2: Sint16, 
                     y2: Sint16, color: Uint32): int{.cdecl, 
    importc, dynlib: SDLgfxLibName.}
proc rectangleRGBA*(dst: PSDL_Surface, x1: Sint16, y1: Sint16, x2: Sint16, 
                    y2: Sint16, r: Uint8, g: Uint8, b: Uint8, a: Uint8): int{.
    cdecl, importc, dynlib: SDLgfxLibName.}
  # Filled rectangle (Box) 
proc boxColor*(dst: PSDL_Surface, x1: Sint16, y1: Sint16, x2: Sint16, 
               y2: Sint16, color: Uint32): int{.cdecl, importc, dynlib: SDLgfxLibName.}
proc boxRGBA*(dst: PSDL_Surface, x1: Sint16, y1: Sint16, x2: Sint16, y2: Sint16, 
              r: Uint8, g: Uint8, b: Uint8, a: Uint8): int{.cdecl, 
    importc, dynlib: SDLgfxLibName.}
  # Line 
proc lineColor*(dst: PSDL_Surface, x1: Sint16, y1: Sint16, x2: Sint16, 
                y2: Sint16, color: Uint32): int{.cdecl, importc, dynlib: SDLgfxLibName.}
proc lineRGBA*(dst: PSDL_Surface, x1: Sint16, y1: Sint16, x2: Sint16, 
               y2: Sint16, r: Uint8, g: Uint8, b: Uint8, a: Uint8): int{.cdecl, 
    importc, dynlib: SDLgfxLibName.}
  # AA Line 
proc aalineColor*(dst: PSDL_Surface, x1: Sint16, y1: Sint16, x2: Sint16, 
                  y2: Sint16, color: Uint32): int{.cdecl, importc, dynlib: SDLgfxLibName.}
proc aalineRGBA*(dst: PSDL_Surface, x1: Sint16, y1: Sint16, x2: Sint16, 
                 y2: Sint16, r: Uint8, g: Uint8, b: Uint8, a: Uint8): int{.
    cdecl, importc, dynlib: SDLgfxLibName.}
  # Circle 
proc circleColor*(dst: PSDL_Surface, x: Sint16, y: Sint16, r: Sint16, 
                  color: Uint32): int{.cdecl, importc, dynlib: SDLgfxLibName.}
proc circleRGBA*(dst: PSDL_Surface, x: Sint16, y: Sint16, rad: Sint16, r: Uint8, 
                 g: Uint8, b: Uint8, a: Uint8): int{.cdecl, 
    importc, dynlib: SDLgfxLibName.}
  # AA Circle 
proc aacircleColor*(dst: PSDL_Surface, x: Sint16, y: Sint16, r: Sint16, 
                    color: Uint32): int{.cdecl, importc, dynlib: SDLgfxLibName.}
proc aacircleRGBA*(dst: PSDL_Surface, x: Sint16, y: Sint16, rad: Sint16, 
                   r: Uint8, g: Uint8, b: Uint8, a: Uint8): int{.cdecl, 
    importc, dynlib: SDLgfxLibName.}
  # Filled Circle 
proc filledCircleColor*(dst: PSDL_Surface, x: Sint16, y: Sint16, r: Sint16, 
                        color: Uint32): int{.cdecl, importc, dynlib: SDLgfxLibName.}
proc filledCircleRGBA*(dst: PSDL_Surface, x: Sint16, y: Sint16, rad: Sint16, 
                       r: Uint8, g: Uint8, b: Uint8, a: Uint8): int{.cdecl, 
    importc, dynlib: SDLgfxLibName.}
  # Ellipse 
proc ellipseColor*(dst: PSDL_Surface, x: Sint16, y: Sint16, rx: Sint16, 
                   ry: Sint16, color: Uint32): int{.cdecl, importc, dynlib: SDLgfxLibName.}
proc ellipseRGBA*(dst: PSDL_Surface, x: Sint16, y: Sint16, rx: Sint16, 
                  ry: Sint16, r: Uint8, g: Uint8, b: Uint8, a: Uint8): int{.
    cdecl, importc, dynlib: SDLgfxLibName.}
  # AA Ellipse 
proc aaellipseColor*(dst: PSDL_Surface, xc: Sint16, yc: Sint16, rx: Sint16, 
                     ry: Sint16, color: Uint32): int{.cdecl, 
    importc, dynlib: SDLgfxLibName.}
proc aaellipseRGBA*(dst: PSDL_Surface, x: Sint16, y: Sint16, rx: Sint16, 
                    ry: Sint16, r: Uint8, g: Uint8, b: Uint8, a: Uint8): int{.
    cdecl, importc, dynlib: SDLgfxLibName.}
  # Filled Ellipse 
proc filledEllipseColor*(dst: PSDL_Surface, x: Sint16, y: Sint16, rx: Sint16, 
                         ry: Sint16, color: Uint32): int{.cdecl, 
    importc, dynlib: SDLgfxLibName.}
proc filledEllipseRGBA*(dst: PSDL_Surface, x: Sint16, y: Sint16, rx: Sint16, 
                        ry: Sint16, r: Uint8, g: Uint8, b: Uint8, a: Uint8): int{.
    cdecl, importc, dynlib: SDLgfxLibName.}
  # Pie
proc pieColor*(dst: PSDL_Surface, x: Sint16, y: Sint16, rad: Sint16, 
               start: Sint16, finish: Sint16, color: Uint32): int{.cdecl, 
    importc, dynlib: SDLgfxLibName.}
proc pieRGBA*(dst: PSDL_Surface, x: Sint16, y: Sint16, rad: Sint16, 
              start: Sint16, finish: Sint16, r: Uint8, g: Uint8, b: Uint8, 
              a: Uint8): int{.cdecl, importc, dynlib: SDLgfxLibName.}
  # Filled Pie
proc filledPieColor*(dst: PSDL_Surface, x: Sint16, y: Sint16, rad: Sint16, 
                     start: Sint16, finish: Sint16, color: Uint32): int{.cdecl, 
    importc, dynlib: SDLgfxLibName.}
proc filledPieRGBA*(dst: PSDL_Surface, x: Sint16, y: Sint16, rad: Sint16, 
                    start: Sint16, finish: Sint16, r: Uint8, g: Uint8, b: Uint8, 
                    a: Uint8): int{.cdecl, importc, dynlib: SDLgfxLibName.}
  # Trigon
proc trigonColor*(dst: PSDL_Surface, x1: Sint16, y1: Sint16, x2: Sint16, 
                  y2: Sint16, x3: Sint16, y3: Sint16, color: Uint32): int{.
    cdecl, importc, dynlib: SDLgfxLibName.}
proc trigonRGBA*(dst: PSDL_Surface, x1: Sint16, y1: Sint16, x2: Sint16, 
                 y2: Sint16, x3: Sint16, y3: Sint16, r: Uint8, g: Uint8, 
                 b: Uint8, a: Uint8): int{.cdecl, importc, dynlib: SDLgfxLibName.}
  # AA-Trigon
proc aatrigonColor*(dst: PSDL_Surface, x1: Sint16, y1: Sint16, x2: Sint16, 
                    y2: Sint16, x3: Sint16, y3: Sint16, color: Uint32): int{.
    cdecl, importc, dynlib: SDLgfxLibName.}
proc aatrigonRGBA*(dst: PSDL_Surface, x1: Sint16, y1: Sint16, x2: Sint16, 
                   y2: Sint16, x3: Sint16, y3: Sint16, r: Uint8, g: Uint8, 
                   b: Uint8, a: Uint8): int{.cdecl, importc, dynlib: SDLgfxLibName.}
  # Filled Trigon
proc filledTrigonColor*(dst: PSDL_Surface, x1: Sint16, y1: Sint16, x2: Sint16, 
                        y2: Sint16, x3: Sint16, y3: Sint16, color: Uint32): int{.
    cdecl, importc, dynlib: SDLgfxLibName.}
proc filledTrigonRGBA*(dst: PSDL_Surface, x1: Sint16, y1: Sint16, x2: Sint16, 
                       y2: Sint16, x3: Sint16, y3: Sint16, r: Uint8, g: Uint8, 
                       b: Uint8, a: Uint8): int{.cdecl, importc, dynlib: SDLgfxLibName.}
  # Polygon
proc polygonColor*(dst: PSDL_Surface, vx: PSint16, vy: PSint16, n: int, 
                   color: Uint32): int{.cdecl, importc, dynlib: SDLgfxLibName.}
proc polygonRGBA*(dst: PSDL_Surface, vx: PSint16, vy: PSint16, n: int, r: Uint8, 
                  g: Uint8, b: Uint8, a: Uint8): int{.cdecl, 
    importc, dynlib: SDLgfxLibName.}
  # AA-Polygon
proc aapolygonColor*(dst: PSDL_Surface, vx: PSint16, vy: PSint16, n: int, 
                     color: Uint32): int{.cdecl, importc, dynlib: SDLgfxLibName.}
proc aapolygonRGBA*(dst: PSDL_Surface, vx: PSint16, vy: PSint16, n: int, 
                    r: Uint8, g: Uint8, b: Uint8, a: Uint8): int{.cdecl, 
    importc, dynlib: SDLgfxLibName.}
  # Filled Polygon
proc filledPolygonColor*(dst: PSDL_Surface, vx: PSint16, vy: PSint16, n: int, 
                         color: Uint32): int{.cdecl, importc, dynlib: SDLgfxLibName.}
proc filledPolygonRGBA*(dst: PSDL_Surface, vx: PSint16, vy: PSint16, n: int, 
                        r: Uint8, g: Uint8, b: Uint8, a: Uint8): int{.cdecl, 
    importc, dynlib: SDLgfxLibName.}
  # Bezier
  # s = number of steps
proc bezierColor*(dst: PSDL_Surface, vx: PSint16, vy: PSint16, n: int, s: int, 
                  color: Uint32): int{.cdecl, importc, dynlib: SDLgfxLibName.}
proc bezierRGBA*(dst: PSDL_Surface, vx: PSint16, vy: PSint16, n: int, s: int, 
                 r: Uint8, g: Uint8, b: Uint8, a: Uint8): int{.cdecl, 
    importc, dynlib: SDLgfxLibName.}
  # Characters/Strings
proc characterColor*(dst: PSDL_Surface, x: Sint16, y: Sint16, c: char, 
                     color: Uint32): int{.cdecl, importc, dynlib: SDLgfxLibName.}
proc characterRGBA*(dst: PSDL_Surface, x: Sint16, y: Sint16, c: char, r: Uint8, 
                    g: Uint8, b: Uint8, a: Uint8): int{.cdecl, 
    importc, dynlib: SDLgfxLibName.}
proc stringColor*(dst: PSDL_Surface, x: Sint16, y: Sint16, c: cstring, 
                  color: Uint32): int{.cdecl, importc, dynlib: SDLgfxLibName.}
proc stringRGBA*(dst: PSDL_Surface, x: Sint16, y: Sint16, c: cstring, r: Uint8, 
                 g: Uint8, b: Uint8, a: Uint8): int{.cdecl, 
    importc, dynlib: SDLgfxLibName.}
proc gfxPrimitivesSetFont*(fontdata: Pointer, cw: int, ch: int){.cdecl, 
    importc, dynlib: SDLgfxLibName.}
  #
  #
  # SDL_imageFilter - bytes-image "filter" routines
  # (uses inline x86 MMX optimizations if available)
  #
  # LGPL (c) A. Schiffler
  #
  #
  # Comments:                                                                           
  #  1.) MMX functions work best if all data blocks are aligned on a 32 bytes boundary. 
  #  2.) Data that is not within an 8 byte boundary is processed using the C routine.   
  #  3.) Convolution routines do not have C routines at this time.                      
  # Detect MMX capability in CPU
proc SDL_imageFilterMMXdetect*(): int{.cdecl, importc, dynlib: SDLgfxLibName.}
  # Force use of MMX off (or turn possible use back on)
proc SDL_imageFilterMMXoff*(){.cdecl, importc, dynlib: SDLgfxLibName.}
proc SDL_imageFilterMMXon*(){.cdecl, importc, dynlib: SDLgfxLibName.}
  #
  # All routines return:
  #   0   OK
  #  -1   Error (internal error, parameter error)
  #
  #  SDL_imageFilterAdd: D = saturation255(S1 + S2)
proc SDL_imageFilterAdd*(Src1: cstring, Src2: cstring, Dest: cstring, len: int): int{.
    cdecl, importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterMean: D = S1/2 + S2/2
proc SDL_imageFilterMean*(Src1: cstring, Src2: cstring, Dest: cstring, len: int): int{.
    cdecl, importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterSub: D = saturation0(S1 - S2)
proc SDL_imageFilterSub*(Src1: cstring, Src2: cstring, Dest: cstring, len: int): int{.
    cdecl, importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterAbsDiff: D = | S1 - S2 |
proc SDL_imageFilterAbsDiff*(Src1: cstring, Src2: cstring, Dest: cstring, 
                             len: int): int{.cdecl, importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterMult: D = saturation(S1 * S2)
proc SDL_imageFilterMult*(Src1: cstring, Src2: cstring, Dest: cstring, len: int): int{.
    cdecl, importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterMultNor: D = S1 * S2   (non-MMX)
proc SDL_imageFilterMultNor*(Src1: cstring, Src2: cstring, Dest: cstring, 
                             len: int): int{.cdecl, importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterMultDivby2: D = saturation255(S1/2 * S2)
proc SDL_imageFilterMultDivby2*(Src1: cstring, Src2: cstring, Dest: cstring, 
                                len: int): int{.cdecl, importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterMultDivby4: D = saturation255(S1/2 * S2/2)
proc SDL_imageFilterMultDivby4*(Src1: cstring, Src2: cstring, Dest: cstring, 
                                len: int): int{.cdecl, importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterBitAnd: D = S1 & S2
proc SDL_imageFilterBitAnd*(Src1: cstring, Src2: cstring, Dest: cstring, 
                            len: int): int{.cdecl, importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterBitOr: D = S1 | S2
proc SDL_imageFilterBitOr*(Src1: cstring, Src2: cstring, Dest: cstring, len: int): int{.
    cdecl, importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterDiv: D = S1 / S2   (non-MMX)
proc SDL_imageFilterDiv*(Src1: cstring, Src2: cstring, Dest: cstring, len: int): int{.
    cdecl, importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterBitNegation: D = !S
proc SDL_imageFilterBitNegation*(Src1: cstring, Dest: cstring, len: int): int{.
    cdecl, importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterAddByte: D = saturation255(S + C)
proc SDL_imageFilterAddByte*(Src1: cstring, Dest: cstring, len: int, C: char): int{.
    cdecl, importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterAddUint: D = saturation255(S + (uint)C)
proc SDL_imageFilterAddUint*(Src1: cstring, Dest: cstring, len: int, C: int): int{.
    cdecl, importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterAddByteToHalf: D = saturation255(S/2 + C)
proc SDL_imageFilterAddByteToHalf*(Src1: cstring, Dest: cstring, len: int, 
                                   C: char): int{.cdecl, importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterSubByte: D = saturation0(S - C)
proc SDL_imageFilterSubByte*(Src1: cstring, Dest: cstring, len: int, C: char): int{.
    cdecl, importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterSubUint: D = saturation0(S - (uint)C)
proc SDL_imageFilterSubUint*(Src1: cstring, Dest: cstring, len: int, C: int): int{.
    cdecl, importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterShiftRight: D = saturation0(S >> N)
proc SDL_imageFilterShiftRight*(Src1: cstring, Dest: cstring, len: int, N: char): int{.
    cdecl, importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterShiftRightUint: D = saturation0((uint)S >> N)
proc SDL_imageFilterShiftRightUint*(Src1: cstring, Dest: cstring, len: int, 
                                    N: char): int{.cdecl, importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterMultByByte: D = saturation255(S * C)
proc SDL_imageFilterMultByByte*(Src1: cstring, Dest: cstring, len: int, C: char): int{.
    cdecl, importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterShiftRightAndMultByByte: D = saturation255((S >> N) * C)
proc SDL_imageFilterShiftRightAndMultByByte*(Src1: cstring, Dest: cstring, 
    len: int, N: char, C: char): int{.cdecl, importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterShiftLeftByte: D = (S << N)
proc SDL_imageFilterShiftLeftByte*(Src1: cstring, Dest: cstring, len: int, 
                                   N: char): int{.cdecl, importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterShiftLeftUint: D = ((uint)S << N)
proc SDL_imageFilterShiftLeftUint*(Src1: cstring, Dest: cstring, len: int, 
                                   N: char): int{.cdecl, importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterShiftLeft: D = saturation255(S << N)
proc SDL_imageFilterShiftLeft*(Src1: cstring, Dest: cstring, len: int, N: char): int{.
    cdecl, importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterBinarizeUsingThreshold: D = S >= T ? 255:0
proc SDL_imageFilterBinarizeUsingThreshold*(Src1: cstring, Dest: cstring, 
    len: int, T: char): int{.cdecl, importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterClipToRange: D = (S >= Tmin) & (S <= Tmax) 255:0
proc SDL_imageFilterClipToRange*(Src1: cstring, Dest: cstring, len: int, 
                                 Tmin: int8, Tmax: int8): int{.cdecl, 
    importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterNormalizeLinear: D = saturation255((Nmax - Nmin)/(Cmax - Cmin)*(S - Cmin) + Nmin)
proc SDL_imageFilterNormalizeLinear*(Src1: cstring, Dest: cstring, len: int, 
                                     Cmin: int, Cmax: int, Nmin: int, Nmax: int): int{.
    cdecl, importc, dynlib: SDLgfxLibName.}
  # !!! NO C-ROUTINE FOR THESE FUNCTIONS YET !!! 
  #  SDL_imageFilterConvolveKernel3x3Divide: Dij = saturation0and255( ... )
proc SDL_imageFilterConvolveKernel3x3Divide*(Src: cstring, Dest: cstring, 
    rows: int, columns: int, Kernel: PShortInt, Divisor: int8): int{.cdecl, 
    importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterConvolveKernel5x5Divide: Dij = saturation0and255( ... )
proc SDL_imageFilterConvolveKernel5x5Divide*(Src: cstring, Dest: cstring, 
    rows: int, columns: int, Kernel: PShortInt, Divisor: int8): int{.cdecl, 
    importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterConvolveKernel7x7Divide: Dij = saturation0and255( ... )
proc SDL_imageFilterConvolveKernel7x7Divide*(Src: cstring, Dest: cstring, 
    rows: int, columns: int, Kernel: PShortInt, Divisor: int8): int{.cdecl, 
    importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterConvolveKernel9x9Divide: Dij = saturation0and255( ... )
proc SDL_imageFilterConvolveKernel9x9Divide*(Src: cstring, Dest: cstring, 
    rows: int, columns: int, Kernel: PShortInt, Divisor: int8): int{.cdecl, 
    importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterConvolveKernel3x3ShiftRight: Dij = saturation0and255( ... )
proc SDL_imageFilterConvolveKernel3x3ShiftRight*(Src: cstring, Dest: cstring, 
    rows: int, columns: int, Kernel: PShortInt, NRightShift: char): int{.cdecl, 
    importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterConvolveKernel5x5ShiftRight: Dij = saturation0and255( ... )
proc SDL_imageFilterConvolveKernel5x5ShiftRight*(Src: cstring, Dest: cstring, 
    rows: int, columns: int, Kernel: PShortInt, NRightShift: char): int{.cdecl, 
    importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterConvolveKernel7x7ShiftRight: Dij = saturation0and255( ... )
proc SDL_imageFilterConvolveKernel7x7ShiftRight*(Src: cstring, Dest: cstring, 
    rows: int, columns: int, Kernel: PShortInt, NRightShift: char): int{.cdecl, 
    importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterConvolveKernel9x9ShiftRight: Dij = saturation0and255( ... )
proc SDL_imageFilterConvolveKernel9x9ShiftRight*(Src: cstring, Dest: cstring, 
    rows: int, columns: int, Kernel: PShortInt, NRightShift: char): int{.cdecl, 
    importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterSobelX: Dij = saturation255( ... )
proc SDL_imageFilterSobelX*(Src: cstring, Dest: cstring, rows: int, columns: int): int{.
    cdecl, importc, dynlib: SDLgfxLibName.}
  #  SDL_imageFilterSobelXShiftRight: Dij = saturation255( ... )
proc SDL_imageFilterSobelXShiftRight*(Src: cstring, Dest: cstring, rows: int, 
                                      columns: int, NRightShift: char): int{.
    cdecl, importc, dynlib: SDLgfxLibName.}
  # Align/restore stack to 32 byte boundary -- Functionality untested! --
proc SDL_imageFilterAlignStack*(){.cdecl, importc, dynlib: SDLgfxLibName.}
proc SDL_imageFilterRestoreStack*(){.cdecl, importc, dynlib: SDLgfxLibName.}
  #
  #
  # SDL_rotozoom - rotozoomer
  #
  # LGPL (c) A. Schiffler
  #
  #
  # 
  # 
  # rotozoomSurface()
  #
  # Rotates and zoomes a 32bit or 8bit 'src' surface to newly created 'dst' surface.
  # 'angle' is the rotation in degrees. 'zoom' a scaling factor. If 'smooth' is 1
  # then the destination 32bit surface is anti-aliased. If the surface is not 8bit
  # or 32bit RGBA/ABGR it will be converted into a 32bit RGBA format on the fly.
  #
  #
proc rotozoomSurface*(src: PSDL_Surface, angle: float64, zoom: float64, 
                      smooth: int): PSDL_Surface{.cdecl, importc, dynlib: SDLgfxLibName.}
proc rotozoomSurfaceXY*(src: PSDL_Surface, angle: float64, zoomx: float64, 
                        zoomy: float64, smooth: int): PSDL_Surface{.cdecl, 
    importc, dynlib: SDLgfxLibName.}
  # Returns the size of the target surface for a rotozoomSurface() call 
proc rotozoomSurfaceSize*(width: int, height: int, angle: float64, 
                          zoom: float64, dstwidth: var int, dstheight: var int){.
    cdecl, importc, dynlib: SDLgfxLibName.}
proc rotozoomSurfaceSizeXY*(width: int, height: int, angle: float64, 
                            zoomx: float64, zoomy: float64, dstwidth: var int, 
                            dstheight: var int){.cdecl, importc, dynlib: SDLgfxLibName.}
  #
  #
  # zoomSurface()
  #
  # Zoomes a 32bit or 8bit 'src' surface to newly created 'dst' surface.
  # 'zoomx' and 'zoomy' are scaling factors for width and height. If 'smooth' is 1
  # then the destination 32bit surface is anti-aliased. If the surface is not 8bit
  # or 32bit RGBA/ABGR it will be converted into a 32bit RGBA format on the fly.
  #
  #
proc zoomSurface*(src: PSDL_Surface, zoomx: float64, zoomy: float64, smooth: int): PSDL_Surface{.
    cdecl, importc, dynlib: SDLgfxLibName.}
  # Returns the size of the target surface for a zoomSurface() call 
proc zoomSurfaceSize*(width: int, height: int, zoomx: float64, zoomy: float64, 
                      dstwidth: var int, dstheight: var int){.cdecl, 
    importc, dynlib: SDLgfxLibName.}
# implementation
