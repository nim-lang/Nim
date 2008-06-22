
#
# Translation of cairo-xlib.h version 1.4
# by Jeffrey Pohlmeyer 
# updated to version 1.4 by Luiz Américo Pereira Câmara 2007
#

import 
  Cairo, x, xlib, xrender

proc cairo_xlib_surface_create*(dpy: PDisplay, drawable: TDrawable, 
                                visual: PVisual, width, height: int32): Pcairo_surface_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_xlib_surface_create_for_bitmap*(dpy: PDisplay, bitmap: TPixmap, 
    screen: PScreen, width, height: int32): Pcairo_surface_t{.cdecl, importc, 
    dynlib: LIB_CAIRO.}
proc cairo_xlib_surface_create_with_xrender_format*(dpy: PDisplay, 
    drawable: TDrawable, screen: PScreen, format: PXRenderPictFormat, 
    width, height: int32): Pcairo_surface_t{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_xlib_surface_get_depth*(surface: Pcairo_surface_t): int32{.cdecl, importc, 
    dynlib: LIB_CAIRO.}
proc cairo_xlib_surface_get_display*(surface: Pcairo_surface_t): PDisplay{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_xlib_surface_get_drawable*(surface: Pcairo_surface_t): TDrawable{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_xlib_surface_get_height*(surface: Pcairo_surface_t): int32{.cdecl, importc, 
    dynlib: LIB_CAIRO.}
proc cairo_xlib_surface_get_screen*(surface: Pcairo_surface_t): PScreen{.cdecl, importc, 
    dynlib: LIB_CAIRO.}
proc cairo_xlib_surface_get_visual*(surface: Pcairo_surface_t): PVisual{.cdecl, importc, 
    dynlib: LIB_CAIRO.}
proc cairo_xlib_surface_get_width*(surface: Pcairo_surface_t): int32{.cdecl, importc, 
    dynlib: LIB_CAIRO.}
proc cairo_xlib_surface_set_size*(surface: Pcairo_surface_t, 
                                  width, height: int32){.cdecl, importc, 
    dynlib: LIB_CAIRO.}
proc cairo_xlib_surface_set_drawable*(surface: Pcairo_surface_t, 
                                      drawable: TDrawable, width, height: int32){.
    cdecl, importc, dynlib: LIB_CAIRO.}
# implementation
