
#* cairo - a vector graphics library with display and print output
# *
# * Copyright © 2002 University of Southern California
# * Copyright © 2005 Red Hat, Inc.
# *
# * This library is free software; you can redistribute it and/or
# * modify it either under the terms of the GNU Lesser General Public
# * License version 2.1 as published by the Free Software Foundation
# * (the "LGPL") or, at your option, under the terms of the Mozilla
# * Public License Version 1.1 (the "MPL"). If you do not alter this
# * notice, a recipient may use your version of this file under either
# * the MPL or the LGPL.
# *
# * You should have received a copy of the LGPL along with this library
# * in the file COPYING-LGPL-2.1; if not, write to the Free Software
# * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
# * You should have received a copy of the MPL along with this library
# * in the file COPYING-MPL-1.1
# *
# * The contents of this file are subject to the Mozilla Public License
# * Version 1.1 (the "License"); you may not use this file except in
# * compliance with the License. You may obtain a copy of the License at
# * http://www.mozilla.org/MPL/
# *
# * This software is distributed on an "AS IS" basis, WITHOUT WARRANTY
# * OF ANY KIND, either express or implied. See the LGPL or the MPL for
# * the specific language governing rights and limitations.
# *
# * The Original Code is the cairo graphics library.
# *
# * The Initial Developer of the Original Code is University of Southern
# * California.
# *
# * Contributor(s):
# *	Carl D. Worth <cworth@cworth.org>
# #*
# *  This FreePascal binding generated August 26, 2005
# *  by Jeffrey Pohlmeyer <yetanothergeek@yahoo.com>
#

#
#  - Updated to cairo version 1.4
#  - Grouped OS specific fuctions in separated units
#  - Organized the functions by group and ordered exactly as the c header
#  - Cleared parameter list syntax according to pascal standard
#
#  By Luiz Américo Pereira Câmara
#  October 2007
#

when defined(windows):
  const
    LIB_CAIRO* = "cairo.dll"
else:
  const
    LIB_CAIRO* = "libcairo.so"

type
  PByte = cstring
  TCairoStatus* = enum
    CAIRO_STATUS_SUCCESS = 0, CAIRO_STATUS_NO_MEMORY,
    CAIRO_STATUS_INVALID_RESTORE, CAIRO_STATUS_INVALID_POP_GROUP,
    CAIRO_STATUS_NO_CURRENT_POINT, CAIRO_STATUS_INVALID_MATRIX,
    CAIRO_STATUS_INVALID_STATUS, CAIRO_STATUS_NULL_POINTER,
    CAIRO_STATUS_INVALID_STRING, CAIRO_STATUS_INVALID_PATH_DATA,
    CAIRO_STATUS_READ_ERROR, CAIRO_STATUS_WRITE_ERROR,
    CAIRO_STATUS_SURFACE_FINISHED, CAIRO_STATUS_SURFACE_TYPE_MISMATCH,
    CAIRO_STATUS_PATTERN_TYPE_MISMATCH, CAIRO_STATUS_INVALID_CONTENT,
    CAIRO_STATUS_INVALID_FORMAT, CAIRO_STATUS_INVALID_VISUAL,
    CAIRO_STATUS_FILE_NOT_FOUND, CAIRO_STATUS_INVALID_DASH
  TCairoOperator* = enum
    CAIRO_OPERATOR_CLEAR, CAIRO_OPERATOR_SOURCE, CAIRO_OPERATOR_OVER,
    CAIRO_OPERATOR_IN, CAIRO_OPERATOR_OUT, CAIRO_OPERATOR_ATOP,
    CAIRO_OPERATOR_DEST, CAIRO_OPERATOR_DEST_OVER, CAIRO_OPERATOR_DEST_IN,
    CAIRO_OPERATOR_DEST_OUT, CAIRO_OPERATOR_DEST_ATOP, CAIRO_OPERATOR_XOR,
    CAIRO_OPERATOR_ADD, CAIRO_OPERATOR_SATURATE
  TCairoAntialias* = enum
    CAIRO_ANTIALIAS_DEFAULT, CAIRO_ANTIALIAS_NONE, CAIRO_ANTIALIAS_GRAY,
    CAIRO_ANTIALIAS_SUBPIXEL
  TCairoFillRule* = enum
    CAIRO_FILL_RULE_WINDING, CAIRO_FILL_RULE_EVEN_ODD
  TCairoLineCap* = enum
    CAIRO_LINE_CAP_BUTT, CAIRO_LINE_CAP_ROUND, CAIRO_LINE_CAP_SQUARE
  TCairoLineJoin* = enum
    CAIRO_LINE_JOIN_MITER, CAIRO_LINE_JOIN_ROUND, CAIRO_LINE_JOIN_BEVEL
  TCairoFontSlant* = enum
    CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_SLANT_ITALIC, CAIRO_FONT_SLANT_OBLIQUE
  TCairoFontWeight* = enum
    CAIRO_FONT_WEIGHT_NORMAL, CAIRO_FONT_WEIGHT_BOLD
  TCairoSubpixelOrder* = enum
    CAIRO_SUBPIXEL_ORDER_DEFAULT, CAIRO_SUBPIXEL_ORDER_RGB,
    CAIRO_SUBPIXEL_ORDER_BGR, CAIRO_SUBPIXEL_ORDER_VRGB,
    CAIRO_SUBPIXEL_ORDER_VBGR
  TCairoHintStyle* = enum
    CAIRO_HINT_STYLE_DEFAULT, CAIRO_HINT_STYLE_NONE, CAIRO_HINT_STYLE_SLIGHT,
    CAIRO_HINT_STYLE_MEDIUM, CAIRO_HINT_STYLE_FULL
  TCairoHintMetrics* = enum
    CAIRO_HINT_METRICS_DEFAULT, CAIRO_HINT_METRICS_OFF, CAIRO_HINT_METRICS_ON
  TCairoPathDataType* = enum
    CAIRO_PATH_MOVE_TO, CAIRO_PATH_LINE_TO, CAIRO_PATH_CURVE_TO,
    CAIRO_PATH_CLOSE_PATH
  TCairoContent* = enum
    CAIRO_CONTENT_COLOR = 0x00001000, CAIRO_CONTENT_ALPHA = 0x00002000,
    CAIRO_CONTENT_COLOR_ALPHA = 0x00003000
  TCairoFormat* = enum
    CAIRO_FORMAT_ARGB32, CAIRO_FORMAT_RGB24, CAIRO_FORMAT_A8, CAIRO_FORMAT_A1
  TCairoExtend* = enum
    CAIRO_EXTEND_NONE, CAIRO_EXTEND_REPEAT, CAIRO_EXTEND_REFLECT,
    CAIRO_EXTEND_PAD
  TCairoFilter* = enum
    CAIRO_FILTER_FAST, CAIRO_FILTER_GOOD, CAIRO_FILTER_BEST,
    CAIRO_FILTER_NEAREST, CAIRO_FILTER_BILINEAR, CAIRO_FILTER_GAUSSIAN
  TCairoFontType* = enum
    CAIRO_FONT_TYPE_TOY, CAIRO_FONT_TYPE_FT, CAIRO_FONT_TYPE_WIN32,
    CAIRO_FONT_TYPE_ATSUI
  TCairoPatternType* = enum
    CAIRO_PATTERN_TYPE_SOLID, CAIRO_PATTERN_TYPE_SURFACE,
    CAIRO_PATTERN_TYPE_LINEAR, CAIRO_PATTERN_TYPE_RADIAL
  TCairoSurfaceType* = enum
    CAIRO_SURFACE_TYPE_IMAGE, CAIRO_SURFACE_TYPE_PDF, CAIRO_SURFACE_TYPE_PS,
    CAIRO_SURFACE_TYPE_XLIB, CAIRO_SURFACE_TYPE_XCB, CAIRO_SURFACE_TYPE_GLITZ,
    CAIRO_SURFACE_TYPE_QUARTZ, CAIRO_SURFACE_TYPE_WIN32,
    CAIRO_SURFACE_TYPE_BEOS, CAIRO_SURFACE_TYPE_DIRECTFB,
    CAIRO_SURFACE_TYPE_SVG, CAIRO_SURFACE_TYPE_OS2
  TCairoSvgVersion* = enum
    CAIRO_SVG_VERSION_1_1, CAIRO_SVG_VERSION_1_2
  PCairoSurface* = ptr TCairoSurface
  PPCairoSurface* = ptr PCairoSurface
  PCairo* = ptr TCairo
  PCairoPattern* = ptr TCairoPattern
  PCairoFontOptions* = ptr TCairoFontOptions
  PCairoFontFace* = ptr TCairoFontFace
  PCairoScaledFont* = ptr TCairoScaledFont
  PCairoBool* = ptr TCairoBool
  TCairoBool* = int32
  PCairoMatrix* = ptr TCairoMatrix
  PCairoUserDataKey* = ptr TCairoUserDataKey
  PCairoGlyph* = ptr TCairoGlyph
  PCairoTextExtents* = ptr TCairoTextExtents
  PCairoFontExtents* = ptr TCairoFontExtents
  PCairoPathDataType* = ptr TCairoPathDataType
  PCairoPathData* = ptr TCairoPathData
  PCairoPath* = ptr TCairoPath
  PCairoRectangle* = ptr TCairoRectangle
  PCairoRectangleList* = ptr TCairoRectangleList
  TCairoDestroyFunc* = proc (data: Pointer){.cdecl.}
  TCairoWriteFunc* = proc (closure: Pointer, data: PByte, len: int32): TCairoStatus{.
      cdecl.}
  TCairoReadFunc* = proc (closure: Pointer, data: PByte, len: int32): TCairoStatus{.
      cdecl.}
  TCairo* {.final.} = object           #OPAQUE
  TCairoSurface* {.final.} = object   #OPAQUE
  TCairoPattern* {.final.} = object   #OPAQUE
  TCairoScaledFont* {.final.} = object #OPAQUE
  TCairoFontFace* {.final.} = object #OPAQUE
  TCairoFontOptions* {.final.} = object #OPAQUE
  TCairoMatrix* {.final.} = object
    xx: float64
    yx: float64
    xy: float64
    yy: float64
    x0: float64
    y0: float64

  TCairoUserDataKey* {.final.} = object
    unused: int32

  TCairoGlyph* {.final.} = object
    index: int32
    x: float64
    y: float64

  TCairoTextExtents* {.final.} = object
    x_bearing: float64
    y_bearing: float64
    width: float64
    height: float64
    x_advance: float64
    y_advance: float64

  TCairoFontExtents* {.final.} = object
    ascent: float64
    descent: float64
    height: float64
    max_x_advance: float64
    max_y_advance: float64

  TCairoPathData* {.final.} = object #* _type : TCairoPathDataType;
                                     #       length : LongInt;
                                     #    end
    x: float64
    y: float64

  TCairoPath* {.final.} = object
    status: TCairoStatus
    data: PCairoPathData
    num_data: int32

  TCairoRectangle* {.final.} = object
    x, y, width, height: float64

  TCairoRectangleList* {.final.} = object
    status: TCairoStatus
    rectangles: PCairoRectangle
    num_rectangles: int32


proc cairo_version*(): int32{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_version_string*(): cstring{.cdecl, importc, dynlib: LIB_CAIRO.}
  #Helper function to retrieve decoded version
proc cairo_version*(major, minor, micro: var int32)
  #* Functions for manipulating state objects
proc cairo_create*(target: PCairoSurface): PCairo{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_reference*(cr: PCairo): PCairo{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_destroy*(cr: PCairo){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_get_reference_count*(cr: PCairo): int32{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_get_user_data*(cr: PCairo, key: PCairoUserDataKey): pointer{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_set_user_data*(cr: PCairo, key: PCairoUserDataKey,
                          user_data: Pointer, destroy: TCairoDestroyFunc): TCairoStatus{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_save*(cr: PCairo){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_restore*(cr: PCairo){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_push_group*(cr: PCairo){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_push_group_with_content*(cr: PCairo, content: TCairoContent){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pop_group*(cr: PCairo): PCairoPattern{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pop_group_to_source*(cr: PCairo){.cdecl, importc, dynlib: LIB_CAIRO.}
  #* Modify state
proc cairo_set_operator*(cr: PCairo, op: TCairoOperator){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_set_source*(cr: PCairo, source: PCairoPattern){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_set_source_rgb*(cr: PCairo, red, green, blue: float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_set_source_rgba*(cr: PCairo, red, green, blue, alpha: float64){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_set_source_surface*(cr: PCairo, surface: PCairoSurface,
                               x, y: float64){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_set_tolerance*(cr: PCairo, tolerance: float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_set_antialias*(cr: PCairo, antialias: TCairoAntialias){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_set_fill_rule*(cr: PCairo, fill_rule: TCairoFillRule){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_set_line_width*(cr: PCairo, width: float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_set_line_cap*(cr: PCairo, line_cap: TCairoLineCap){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_set_line_join*(cr: PCairo, line_join: TCairoLineJoin){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_set_dash*(cr: PCairo, dashes: openarray[float64],
                     offset: float64){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_set_miter_limit*(cr: PCairo, limit: float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_translate*(cr: PCairo, tx, ty: float64){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_scale*(cr: PCairo, sx, sy: float64){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_rotate*(cr: PCairo, angle: float64){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_transform*(cr: PCairo, matrix: PCairoMatrix){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_set_matrix*(cr: PCairo, matrix: PCairoMatrix){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_identity_matrix*(cr: PCairo){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_user_to_device*(cr: PCairo, x, y: var float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_user_to_device_distance*(cr: PCairo, dx, dy: var float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_device_to_user*(cr: PCairo, x, y: var float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_device_to_user_distance*(cr: PCairo, dx, dy: var float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
  #* Path creation functions
proc cairo_new_path*(cr: PCairo){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_move_to*(cr: PCairo, x, y: float64){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_new_sub_path*(cr: PCairo){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_line_to*(cr: PCairo, x, y: float64){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_curve_to*(cr: PCairo, x1, y1, x2, y2, x3, y3: float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_arc*(cr: PCairo, xc, yc, radius, angle1, angle2: float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_arc_negative*(cr: PCairo, xc, yc, radius, angle1, angle2: float64){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_rel_move_to*(cr: PCairo, dx, dy: float64){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_rel_line_to*(cr: PCairo, dx, dy: float64){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_rel_curve_to*(cr: PCairo, dx1, dy1, dx2, dy2, dx3, dy3: float64){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_rectangle*(cr: PCairo, x, y, width, height: float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_close_path*(cr: PCairo){.cdecl, importc, dynlib: LIB_CAIRO.}
  #* Painting functions
proc cairo_paint*(cr: PCairo){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_paint_with_alpha*(cr: PCairo, alpha: float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_mask*(cr: PCairo, pattern: PCairoPattern){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_mask_surface*(cr: PCairo, surface: PCairoSurface,
                         surface_x, surface_y: float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_stroke*(cr: PCairo){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_stroke_preserve*(cr: PCairo){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_fill*(cr: PCairo){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_fill_preserve*(cr: PCairo){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_copy_page*(cr: PCairo){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_show_page*(cr: PCairo){.cdecl, importc, dynlib: LIB_CAIRO.}
  #* Insideness testing
proc cairo_in_stroke*(cr: PCairo, x, y: float64): TCairoBool{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_in_fill*(cr: PCairo, x, y: float64): TCairoBool{.cdecl, importc,
    dynlib: LIB_CAIRO.}
  #* Rectangular extents
proc cairo_stroke_extents*(cr: PCairo, x1, y1, x2, y2: var float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_fill_extents*(cr: PCairo, x1, y1, x2, y2: var float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
  #* Clipping
proc cairo_reset_clip*(cr: PCairo){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_clip*(cr: PCairo){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_clip_preserve*(cr: PCairo){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_clip_extents*(cr: PCairo, x1, y1, x2, y2: var float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_copy_clip_rectangle_list*(cr: PCairo): PCairoRectangleList{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_rectangle_list_destroy*(rectangle_list: PCairoRectangleList){.
    cdecl, importc, dynlib: LIB_CAIRO.}
  #* Font/Text functions
proc cairo_font_options_create*(): PCairoFontOptions{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_font_options_copy*(original: PCairoFontOptions): PCairoFontOptions{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_font_options_destroy*(options: PCairoFontOptions){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_font_options_status*(options: PCairoFontOptions): TCairoStatus{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_font_options_merge*(options, other: PCairoFontOptions){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_font_options_equal*(options, other: PCairoFontOptions): TCairoBool{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_font_options_hash*(options: PCairoFontOptions): int32{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_font_options_set_antialias*(options: PCairoFontOptions,
                                       antialias: TCairoAntialias){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_font_options_get_antialias*(options: PCairoFontOptions): TCairoAntialias{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_font_options_set_subpixel_order*(options: PCairoFontOptions,
    subpixel_order: TCairoSubpixelOrder){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_font_options_get_subpixel_order*(options: PCairoFontOptions): TCairoSubpixelOrder{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_font_options_set_hint_style*(options: PCairoFontOptions,
                                        hint_style: TCairoHintStyle){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_font_options_get_hint_style*(options: PCairoFontOptions): TCairoHintStyle{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_font_options_set_hint_metrics*(options: PCairoFontOptions,
    hint_metrics: TCairoHintMetrics){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_font_options_get_hint_metrics*(options: PCairoFontOptions): TCairoHintMetrics{.
    cdecl, importc, dynlib: LIB_CAIRO.}
  #* This interface is for dealing with text as text, not caring about the
  #   font object inside the the TCairo.
proc cairo_select_font_face*(cr: PCairo, family: cstring,
                             slant: TCairoFontSlant,
                             weight: TCairoFontWeight){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_set_font_size*(cr: PCairo, size: float64){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_set_font_matrix*(cr: PCairo, matrix: PCairoMatrix){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_get_font_matrix*(cr: PCairo, matrix: PCairoMatrix){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_set_font_options*(cr: PCairo, options: PCairoFontOptions){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_get_font_options*(cr: PCairo, options: PCairoFontOptions){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_set_font_face*(cr: PCairo, font_face: PCairoFontFace){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_get_font_face*(cr: PCairo): PCairoFontFace{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_set_scaled_font*(cr: PCairo, scaled_font: PCairoScaledFont){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_get_scaled_font*(cr: PCairo): PCairoScaledFont{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_show_text*(cr: PCairo, utf8: cstring){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_show_glyphs*(cr: PCairo, glyphs: PCairoGlyph, num_glyphs: int32){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_text_path*(cr: PCairo, utf8: cstring){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_glyph_path*(cr: PCairo, glyphs: PCairoGlyph, num_glyphs: int32){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_text_extents*(cr: PCairo, utf8: cstring,
                         extents: PCairoTextExtents){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_glyph_extents*(cr: PCairo, glyphs: PCairoGlyph,
                          num_glyphs: int32, extents: PCairoTextExtents){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_font_extents*(cr: PCairo, extents: PCairoFontExtents){.cdecl, importc,
    dynlib: LIB_CAIRO.}
  #* Generic identifier for a font style
proc cairo_font_face_reference*(font_face: PCairoFontFace): PCairoFontFace{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_font_face_destroy*(font_face: PCairoFontFace){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_font_face_get_reference_count*(font_face: PCairoFontFace): int32{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_font_face_status*(font_face: PCairoFontFace): TCairoStatus{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_font_face_get_type*(font_face: PCairoFontFace): TCairoFontType{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_font_face_get_user_data*(font_face: PCairoFontFace,
                                    key: PCairoUserDataKey): pointer{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_font_face_set_user_data*(font_face: PCairoFontFace,
                                    key: PCairoUserDataKey,
                                    user_data: pointer,
                                    destroy: TCairoDestroyFunc): TCairoStatus{.
    cdecl, importc, dynlib: LIB_CAIRO.}
  #* Portable interface to general font features
proc cairo_scaled_font_create*(font_face: PCairoFontFace,
                               font_matrix: PCairoMatrix,
                               ctm: PCairoMatrix,
                               options: PCairoFontOptions): PCairoScaledFont{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_scaled_font_reference*(scaled_font: PCairoScaledFont): PCairoScaledFont{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_scaled_font_destroy*(scaled_font: PCairoScaledFont){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_scaled_font_get_reference_count*(scaled_font: PCairoScaledFont): int32{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_scaled_font_status*(scaled_font: PCairoScaledFont): TCairoStatus{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_scaled_font_get_type*(scaled_font: PCairoScaledFont): TCairoFontType{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_scaled_font_get_user_data*(scaled_font: PCairoScaledFont,
                                      key: PCairoUserDataKey): Pointer{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_scaled_font_set_user_data*(scaled_font: PCairoScaledFont,
                                      key: PCairoUserDataKey,
                                      user_data: Pointer,
                                      destroy: TCairoDestroyFunc): TCairoStatus{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_scaled_font_extents*(scaled_font: PCairoScaledFont,
                                extents: PCairoFontExtents){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_scaled_font_text_extents*(scaled_font: PCairoScaledFont,
                                     utf8: cstring,
                                     extents: PCairoTextExtents){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_scaled_font_glyph_extents*(scaled_font: PCairoScaledFont,
                                      glyphs: PCairoGlyph, num_glyphs: int32,
                                      extents: PCairoTextExtents){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_scaled_font_get_font_face*(scaled_font: PCairoScaledFont): PCairoFontFace{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_scaled_font_get_font_matrix*(scaled_font: PCairoScaledFont,
                                        font_matrix: PCairoMatrix){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_scaled_font_get_ctm*(scaled_font: PCairoScaledFont,
                                ctm: PCairoMatrix){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_scaled_font_get_font_options*(scaled_font: PCairoScaledFont,
    options: PCairoFontOptions){.cdecl, importc, dynlib: LIB_CAIRO.}
  #* Query functions
proc cairo_get_operator*(cr: PCairo): TCairoOperator{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_get_source*(cr: PCairo): PCairoPattern{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_get_tolerance*(cr: PCairo): float64{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_get_antialias*(cr: PCairo): TCairoAntialias{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_get_current_point*(cr: PCairo, x, y: var float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_get_fill_rule*(cr: PCairo): TCairoFillRule{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_get_line_width*(cr: PCairo): float64{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_get_line_cap*(cr: PCairo): TCairoLineCap{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_get_line_join*(cr: PCairo): TCairoLineJoin{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_get_miter_limit*(cr: PCairo): float64{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_get_dash_count*(cr: PCairo): int32{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_get_dash*(cr: PCairo, dashes, offset: var float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_get_matrix*(cr: PCairo, matrix: PCairoMatrix){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_get_target*(cr: PCairo): PCairoSurface{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_get_group_target*(cr: PCairo): PCairoSurface{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_copy_path*(cr: PCairo): PCairoPath{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_copy_path_flat*(cr: PCairo): PCairoPath{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_append_path*(cr: PCairo, path: PCairoPath){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_path_destroy*(path: PCairoPath){.cdecl, importc, dynlib: LIB_CAIRO.}
  #* Error status queries
proc cairo_status*(cr: PCairo): TCairoStatus{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_status_to_string*(status: TCairoStatus): cstring{.cdecl, importc,
    dynlib: LIB_CAIRO.}
  #* Surface manipulation
proc cairo_surface_create_similar*(other: PCairoSurface,
                                   content: TCairoContent,
                                   width, height: int32): PCairoSurface{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_surface_reference*(surface: PCairoSurface): PCairoSurface{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_surface_finish*(surface: PCairoSurface){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_surface_destroy*(surface: PCairoSurface){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_surface_get_reference_count*(surface: PCairoSurface): int32{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_surface_status*(surface: PCairoSurface): TCairoStatus{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_surface_get_type*(surface: PCairoSurface): TCairoSurfaceType{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_surface_get_content*(surface: PCairoSurface): TCairoContent{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_surface_write_to_png*(surface: PCairoSurface, filename: cstring): TCairoStatus{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_surface_write_to_png_stream*(surface: PCairoSurface,
                                        write_func: TCairoWriteFunc,
                                        closure: pointer): TCairoStatus{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_surface_get_user_data*(surface: PCairoSurface,
                                  key: PCairoUserDataKey): pointer{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_surface_set_user_data*(surface: PCairoSurface,
                                  key: PCairoUserDataKey,
                                  user_data: pointer,
                                  destroy: TCairoDestroyFunc): TCairoStatus{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_surface_get_font_options*(surface: PCairoSurface,
                                     options: PCairoFontOptions){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_surface_flush*(surface: PCairoSurface){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_surface_mark_dirty*(surface: PCairoSurface){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_surface_mark_dirty_rectangle*(surface: PCairoSurface,
    x, y, width, height: int32){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_surface_set_device_offset*(surface: PCairoSurface,
                                      x_offset, y_offset: float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_surface_get_device_offset*(surface: PCairoSurface,
                                      x_offset, y_offset: var float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_surface_set_fallback_resolution*(surface: PCairoSurface,
    x_pixels_per_inch, y_pixels_per_inch: float64){.cdecl, importc, dynlib: LIB_CAIRO.}
  #* Image-surface functions
proc cairo_image_surface_create*(format: TCairoFormat, width, height: int32): PCairoSurface{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_image_surface_create_for_data*(data: Pbyte, format: TCairoFormat,
    width, height, stride: int32): PCairoSurface{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_image_surface_get_data*(surface: PCairoSurface): cstring{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_image_surface_get_format*(surface: PCairoSurface): TCairoFormat{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_image_surface_get_width*(surface: PCairoSurface): int32{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_image_surface_get_height*(surface: PCairoSurface): int32{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_image_surface_get_stride*(surface: PCairoSurface): int32{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_image_surface_create_from_png*(filename: cstring): PCairoSurface{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_image_surface_create_from_png_stream*(read_func: TCairoReadFunc,
    closure: pointer): PCairoSurface{.cdecl, importc, dynlib: LIB_CAIRO.}
  #* Pattern creation functions
proc cairo_pattern_create_rgb*(red, green, blue: float64): PCairoPattern{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_create_rgba*(red, green, blue, alpha: float64): PCairoPattern{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_create_for_surface*(surface: PCairoSurface): PCairoPattern{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_create_linear*(x0, y0, x1, y1: float64): PCairoPattern{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_create_radial*(cx0, cy0, radius0, cx1, cy1, radius1: float64): PCairoPattern{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_reference*(pattern: PCairoPattern): PCairoPattern{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_destroy*(pattern: PCairoPattern){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_get_reference_count*(pattern: PCairoPattern): int32{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_status*(pattern: PCairoPattern): TCairoStatus{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_pattern_get_user_data*(pattern: PCairoPattern,
                                  key: PCairoUserDataKey): Pointer{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_pattern_set_user_data*(pattern: PCairoPattern,
                                  key: PCairoUserDataKey,
                                  user_data: Pointer,
                                  destroy: TCairoDestroyFunc): TCairoStatus{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_get_type*(pattern: PCairoPattern): TCairoPatternType{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_add_color_stop_rgb*(pattern: PCairoPattern,
                                       offset, red, green, blue: float64){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_add_color_stop_rgba*(pattern: PCairoPattern, offset, red,
    green, blue, alpha: float64){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_set_matrix*(pattern: PCairoPattern,
                               matrix: PCairoMatrix){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_pattern_get_matrix*(pattern: PCairoPattern,
                               matrix: PCairoMatrix){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_pattern_set_extend*(pattern: PCairoPattern, extend: TCairoExtend){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_get_extend*(pattern: PCairoPattern): TCairoExtend{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_set_filter*(pattern: PCairoPattern, filter: TCairoFilter){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_get_filter*(pattern: PCairoPattern): TCairoFilter{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_get_rgba*(pattern: PCairoPattern,
                             red, green, blue, alpha: var float64): TCairoStatus{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_get_surface*(pattern: PCairoPattern,
                                surface: PPCairoSurface): TCairoStatus{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_get_color_stop_rgba*(pattern: PCairoPattern, index: int32,
    offset, red, green, blue, alpha: var float64): TCairoStatus{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_pattern_get_color_stop_count*(pattern: PCairoPattern,
    count: var int32): TCairoStatus{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_get_linear_points*(pattern: PCairoPattern,
                                      x0, y0, x1, y1: var float64): TCairoStatus{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_get_radial_circles*(pattern: PCairoPattern,
                                       x0, y0, r0, x1, y1, r1: var float64): TCairoStatus{.
    cdecl, importc, dynlib: LIB_CAIRO.}
  #* Matrix functions
proc cairo_matrix_init*(matrix: PCairoMatrix, xx, yx, xy, yy, x0, y0: float64){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_matrix_init_identity*(matrix: PCairoMatrix){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_matrix_init_translate*(matrix: PCairoMatrix, tx, ty: float64){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_matrix_init_scale*(matrix: PCairoMatrix, sx, sy: float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_matrix_init_rotate*(matrix: PCairoMatrix, radians: float64){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_matrix_translate*(matrix: PCairoMatrix, tx, ty: float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_matrix_scale*(matrix: PCairoMatrix, sx, sy: float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_matrix_rotate*(matrix: PCairoMatrix, radians: float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_matrix_invert*(matrix: PCairoMatrix): TCairoStatus{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_matrix_multiply*(result, a, b: PCairoMatrix){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_matrix_transform_distance*(matrix: PCairoMatrix, dx, dy: var float64){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_matrix_transform_point*(matrix: PCairoMatrix, x, y: var float64){.
    cdecl, importc, dynlib: LIB_CAIRO.}
  #* PDF functions
proc cairo_pdf_surface_create*(filename: cstring,
                               width_in_points, height_in_points: float64): PCairoSurface{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pdf_surface_create_for_stream*(write_func: TCairoWriteFunc,
    closure: Pointer, width_in_points, height_in_points: float64): PCairoSurface{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pdf_surface_set_size*(surface: PCairoSurface,
                                 width_in_points, height_in_points: float64){.
    cdecl, importc, dynlib: LIB_CAIRO.}
  #* PS functions
proc cairo_ps_surface_create*(filename: cstring,
                              width_in_points, height_in_points: float64): PCairoSurface{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_ps_surface_create_for_stream*(write_func: TCairoWriteFunc,
    closure: Pointer, width_in_points, height_in_points: float64): PCairoSurface{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_ps_surface_set_size*(surface: PCairoSurface,
                                width_in_points, height_in_points: float64){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_ps_surface_dsc_comment*(surface: PCairoSurface, comment: cstring){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_ps_surface_dsc_begin_setup*(surface: PCairoSurface){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_ps_surface_dsc_begin_page_setup*(surface: PCairoSurface){.cdecl, importc,
    dynlib: LIB_CAIRO.}
  #* SVG functions
proc cairo_svg_surface_create*(filename: cstring,
                               width_in_points, height_in_points: float64): PCairoSurface{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_svg_surface_create_for_stream*(write_func: TCairoWriteFunc,
    closure: Pointer, width_in_points, height_in_points: float64): PCairoSurface{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_svg_surface_restrict_to_version*(surface: PCairoSurface,
    version: TCairoSvgVersion){.cdecl, importc, dynlib: LIB_CAIRO.}
  #todo: see how translate this
  #procedure cairo_svg_get_versions(TCairoSvgVersion const	**versions,
  #                        int                      	 *num_versions);
proc cairo_svg_version_to_string*(version: TCairoSvgVersion): cstring{.cdecl, importc,
    dynlib: LIB_CAIRO.}
  #* Functions to be used while debugging (not intended for use in production code)
proc cairo_debug_reset_static_data*(){.cdecl, importc, dynlib: LIB_CAIRO.}
# implementation

proc cairo_version(major, minor, micro: var int32) =
  var version: int32
  version = cairo_version()
  major = version div 10000'i32
  minor = (version mod (major * 10000'i32)) div 100'i32
  micro = (version mod ((major * 10000'i32) + (minor * 100'i32)))
