#
# Translation of cairo-xlib.h version 1.4
# by Jeffrey Pohlmeyer 
# updated to version 1.4 by Luiz Américo Pereira Câmara 2007
#

import 
  cairo, x, xlib, xrender

include "cairo_pragma.nim"

proc xlib_surface_create*(dpy: PDisplay, drawable: TDrawable, visual: PVisual, 
                          width, height: int32): PSurface{.cdecl, 
    importc: "cairo_xlib_surface_create", libcairo.}
proc xlib_surface_create_for_bitmap*(dpy: PDisplay, bitmap: TPixmap, 
                                     screen: PScreen, width, height: int32): PSurface{.
    cdecl, importc: "cairo_xlib_surface_create_for_bitmap", libcairo.}
proc xlib_surface_create_with_xrender_format*(dpy: PDisplay, 
    drawable: TDrawable, screen: PScreen, format: PXRenderPictFormat, 
    width, height: int32): PSurface{.cdecl, importc: "cairo_xlib_surface_create_with_xrender_format", 
                                     libcairo.}
proc xlib_surface_get_depth*(surface: PSurface): int32{.cdecl, 
    importc: "cairo_xlib_surface_get_depth", libcairo.}
proc xlib_surface_get_display*(surface: PSurface): PDisplay{.cdecl, 
    importc: "cairo_xlib_surface_get_display", libcairo.}
proc xlib_surface_get_drawable*(surface: PSurface): TDrawable{.cdecl, 
    importc: "cairo_xlib_surface_get_drawable", libcairo.}
proc xlib_surface_get_height*(surface: PSurface): int32{.cdecl, 
    importc: "cairo_xlib_surface_get_height", libcairo.}
proc xlib_surface_get_screen*(surface: PSurface): PScreen{.cdecl, 
    importc: "cairo_xlib_surface_get_screen", libcairo.}
proc xlib_surface_get_visual*(surface: PSurface): PVisual{.cdecl, 
    importc: "cairo_xlib_surface_get_visual", libcairo.}
proc xlib_surface_get_width*(surface: PSurface): int32{.cdecl, 
    importc: "cairo_xlib_surface_get_width", libcairo.}
proc xlib_surface_set_size*(surface: PSurface, width, height: int32){.cdecl, 
    importc: "cairo_xlib_surface_set_size", libcairo.}
proc xlib_surface_set_drawable*(surface: PSurface, drawable: TDrawable, 
                                width, height: int32){.cdecl, 
    importc: "cairo_xlib_surface_set_drawable", libcairo.}
# implementation
