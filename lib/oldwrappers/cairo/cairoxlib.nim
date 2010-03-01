
#
# Translation of cairo-xlib.h version 1.4
# by Jeffrey Pohlmeyer 
# updated to version 1.4 by Luiz Américo Pereira Câmara 2007
#

import 
  Cairo, x, xlib, xrender

proc cairo_xlib_surface_create*(dpy: PDisplay, drawable: TDrawable, 
                                visual: PVisual, width, height: int32): PCairoSurface{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_xlib_surface_create_for_bitmap*(dpy: PDisplay, bitmap: TPixmap, 
    screen: PScreen, width, height: int32): PCairoSurface{.cdecl, importc, 
    dynlib: LIB_CAIRO.}
proc cairo_xlib_surface_create_with_xrender_format*(dpy: PDisplay, 
    drawable: TDrawable, screen: PScreen, format: PXRenderPictFormat, 
    width, height: int32): PCairoSurface{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_xlib_surface_get_depth*(surface: PCairoSurface): int32{.cdecl, importc, 
    dynlib: LIB_CAIRO.}
proc cairo_xlib_surface_get_display*(surface: PCairoSurface): PDisplay{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_xlib_surface_get_drawable*(surface: PCairoSurface): TDrawable{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_xlib_surface_get_height*(surface: PCairoSurface): int32{.cdecl, importc, 
    dynlib: LIB_CAIRO.}
proc cairo_xlib_surface_get_screen*(surface: PCairoSurface): PScreen{.cdecl, importc, 
    dynlib: LIB_CAIRO.}
proc cairo_xlib_surface_get_visual*(surface: PCairoSurface): PVisual{.cdecl, importc, 
    dynlib: LIB_CAIRO.}
proc cairo_xlib_surface_get_width*(surface: PCairoSurface): int32{.cdecl, importc, 
    dynlib: LIB_CAIRO.}
proc cairo_xlib_surface_set_size*(surface: PCairoSurface, 
                                  width, height: int32){.cdecl, importc, 
    dynlib: LIB_CAIRO.}
proc cairo_xlib_surface_set_drawable*(surface: PCairoSurface, 
                                      drawable: TDrawable, width, height: int32){.
    cdecl, importc, dynlib: LIB_CAIRO.}
# implementation
