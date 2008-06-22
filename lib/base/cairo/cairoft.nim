#
# Translation of cairo-ft.h 
# by Jeffrey Pohlmeyer 
# updated to version 1.4 by Luiz Américo Pereira Câmara 2007
#

import  Cairo, freetypeh

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
  PFcPattern* = ref FcPattern

proc cairo_ft_font_face_create_for_pattern*(pattern: PFcPattern): Pcairo_font_face_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_ft_font_options_substitute*(options: Pcairo_font_options_t, 
                                       pattern: PFcPattern){.cdecl, importc, 
    dynlib: LIB_CAIRO.}
proc cairo_ft_font_face_create_for_ft_face*(face: TFT_Face, 
       load_flags: int32): Pcairo_font_face_t {.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_ft_scaled_font_lock_face*(
  scaled_font: Pcairo_scaled_font_t): TFT_Face{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_ft_scaled_font_unlock_face*(
  scaled_font: Pcairo_scaled_font_t){.cdecl, importc, dynlib: LIB_CAIRO.}

