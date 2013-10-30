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

include "cairo_pragma.nim"

type
  PByte = cstring
  TStatus* = enum
    STATUS_SUCCESS = 0,
    STATUS_NO_MEMORY,
    STATUS_INVALID_RESTORE,
    STATUS_INVALID_POP_GROUP,
    STATUS_NO_CURRENT_POINT,
    STATUS_INVALID_MATRIX,
    STATUS_INVALID_STATUS,
    STATUS_NULL_POINTER,
    STATUS_INVALID_STRING,
    STATUS_INVALID_PATH_DATA,
    STATUS_READ_ERROR,
    STATUS_WRITE_ERROR,
    STATUS_SURFACE_FINISHED,
    STATUS_SURFACE_TYPE_MISMATCH,
    STATUS_PATTERN_TYPE_MISMATCH,
    STATUS_INVALID_CONTENT,
    STATUS_INVALID_FORMAT,
    STATUS_INVALID_VISUAL,
    STATUS_FILE_NOT_FOUND,
    STATUS_INVALID_DASH,
    STATUS_INVALID_DSC_COMMENT,
    STATUS_INVALID_INDEX,
    STATUS_CLIP_NOT_REPRESENTABLE,
    STATUS_TEMP_FILE_ERROR,
    STATUS_INVALID_STRIDE,
    STATUS_FONT_TYPE_MISMATCH,
    STATUS_USER_FONT_IMMUTABLE,
    STATUS_USER_FONT_ERROR,
    STATUS_NEGATIVE_COUNT,
    STATUS_INVALID_CLUSTERS,
    STATUS_INVALID_SLANT,
    STATUS_INVALID_WEIGHT


  TOperator* = enum
    OPERATOR_CLEAR, OPERATOR_SOURCE, OPERATOR_OVER, OPERATOR_IN, OPERATOR_OUT,
    OPERATOR_ATOP, OPERATOR_DEST, OPERATOR_DEST_OVER, OPERATOR_DEST_IN,
    OPERATOR_DEST_OUT, OPERATOR_DEST_ATOP, OPERATOR_XOR, OPERATOR_ADD,
    OPERATOR_SATURATE
  TAntialias* = enum
    ANTIALIAS_DEFAULT, ANTIALIAS_NONE, ANTIALIAS_GRAY, ANTIALIAS_SUBPIXEL
  TFillRule* = enum
    FILL_RULE_WINDING, FILL_RULE_EVEN_ODD
  TLineCap* = enum
    LINE_CAP_BUTT, LINE_CAP_ROUND, LINE_CAP_SQUARE
  TLineJoin* = enum
    LINE_JOIN_MITER, LINE_JOIN_ROUND, LINE_JOIN_BEVEL
  TFontSlant* = enum
    FONT_SLANT_NORMAL, FONT_SLANT_ITALIC, FONT_SLANT_OBLIQUE
  TFontWeight* = enum
    FONT_WEIGHT_NORMAL, FONT_WEIGHT_BOLD
  TSubpixelOrder* = enum
    SUBPIXEL_ORDER_DEFAULT, SUBPIXEL_ORDER_RGB, SUBPIXEL_ORDER_BGR,
    SUBPIXEL_ORDER_VRGB, SUBPIXEL_ORDER_VBGR
  THintStyle* = enum
    HINT_STYLE_DEFAULT, HINT_STYLE_NONE, HINT_STYLE_SLIGHT, HINT_STYLE_MEDIUM,
    HINT_STYLE_FULL
  THintMetrics* = enum
    HINT_METRICS_DEFAULT, HINT_METRICS_OFF, HINT_METRICS_ON
  TPathDataType* = enum
    PATH_MOVE_TO, PATH_LINE_TO, PATH_CURVE_TO, PATH_CLOSE_PATH
  TContent* = enum
    CONTENT_COLOR = 0x00001000, CONTENT_ALPHA = 0x00002000,
    CONTENT_COLOR_ALPHA = 0x00003000
  TFormat* = enum
    FORMAT_ARGB32, FORMAT_RGB24, FORMAT_A8, FORMAT_A1
  TExtend* = enum
    EXTEND_NONE, EXTEND_REPEAT, EXTEND_REFLECT, EXTEND_PAD
  TFilter* = enum
    FILTER_FAST, FILTER_GOOD, FILTER_BEST, FILTER_NEAREST, FILTER_BILINEAR,
    FILTER_GAUSSIAN
  TFontType* = enum
    FONT_TYPE_TOY, FONT_TYPE_FT, FONT_TYPE_WIN32, FONT_TYPE_ATSUI
  TPatternType* = enum
    PATTERN_TYPE_SOLID, PATTERN_TYPE_SURFACE, PATTERN_TYPE_LINEAR,
    PATTERN_TYPE_RADIAL
  TSurfaceType* = enum
    SURFACE_TYPE_IMAGE, SURFACE_TYPE_PDF, SURFACE_TYPE_PS, SURFACE_TYPE_XLIB,
    SURFACE_TYPE_XCB, SURFACE_TYPE_GLITZ, SURFACE_TYPE_QUARTZ,
    SURFACE_TYPE_WIN32, SURFACE_TYPE_BEOS, SURFACE_TYPE_DIRECTFB,
    SURFACE_TYPE_SVG, SURFACE_TYPE_OS2
  TSvgVersion* = enum
    SVG_VERSION_1_1, SVG_VERSION_1_2
  PSurface* = ptr TSurface
  PPSurface* = ptr PSurface
  PContext* = ptr TContext
  PPattern* = ptr TPattern
  PFontOptions* = ptr TFontOptions
  PFontFace* = ptr TFontFace
  PScaledFont* = ptr TScaledFont
  PBool* = ptr TBool
  TBool* = int32
  PMatrix* = ptr TMatrix
  PUserDataKey* = ptr TUserDataKey
  PGlyph* = ptr TGlyph
  PTextExtents* = ptr TTextExtents
  PFontExtents* = ptr TFontExtents
  PPathDataType* = ptr TPathDataType
  PPathData* = ptr TPathData
  PPath* = ptr TPath
  PRectangle* = ptr TRectangle
  PRectangleList* = ptr TRectangleList
  TDestroyFunc* = proc (data: Pointer){.cdecl.}
  TWriteFunc* = proc (closure: Pointer, data: PByte, len: int32): TStatus{.cdecl.}
  TReadFunc* = proc (closure: Pointer, data: PByte, len: int32): TStatus{.cdecl.}
  TContext*{.final.} = object        #OPAQUE
  TSurface*{.final.} = object  #OPAQUE
  TPattern*{.final.} = object  #OPAQUE
  TScaledFont*{.final.} = object  #OPAQUE
  TFontFace*{.final.} = object  #OPAQUE
  TFontOptions*{.final.} = object  #OPAQUE
  TMatrix*{.final.} = object
    xx: float64
    yx: float64
    xy: float64
    yy: float64
    x0: float64
    y0: float64

  TUserDataKey*{.final.} = object
    unused: int32

  TGlyph*{.final.} = object
    index: int32
    x: float64
    y: float64

  TTextExtents*{.final.} = object
    x_bearing: float64
    y_bearing: float64
    width: float64
    height: float64
    x_advance: float64
    y_advance: float64

  TFontExtents*{.final.} = object
    ascent: float64
    descent: float64
    height: float64
    max_x_advance: float64
    max_y_advance: float64

  TPathData*{.final.} = object  #* _type : TCairoPathDataType;
                                #       length : LongInt;
                                #    end
    x: float64
    y: float64

  TPath*{.final.} = object
    status: TStatus
    data: PPathData
    num_data: int32

  TRectangle*{.final.} = object
    x, y, width, height: float64

  TRectangleList*{.final.} = object
    status: TStatus
    rectangles: PRectangle
    num_rectangles: int32


proc version*(): int32{.cdecl, importc: "cairo_version", libcairo.}
proc version_string*(): cstring{.cdecl, importc: "cairo_version_string",
                                 libcairo.}
  #Helper function to retrieve decoded version
proc version*(major, minor, micro: var int32)
  #* Functions for manipulating state objects
proc create*(target: PSurface): PContext{.cdecl, importc: "cairo_create",
                                   libcairo.}
proc reference*(cr: PContext): PContext{.cdecl, importc: "cairo_reference", libcairo.}
proc destroy*(cr: PContext){.cdecl, importc: "cairo_destroy", libcairo.}
proc get_reference_count*(cr: PContext): int32{.cdecl,
    importc: "cairo_get_reference_count", libcairo.}
proc get_user_data*(cr: PContext, key: PUserDataKey): pointer{.cdecl,
    importc: "cairo_get_user_data", libcairo.}
proc set_user_data*(cr: PContext, key: PUserDataKey, user_data: Pointer,
                    destroy: TDestroyFunc): TStatus{.cdecl,
    importc: "cairo_set_user_data", libcairo.}
proc save*(cr: PContext){.cdecl, importc: "cairo_save", libcairo.}
proc restore*(cr: PContext){.cdecl, importc: "cairo_restore", libcairo.}
proc push_group*(cr: PContext){.cdecl, importc: "cairo_push_group", libcairo.}
proc push_group_with_content*(cr: PContext, content: TContent){.cdecl,
    importc: "cairo_push_group_with_content", libcairo.}
proc pop_group*(cr: PContext): PPattern{.cdecl, importc: "cairo_pop_group",
                                  libcairo.}
proc pop_group_to_source*(cr: PContext){.cdecl, importc: "cairo_pop_group_to_source",
                                  libcairo.}
  #* Modify state
proc set_operator*(cr: PContext, op: TOperator){.cdecl, importc: "cairo_set_operator",
    libcairo.}
proc set_source*(cr: PContext, source: PPattern){.cdecl, importc: "cairo_set_source",
    libcairo.}
proc set_source_rgb*(cr: PContext, red, green, blue: float64){.cdecl,
    importc: "cairo_set_source_rgb", libcairo.}
proc set_source_rgba*(cr: PContext, red, green, blue, alpha: float64){.cdecl,
    importc: "cairo_set_source_rgba", libcairo.}
proc set_source*(cr: PContext, surface: PSurface, x, y: float64){.cdecl,
    importc: "cairo_set_source_surface", libcairo.}
proc set_tolerance*(cr: PContext, tolerance: float64){.cdecl,
    importc: "cairo_set_tolerance", libcairo.}
proc set_antialias*(cr: PContext, antialias: TAntialias){.cdecl,
    importc: "cairo_set_antialias", libcairo.}
proc set_fill_rule*(cr: PContext, fill_rule: TFillRule){.cdecl,
    importc: "cairo_set_fill_rule", libcairo.}
proc set_line_width*(cr: PContext, width: float64){.cdecl,
    importc: "cairo_set_line_width", libcairo.}
proc set_line_cap*(cr: PContext, line_cap: TLineCap){.cdecl,
    importc: "cairo_set_line_cap", libcairo.}
proc set_line_join*(cr: PContext, line_join: TLineJoin){.cdecl,
    importc: "cairo_set_line_join", libcairo.}
proc set_dash*(cr: PContext, dashes: openarray[float64], offset: float64){.cdecl,
    importc: "cairo_set_dash", libcairo.}
proc set_miter_limit*(cr: PContext, limit: float64){.cdecl,
    importc: "cairo_set_miter_limit", libcairo.}
proc translate*(cr: PContext, tx, ty: float64){.cdecl, importc: "cairo_translate",
    libcairo.}
proc scale*(cr: PContext, sx, sy: float64){.cdecl, importc: "cairo_scale",
                                     libcairo.}
proc rotate*(cr: PContext, angle: float64){.cdecl, importc: "cairo_rotate",
                                     libcairo.}
proc transform*(cr: PContext, matrix: PMatrix){.cdecl, importc: "cairo_transform",
    libcairo.}
proc set_matrix*(cr: PContext, matrix: PMatrix){.cdecl, importc: "cairo_set_matrix",
    libcairo.}
proc identity_matrix*(cr: PContext){.cdecl, importc: "cairo_identity_matrix",
                              libcairo.}
proc user_to_device*(cr: PContext, x, y: var float64){.cdecl,
    importc: "cairo_user_to_device", libcairo.}
proc user_to_device_distance*(cr: PContext, dx, dy: var float64){.cdecl,
    importc: "cairo_user_to_device_distance", libcairo.}
proc device_to_user*(cr: PContext, x, y: var float64){.cdecl,
    importc: "cairo_device_to_user", libcairo.}
proc device_to_user_distance*(cr: PContext, dx, dy: var float64){.cdecl,
    importc: "cairo_device_to_user_distance", libcairo.}
  #* Path creation functions
proc new_path*(cr: PContext){.cdecl, importc: "cairo_new_path", libcairo.}
proc move_to*(cr: PContext, x, y: float64){.cdecl, importc: "cairo_move_to",
                                     libcairo.}
proc new_sub_path*(cr: PContext){.cdecl, importc: "cairo_new_sub_path",
                           libcairo.}
proc line_to*(cr: PContext, x, y: float64){.cdecl, importc: "cairo_line_to",
                                     libcairo.}
proc curve_to*(cr: PContext, x1, y1, x2, y2, x3, y3: float64){.cdecl,
    importc: "cairo_curve_to", libcairo.}
proc arc*(cr: PContext, xc, yc, radius, angle1, angle2: float64){.cdecl,
    importc: "cairo_arc", libcairo.}
proc arc_negative*(cr: PContext, xc, yc, radius, angle1, angle2: float64){.cdecl,
    importc: "cairo_arc_negative", libcairo.}
proc rel_move_to*(cr: PContext, dx, dy: float64){.cdecl, importc: "cairo_rel_move_to",
    libcairo.}
proc rel_line_to*(cr: PContext, dx, dy: float64){.cdecl, importc: "cairo_rel_line_to",
    libcairo.}
proc rel_curve_to*(cr: PContext, dx1, dy1, dx2, dy2, dx3, dy3: float64){.cdecl,
    importc: "cairo_rel_curve_to", libcairo.}
proc rectangle*(cr: PContext, x, y, width, height: float64){.cdecl,
    importc: "cairo_rectangle", libcairo.}
proc close_path*(cr: PContext){.cdecl, importc: "cairo_close_path", libcairo.}
  #* Painting functions
proc paint*(cr: PContext){.cdecl, importc: "cairo_paint", libcairo.}
proc paint_with_alpha*(cr: PContext, alpha: float64){.cdecl,
    importc: "cairo_paint_with_alpha", libcairo.}
proc mask*(cr: PContext, pattern: PPattern){.cdecl, importc: "cairo_mask",
                                      libcairo.}
proc mask*(cr: PContext, surface: PSurface, surface_x, surface_y: float64){.
    cdecl, importc: "cairo_mask_surface", libcairo.}
proc stroke*(cr: PContext){.cdecl, importc: "cairo_stroke", libcairo.}
proc stroke_preserve*(cr: PContext){.cdecl, importc: "cairo_stroke_preserve",
                              libcairo.}
proc fill*(cr: PContext){.cdecl, importc: "cairo_fill", libcairo.}
proc fill_preserve*(cr: PContext){.cdecl, importc: "cairo_fill_preserve",
                            libcairo.}
proc copy_page*(cr: PContext){.cdecl, importc: "cairo_copy_page", libcairo.}
proc show_page*(cr: PContext){.cdecl, importc: "cairo_show_page", libcairo.}
  #* Insideness testing
proc in_stroke*(cr: PContext, x, y: float64): TBool{.cdecl, importc: "cairo_in_stroke",
    libcairo.}
proc in_fill*(cr: PContext, x, y: float64): TBool{.cdecl, importc: "cairo_in_fill",
    libcairo.}
  #* Rectangular extents
proc stroke_extents*(cr: PContext, x1, y1, x2, y2: var float64){.cdecl,
    importc: "cairo_stroke_extents", libcairo.}
proc fill_extents*(cr: PContext, x1, y1, x2, y2: var float64){.cdecl,
    importc: "cairo_fill_extents", libcairo.}
  #* Clipping
proc reset_clip*(cr: PContext){.cdecl, importc: "cairo_reset_clip", libcairo.}
proc clip*(cr: PContext){.cdecl, importc: "cairo_clip", libcairo.}
proc clip_preserve*(cr: PContext){.cdecl, importc: "cairo_clip_preserve",
                            libcairo.}
proc clip_extents*(cr: PContext, x1, y1, x2, y2: var float64){.cdecl,
    importc: "cairo_clip_extents", libcairo.}
proc copy_clip_rectangle_list*(cr: PContext): PRectangleList{.cdecl,
    importc: "cairo_copy_clip_rectangle_list", libcairo.}
proc rectangle_list_destroy*(rectangle_list: PRectangleList){.cdecl,
    importc: "cairo_rectangle_list_destroy", libcairo.}
  #* Font/Text functions
proc font_options_create*(): PFontOptions{.cdecl,
    importc: "cairo_font_options_create", libcairo.}
proc copy*(original: PFontOptions): PFontOptions{.cdecl,
    importc: "cairo_font_options_copy", libcairo.}
proc destroy*(options: PFontOptions){.cdecl,
    importc: "cairo_font_options_destroy", libcairo.}
proc status*(options: PFontOptions): TStatus{.cdecl,
    importc: "cairo_font_options_status", libcairo.}
proc merge*(options, other: PFontOptions){.cdecl,
    importc: "cairo_font_options_merge", libcairo.}
proc equal*(options, other: PFontOptions): TBool{.cdecl,
    importc: "cairo_font_options_equal", libcairo.}
proc hash*(options: PFontOptions): int32{.cdecl,
    importc: "cairo_font_options_hash", libcairo.}
proc set_antialias*(options: PFontOptions, antialias: TAntialias){.
    cdecl, importc: "cairo_font_options_set_antialias", libcairo.}
proc get_antialias*(options: PFontOptions): TAntialias{.cdecl,
    importc: "cairo_font_options_get_antialias", libcairo.}
proc set_subpixel_order*(options: PFontOptions,
                                      subpixel_order: TSubpixelOrder){.cdecl,
    importc: "cairo_font_options_set_subpixel_order", libcairo.}
proc get_subpixel_order*(options: PFontOptions): TSubpixelOrder{.
    cdecl, importc: "cairo_font_options_get_subpixel_order", libcairo.}
proc set_hint_style*(options: PFontOptions, hint_style: THintStyle){.
    cdecl, importc: "cairo_font_options_set_hint_style", libcairo.}
proc get_hint_style*(options: PFontOptions): THintStyle{.cdecl,
    importc: "cairo_font_options_get_hint_style", libcairo.}
proc set_hint_metrics*(options: PFontOptions,
                                    hint_metrics: THintMetrics){.cdecl,
    importc: "cairo_font_options_set_hint_metrics", libcairo.}
proc get_hint_metrics*(options: PFontOptions): THintMetrics{.cdecl,
    importc: "cairo_font_options_get_hint_metrics", libcairo.}
  #* This interface is for dealing with text as text, not caring about the
  #   font object inside the the TCairo.
proc select_font_face*(cr: PContext, family: cstring, slant: TFontSlant,
                       weight: TFontWeight){.cdecl,
    importc: "cairo_select_font_face", libcairo.}
proc set_font_size*(cr: PContext, size: float64){.cdecl,
    importc: "cairo_set_font_size", libcairo.}
proc set_font_matrix*(cr: PContext, matrix: PMatrix){.cdecl,
    importc: "cairo_set_font_matrix", libcairo.}
proc get_font_matrix*(cr: PContext, matrix: PMatrix){.cdecl,
    importc: "cairo_get_font_matrix", libcairo.}
proc set_font_options*(cr: PContext, options: PFontOptions){.cdecl,
    importc: "cairo_set_font_options", libcairo.}
proc get_font_options*(cr: PContext, options: PFontOptions){.cdecl,
    importc: "cairo_get_font_options", libcairo.}
proc set_font_face*(cr: PContext, font_face: PFontFace){.cdecl,
    importc: "cairo_set_font_face", libcairo.}
proc get_font_face*(cr: PContext): PFontFace{.cdecl, importc: "cairo_get_font_face",
                                       libcairo.}
proc set_scaled_font*(cr: PContext, scaled_font: PScaledFont){.cdecl,
    importc: "cairo_set_scaled_font", libcairo.}
proc get_scaled_font*(cr: PContext): PScaledFont{.cdecl,
    importc: "cairo_get_scaled_font", libcairo.}
proc show_text*(cr: PContext, utf8: cstring){.cdecl, importc: "cairo_show_text",
                                       libcairo.}
proc show_glyphs*(cr: PContext, glyphs: PGlyph, num_glyphs: int32){.cdecl,
    importc: "cairo_show_glyphs", libcairo.}
proc text_path*(cr: PContext, utf8: cstring){.cdecl, importc: "cairo_text_path",
                                       libcairo.}
proc glyph_path*(cr: PContext, glyphs: PGlyph, num_glyphs: int32){.cdecl,
    importc: "cairo_glyph_path", libcairo.}
proc text_extents*(cr: PContext, utf8: cstring, extents: PTextExtents){.cdecl,
    importc: "cairo_text_extents", libcairo.}
proc glyph_extents*(cr: PContext, glyphs: PGlyph, num_glyphs: int32,
                    extents: PTextExtents){.cdecl,
    importc: "cairo_glyph_extents", libcairo.}
proc font_extents*(cr: PContext, extents: PFontExtents){.cdecl,
    importc: "cairo_font_extents", libcairo.}
  #* Generic identifier for a font style
proc reference*(font_face: PFontFace): PFontFace{.cdecl,
    importc: "cairo_font_face_reference", libcairo.}
proc destroy*(font_face: PFontFace){.cdecl,
    importc: "cairo_font_face_destroy", libcairo.}
proc get_reference_count*(font_face: PFontFace): int32{.cdecl,
    importc: "cairo_font_face_get_reference_count", libcairo.}
proc status*(font_face: PFontFace): TStatus{.cdecl,
    importc: "cairo_font_face_status", libcairo.}
proc get_type*(font_face: PFontFace): TFontType{.cdecl,
    importc: "cairo_font_face_get_type", libcairo.}
proc get_user_data*(font_face: PFontFace, key: PUserDataKey): pointer{.
    cdecl, importc: "cairo_font_face_get_user_data", libcairo.}
proc set_user_data*(font_face: PFontFace, key: PUserDataKey,
                    user_data: pointer, destroy: TDestroyFunc): TStatus{.
    cdecl, importc: "cairo_font_face_set_user_data", libcairo.}
  #* Portable interface to general font features
proc scaled_font_create*(font_face: PFontFace, font_matrix: PMatrix,
                         ctm: PMatrix, options: PFontOptions): PScaledFont{.
    cdecl, importc: "cairo_scaled_font_create", libcairo.}
proc reference*(scaled_font: PScaledFont): PScaledFont{.cdecl,
    importc: "cairo_scaled_font_reference", libcairo.}
proc destroy*(scaled_font: PScaledFont){.cdecl,
    importc: "cairo_scaled_font_destroy", libcairo.}
proc get_reference_count*(scaled_font: PScaledFont): int32{.cdecl,
    importc: "cairo_scaled_font_get_reference_count", libcairo.}
proc status*(scaled_font: PScaledFont): TStatus{.cdecl,
    importc: "cairo_scaled_font_status", libcairo.}
proc get_type*(scaled_font: PScaledFont): TFontType{.cdecl,
    importc: "cairo_scaled_font_get_type", libcairo.}
proc get_user_data*(scaled_font: PScaledFont, key: PUserDataKey): Pointer{.
    cdecl, importc: "cairo_scaled_font_get_user_data", libcairo.}
proc set_user_data*(scaled_font: PScaledFont, key: PUserDataKey,
                    user_data: Pointer, destroy: TDestroyFunc): TStatus{.
    cdecl, importc: "cairo_scaled_font_set_user_data", libcairo.}
proc extents*(scaled_font: PScaledFont, extents: PFontExtents){.
    cdecl, importc: "cairo_scaled_font_extents", libcairo.}
proc text_extents*(scaled_font: PScaledFont, utf8: cstring,
                   extents: PTextExtents){.cdecl,
    importc: "cairo_scaled_font_text_extents", libcairo.}
proc glyph_extents*(scaled_font: PScaledFont, glyphs: PGlyph,
                                num_glyphs: int32, extents: PTextExtents){.
    cdecl, importc: "cairo_scaled_font_glyph_extents", libcairo.}
proc get_font_face*(scaled_font: PScaledFont): PFontFace{.cdecl,
    importc: "cairo_scaled_font_get_font_face", libcairo.}
proc get_font_matrix*(scaled_font: PScaledFont, font_matrix: PMatrix){.
    cdecl, importc: "cairo_scaled_font_get_font_matrix", libcairo.}
proc get_ctm*(scaled_font: PScaledFont, ctm: PMatrix){.cdecl,
    importc: "cairo_scaled_font_get_ctm", libcairo.}
proc get_font_options*(scaled_font: PScaledFont,
                                   options: PFontOptions){.cdecl,
    importc: "cairo_scaled_font_get_font_options", libcairo.}
  #* Query functions
proc get_operator*(cr: PContext): TOperator{.cdecl, importc: "cairo_get_operator",
                                      libcairo.}
proc get_source*(cr: PContext): PPattern{.cdecl, importc: "cairo_get_source",
                                   libcairo.}
proc get_tolerance*(cr: PContext): float64{.cdecl, importc: "cairo_get_tolerance",
                                     libcairo.}
proc get_antialias*(cr: PContext): TAntialias{.cdecl, importc: "cairo_get_antialias",
                                        libcairo.}
proc get_current_point*(cr: PContext, x, y: var float64){.cdecl,
    importc: "cairo_get_current_point", libcairo.}
proc get_fill_rule*(cr: PContext): TFillRule{.cdecl, importc: "cairo_get_fill_rule",
                                       libcairo.}
proc get_line_width*(cr: PContext): float64{.cdecl, importc: "cairo_get_line_width",
                                      libcairo.}
proc get_line_cap*(cr: PContext): TLineCap{.cdecl, importc: "cairo_get_line_cap",
                                     libcairo.}
proc get_line_join*(cr: PContext): TLineJoin{.cdecl, importc: "cairo_get_line_join",
                                       libcairo.}
proc get_miter_limit*(cr: PContext): float64{.cdecl, importc: "cairo_get_miter_limit",
                                       libcairo.}
proc get_dash_count*(cr: PContext): int32{.cdecl, importc: "cairo_get_dash_count",
                                    libcairo.}
proc get_dash*(cr: PContext, dashes, offset: var float64){.cdecl,
    importc: "cairo_get_dash", libcairo.}
proc get_matrix*(cr: PContext, matrix: PMatrix){.cdecl, importc: "cairo_get_matrix",
    libcairo.}
proc get_target*(cr: PContext): PSurface{.cdecl, importc: "cairo_get_target",
                                   libcairo.}
proc get_group_target*(cr: PContext): PSurface{.cdecl,
    importc: "cairo_get_group_target", libcairo.}
proc copy_path*(cr: PContext): PPath{.cdecl, importc: "cairo_copy_path",
                               libcairo.}
proc copy_path_flat*(cr: PContext): PPath{.cdecl, importc: "cairo_copy_path_flat",
                                    libcairo.}
proc append_path*(cr: PContext, path: PPath){.cdecl, importc: "cairo_append_path",
                                       libcairo.}
proc destroy*(path: PPath){.cdecl, importc: "cairo_path_destroy",
                                 libcairo.}
  #* Error status queries
proc status*(cr: PContext): TStatus{.cdecl, importc: "cairo_status", libcairo.}
proc status_to_string*(status: TStatus): cstring{.cdecl,
    importc: "cairo_status_to_string", libcairo.}
  #* Surface manipulation
proc surface_create_similar*(other: PSurface, content: TContent,
                             width, height: int32): PSurface{.cdecl,
    importc: "cairo_surface_create_similar", libcairo.}
proc reference*(surface: PSurface): PSurface{.cdecl,
    importc: "cairo_surface_reference", libcairo.}
proc finish*(surface: PSurface){.cdecl, importc: "cairo_surface_finish",
    libcairo.}
proc destroy*(surface: PSurface){.cdecl,
    importc: "cairo_surface_destroy", libcairo.}
proc get_reference_count*(surface: PSurface): int32{.cdecl,
    importc: "cairo_surface_get_reference_count", libcairo.}
proc status*(surface: PSurface): TStatus{.cdecl,
    importc: "cairo_surface_status", libcairo.}
proc get_type*(surface: PSurface): TSurfaceType{.cdecl,
    importc: "cairo_surface_get_type", libcairo.}
proc get_content*(surface: PSurface): TContent{.cdecl,
    importc: "cairo_surface_get_content", libcairo.}
proc write_to_png*(surface: PSurface, filename: cstring): TStatus{.
    cdecl, importc: "cairo_surface_write_to_png", libcairo.}
proc write_to_png*(surface: PSurface, write_func: TWriteFunc,
                   closure: pointer): TStatus{.cdecl,
    importc: "cairo_surface_write_to_png_stream", libcairo.}
proc get_user_data*(surface: PSurface, key: PUserDataKey): pointer{.
    cdecl, importc: "cairo_surface_get_user_data", libcairo.}
proc set_user_data*(surface: PSurface, key: PUserDataKey,
                            user_data: pointer, destroy: TDestroyFunc): TStatus{.
    cdecl, importc: "cairo_surface_set_user_data", libcairo.}
proc get_font_options*(surface: PSurface, options: PFontOptions){.cdecl,
    importc: "cairo_surface_get_font_options", libcairo.}
proc flush*(surface: PSurface){.cdecl, importc: "cairo_surface_flush",
                                        libcairo.}
proc mark_dirty*(surface: PSurface){.cdecl,
    importc: "cairo_surface_mark_dirty", libcairo.}
proc mark_dirty_rectangle*(surface: PSurface, x, y, width, height: int32){.
    cdecl, importc: "cairo_surface_mark_dirty_rectangle", libcairo.}
proc set_device_offset*(surface: PSurface, x_offset, y_offset: float64){.
    cdecl, importc: "cairo_surface_set_device_offset", libcairo.}
proc get_device_offset*(surface: PSurface,
                                x_offset, y_offset: var float64){.cdecl,
    importc: "cairo_surface_get_device_offset", libcairo.}
proc set_fallback_resolution*(surface: PSurface, x_pixels_per_inch,
    y_pixels_per_inch: float64){.cdecl, importc: "cairo_surface_set_fallback_resolution",
                                 libcairo.}
  #* Image-surface functions
proc image_surface_create*(format: TFormat, width, height: int32): PSurface{.
    cdecl, importc: "cairo_image_surface_create", libcairo.}
proc image_surface_create*(data: Pbyte, format: TFormat,
                           width, height, stride: int32): PSurface{.
    cdecl, importc: "cairo_image_surface_create_for_data", libcairo.}
proc get_data*(surface: PSurface): cstring{.cdecl,
    importc: "cairo_image_surface_get_data", libcairo.}
proc get_format*(surface: PSurface): TFormat{.cdecl,
    importc: "cairo_image_surface_get_format", libcairo.}
proc get_width*(surface: PSurface): int32{.cdecl,
    importc: "cairo_image_surface_get_width", libcairo.}
proc get_height*(surface: PSurface): int32{.cdecl,
    importc: "cairo_image_surface_get_height", libcairo.}
proc get_stride*(surface: PSurface): int32{.cdecl,
    importc: "cairo_image_surface_get_stride", libcairo.}
proc image_surface_create_from_png*(filename: cstring): PSurface{.cdecl,
    importc: "cairo_image_surface_create_from_png", libcairo.}
proc image_surface_create_from_png*(read_func: TReadFunc,
    closure: pointer): PSurface{.cdecl, importc: "cairo_image_surface_create_from_png_stream",
                                 libcairo.}
  #* Pattern creation functions
proc pattern_create_rgb*(red, green, blue: float64): PPattern{.cdecl,
    importc: "cairo_pattern_create_rgb", libcairo.}
proc pattern_create_rgba*(red, green, blue, alpha: float64): PPattern{.cdecl,
    importc: "cairo_pattern_create_rgba", libcairo.}
proc pattern_create_for_surface*(surface: PSurface): PPattern{.cdecl,
    importc: "cairo_pattern_create_for_surface", libcairo.}
proc pattern_create_linear*(x0, y0, x1, y1: float64): PPattern{.cdecl,
    importc: "cairo_pattern_create_linear", libcairo.}
proc pattern_create_radial*(cx0, cy0, radius0, cx1, cy1, radius1: float64): PPattern{.
    cdecl, importc: "cairo_pattern_create_radial", libcairo.}
proc reference*(pattern: PPattern): PPattern{.cdecl,
    importc: "cairo_pattern_reference", libcairo.}
proc destroy*(pattern: PPattern){.cdecl,
    importc: "cairo_pattern_destroy", libcairo.}
proc get_reference_count*(pattern: PPattern): int32{.cdecl,
    importc: "cairo_pattern_get_reference_count", libcairo.}
proc status*(pattern: PPattern): TStatus{.cdecl,
    importc: "cairo_pattern_status", libcairo.}
proc get_user_data*(pattern: PPattern, key: PUserDataKey): Pointer{.
    cdecl, importc: "cairo_pattern_get_user_data", libcairo.}
proc set_user_data*(pattern: PPattern, key: PUserDataKey,
                    user_data: Pointer, destroy: TDestroyFunc): TStatus{.
    cdecl, importc: "cairo_pattern_set_user_data", libcairo.}
proc get_type*(pattern: PPattern): TPatternType{.cdecl,
    importc: "cairo_pattern_get_type", libcairo.}
proc add_color_stop_rgb*(pattern: PPattern,
                                 offset, red, green, blue: float64){.cdecl,
    importc: "cairo_pattern_add_color_stop_rgb", libcairo.}
proc add_color_stop_rgba*(pattern: PPattern,
                                  offset, red, green, blue, alpha: float64){.
    cdecl, importc: "cairo_pattern_add_color_stop_rgba", libcairo.}
proc set_matrix*(pattern: PPattern, matrix: PMatrix){.cdecl,
    importc: "cairo_pattern_set_matrix", libcairo.}
proc get_matrix*(pattern: PPattern, matrix: PMatrix){.cdecl,
    importc: "cairo_pattern_get_matrix", libcairo.}
proc set_extend*(pattern: PPattern, extend: TExtend){.cdecl,
    importc: "cairo_pattern_set_extend", libcairo.}
proc get_extend*(pattern: PPattern): TExtend{.cdecl,
    importc: "cairo_pattern_get_extend", libcairo.}
proc set_filter*(pattern: PPattern, filter: TFilter){.cdecl,
    importc: "cairo_pattern_set_filter", libcairo.}
proc get_filter*(pattern: PPattern): TFilter{.cdecl,
    importc: "cairo_pattern_get_filter", libcairo.}
proc get_rgba*(pattern: PPattern,
               red, green, blue, alpha: var float64): TStatus{.
    cdecl, importc: "cairo_pattern_get_rgba", libcairo.}
proc get_surface*(pattern: PPattern, surface: PPSurface): TStatus{.
    cdecl, importc: "cairo_pattern_get_surface", libcairo.}
proc get_color_stop_rgba*(pattern: PPattern, index: int32,
                       offset, red, green, blue, alpha: var float64): TStatus{.
    cdecl, importc: "cairo_pattern_get_color_stop_rgba", libcairo.}
proc get_color_stop_count*(pattern: PPattern, count: var int32): TStatus{.
    cdecl, importc: "cairo_pattern_get_color_stop_count", libcairo.}
proc get_linear_points*(pattern: PPattern,
                        x0, y0, x1, y1: var float64): TStatus{.
    cdecl, importc: "cairo_pattern_get_linear_points", libcairo.}
proc get_radial_circles*(pattern: PPattern,
                         x0, y0, r0, x1, y1, r1: var float64): TStatus{.
    cdecl, importc: "cairo_pattern_get_radial_circles", libcairo.}
  #* Matrix functions
proc init*(matrix: PMatrix, xx, yx, xy, yy, x0, y0: float64){.cdecl,
    importc: "cairo_matrix_init", libcairo.}
proc init_identity*(matrix: PMatrix){.cdecl,
    importc: "cairo_matrix_init_identity", libcairo.}
proc init_translate*(matrix: PMatrix, tx, ty: float64){.cdecl,
    importc: "cairo_matrix_init_translate", libcairo.}
proc init_scale*(matrix: PMatrix, sx, sy: float64){.cdecl,
    importc: "cairo_matrix_init_scale", libcairo.}
proc init_rotate*(matrix: PMatrix, radians: float64){.cdecl,
    importc: "cairo_matrix_init_rotate", libcairo.}
proc translate*(matrix: PMatrix, tx, ty: float64){.cdecl,
    importc: "cairo_matrix_translate", libcairo.}
proc scale*(matrix: PMatrix, sx, sy: float64){.cdecl,
    importc: "cairo_matrix_scale", libcairo.}
proc rotate*(matrix: PMatrix, radians: float64){.cdecl,
    importc: "cairo_matrix_rotate", libcairo.}
proc invert*(matrix: PMatrix): TStatus{.cdecl,
    importc: "cairo_matrix_invert", libcairo.}
proc multiply*(result, a, b: PMatrix){.cdecl,
    importc: "cairo_matrix_multiply", libcairo.}
proc transform_distance*(matrix: PMatrix, dx, dy: var float64){.cdecl,
    importc: "cairo_matrix_transform_distance", libcairo.}
proc transform_point*(matrix: PMatrix, x, y: var float64){.cdecl,
    importc: "cairo_matrix_transform_point", libcairo.}
  #* PDF functions
proc pdf_surface_create*(filename: cstring,
                         width_in_points, height_in_points: float64): PSurface{.
    cdecl, importc: "cairo_pdf_surface_create", libcairo.}
proc pdf_surface_create_for_stream*(write_func: TWriteFunc, closure: Pointer,
                                    width_in_points, height_in_points: float64): PSurface{.
    cdecl, importc: "cairo_pdf_surface_create_for_stream", libcairo.}
proc pdf_surface_set_size*(surface: PSurface,
                           width_in_points, height_in_points: float64){.cdecl,
    importc: "cairo_pdf_surface_set_size", libcairo.}
  #* PS functions
proc ps_surface_create*(filename: cstring,
                        width_in_points, height_in_points: float64): PSurface{.
    cdecl, importc: "cairo_ps_surface_create", libcairo.}
proc ps_surface_create_for_stream*(write_func: TWriteFunc, closure: Pointer,
                                   width_in_points, height_in_points: float64): PSurface{.
    cdecl, importc: "cairo_ps_surface_create_for_stream", libcairo.}
proc ps_surface_set_size*(surface: PSurface,
                          width_in_points, height_in_points: float64){.cdecl,
    importc: "cairo_ps_surface_set_size", libcairo.}
proc ps_surface_dsc_comment*(surface: PSurface, comment: cstring){.cdecl,
    importc: "cairo_ps_surface_dsc_comment", libcairo.}
proc ps_surface_dsc_begin_setup*(surface: PSurface){.cdecl,
    importc: "cairo_ps_surface_dsc_begin_setup", libcairo.}
proc ps_surface_dsc_begin_page_setup*(surface: PSurface){.cdecl,
    importc: "cairo_ps_surface_dsc_begin_page_setup", libcairo.}
  #* SVG functions
proc svg_surface_create*(filename: cstring,
                         width_in_points, height_in_points: float64): PSurface{.
    cdecl, importc: "cairo_svg_surface_create", libcairo.}
proc svg_surface_create_for_stream*(write_func: TWriteFunc, closure: Pointer,
                                    width_in_points, height_in_points: float64): PSurface{.
    cdecl, importc: "cairo_svg_surface_create_for_stream", libcairo.}
proc svg_surface_restrict_to_version*(surface: PSurface, version: TSvgVersion){.
    cdecl, importc: "cairo_svg_surface_restrict_to_version", libcairo.}
  #todo: see how translate this
  #procedure cairo_svg_get_versions(TCairoSvgVersion const	**versions,
  #                        int                      	 *num_versions);
proc svg_version_to_string*(version: TSvgVersion): cstring{.cdecl,
    importc: "cairo_svg_version_to_string", libcairo.}
  #* Functions to be used while debugging (not intended for use in production code)
proc debug_reset_static_data*(){.cdecl,
                                 importc: "cairo_debug_reset_static_data",
                                 libcairo.}
# implementation

proc version(major, minor, micro: var int32) =
  var version: int32
  version = version()
  major = version div 10000'i32
  minor = (version mod (major * 10000'i32)) div 100'i32
  micro = (version mod ((major * 10000'i32) + (minor * 100'i32)))

proc checkStatus*(s: cairo.TStatus) {.noinline.} =
  ## if ``s != StatusSuccess`` the error is turned into an appropirate Nimrod
  ## exception and raised.
  case s
  of StatusSuccess: nil
  of StatusNoMemory:
    raise newException(EOutOfMemory, $statusToString(s))
  of STATUS_READ_ERROR, STATUS_WRITE_ERROR, STATUS_FILE_NOT_FOUND,
     STATUS_TEMP_FILE_ERROR:
    raise newException(EIO, $statusToString(s))
  else:
    raise newException(EAssertionFailed, $statusToString(s))


