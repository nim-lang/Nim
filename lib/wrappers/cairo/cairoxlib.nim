#
# Translation of cairo-xlib.h version 1.4
# by Jeffrey Pohlmeyer 
# updated to version 1.4 by Luiz Américo Pereira Câmara 2007
#

import 
  cairo, x, xlib, xrender

proc xlib_surface_create*(dpy: PDisplay, drawable: TDrawable, visual: PVisual, 
                          width, height: int32): PSurface{.cdecl, 
    importc: "cairo_xlib_surface_create", dynlib: LIB_CAIRO.}
proc xlib_surface_create_for_bitmap*(dpy: PDisplay, bitmap: TPixmap, 
                                     screen: PScreen, width, height: int32): PSurface{.
    cdecl, importc: "cairo_xlib_surface_create_for_bitmap", dynlib: LIB_CAIRO.}
proc xlib_surface_create_with_xrender_format*(dpy: PDisplay, 
    drawable: TDrawable, screen: PScreen, format: PXRenderPictFormat, 
    width, height: int32): PSurface{.cdecl, importc: "cairo_xlib_surface_create_with_xrender_format", 
                                     dynlib: LIB_CAIRO.}
proc xlib_surface_get_depth*(surface: PSurface): int32{.cdecl, 
    importc: "cairo_xlib_surface_get_depth", dynlib: LIB_CAIRO.}
proc xlib_surface_get_display*(surface: PSurface): PDisplay{.cdecl, 
    importc: "cairo_xlib_surface_get_display", dynlib: LIB_CAIRO.}
proc xlib_surface_get_drawable*(surface: PSurface): TDrawable{.cdecl, 
    importc: "cairo_xlib_surface_get_drawable", dynlib: LIB_CAIRO.}
proc xlib_surface_get_height*(surface: PSurface): int32{.cdecl, 
    importc: "cairo_xlib_surface_get_height", dynlib: LIB_CAIRO.}
proc xlib_surface_get_screen*(surface: PSurface): PScreen{.cdecl, 
    importc: "cairo_xlib_surface_get_screen", dynlib: LIB_CAIRO.}
proc xlib_surface_get_visual*(surface: PSurface): PVisual{.cdecl, 
    importc: "cairo_xlib_surface_get_visual", dynlib: LIB_CAIRO.}
proc xlib_surface_get_width*(surface: PSurface): int32{.cdecl, 
    importc: "cairo_xlib_surface_get_width", dynlib: LIB_CAIRO.}
proc xlib_surface_set_size*(surface: PSurface, width, height: int32){.cdecl, 
    importc: "cairo_xlib_surface_set_size", dynlib: LIB_CAIRO.}
proc xlib_surface_set_drawable*(surface: PSurface, drawable: TDrawable, 
                                width, height: int32){.cdecl, 
    importc: "cairo_xlib_surface_set_drawable", dynlib: LIB_CAIRO.}
# implementation
