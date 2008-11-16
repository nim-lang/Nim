
#
# Translation of cairo-win32.h version 1.4
# by Luiz Américo Pereira Câmara 2007
#

import 
  Cairo, windows

proc cairo_win32_surface_create*(hdc: HDC): PCairoSurface{.cdecl, importc, 
    dynlib: LIB_CAIRO.}
proc cairo_win32_surface_create_with_ddb*(hdc: HDC, format: TCairoFormat, 
    width, height: int32): PCairoSurface{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_win32_surface_create_with_dib*(format: TCairoFormat, 
    width, height: int32): PCairoSurface{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_win32_surface_get_dc*(surface: PCairoSurface): HDC{.cdecl, importc, 
    dynlib: LIB_CAIRO.}
proc cairo_win32_surface_get_image*(surface: PCairoSurface): PCairoSurface{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_win32_font_face_create_for_logfontw*(logfont: pLOGFONTW): PCairoFontFace{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_win32_font_face_create_for_hfont*(font: HFONT): PCairoFontFace{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_win32_scaled_font_select_font*(scaled_font: PCairoScaledFont, 
    hdc: HDC): TCairoStatus{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_win32_scaled_font_done_font*(scaled_font: PCairoScaledFont){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_win32_scaled_font_get_metrics_factor*(
    scaled_font: PCairoScaledFont): float64{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_win32_scaled_font_get_logical_to_device*(
    scaled_font: PCairoScaledFont, logical_to_device: PCairoMatrix){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_win32_scaled_font_get_device_to_logical*(
    scaled_font: PCairoScaledFont, device_to_logical: PCairoMatrix){.
    cdecl, importc, dynlib: LIB_CAIRO.}
# implementation
