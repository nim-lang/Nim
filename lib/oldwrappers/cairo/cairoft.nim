#
# Translation of cairo-ft.h 
# by Jeffrey Pohlmeyer 
# updated to version 1.4 by Luiz Américo Pereira Câmara 2007
#

import cairo, freetypeh

#todo: properly define FcPattern:
#It will require translate FontConfig header

#*
#typedef struct _XftPattern {
#  int		    num;
#  int		    size;
#  XftPatternElt   *elts;
# } XftPattern;
# typedef FcPattern XftPattern;
#

type 
  FcPattern* = Pointer
  PFcPattern* = ptr FcPattern

proc cairo_ft_font_face_create_for_pattern*(pattern: PFcPattern): PCairoFontFace{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_ft_font_options_substitute*(options: PCairoFontOptions, 
                                       pattern: PFcPattern){.cdecl, importc, 
    dynlib: LIB_CAIRO.}
proc cairo_ft_font_face_create_for_ft_face*(face: TFT_Face, 
       load_flags: int32): PCairoFontFace {.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_ft_scaled_font_lock_face*(
  scaled_font: PCairoScaledFont): TFT_Face{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_ft_scaled_font_unlock_face*(
  scaled_font: PCairoScaledFont){.cdecl, importc, dynlib: LIB_CAIRO.}

