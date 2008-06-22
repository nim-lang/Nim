
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
  cairo_status_t* = enum
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
  cairo_operator_t* = enum
    CAIRO_OPERATOR_CLEAR, CAIRO_OPERATOR_SOURCE, CAIRO_OPERATOR_OVER,
    CAIRO_OPERATOR_IN, CAIRO_OPERATOR_OUT, CAIRO_OPERATOR_ATOP,
    CAIRO_OPERATOR_DEST, CAIRO_OPERATOR_DEST_OVER, CAIRO_OPERATOR_DEST_IN,
    CAIRO_OPERATOR_DEST_OUT, CAIRO_OPERATOR_DEST_ATOP, CAIRO_OPERATOR_XOR,
    CAIRO_OPERATOR_ADD, CAIRO_OPERATOR_SATURATE
  cairo_antialias_t* = enum
    CAIRO_ANTIALIAS_DEFAULT, CAIRO_ANTIALIAS_NONE, CAIRO_ANTIALIAS_GRAY,
    CAIRO_ANTIALIAS_SUBPIXEL
  cairo_fill_rule_t* = enum
    CAIRO_FILL_RULE_WINDING, CAIRO_FILL_RULE_EVEN_ODD
  cairo_line_cap_t* = enum
    CAIRO_LINE_CAP_BUTT, CAIRO_LINE_CAP_ROUND, CAIRO_LINE_CAP_SQUARE
  cairo_line_join_t* = enum
    CAIRO_LINE_JOIN_MITER, CAIRO_LINE_JOIN_ROUND, CAIRO_LINE_JOIN_BEVEL
  cairo_font_slant_t* = enum
    CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_SLANT_ITALIC, CAIRO_FONT_SLANT_OBLIQUE
  cairo_font_weight_t* = enum
    CAIRO_FONT_WEIGHT_NORMAL, CAIRO_FONT_WEIGHT_BOLD
  cairo_subpixel_order_t* = enum
    CAIRO_SUBPIXEL_ORDER_DEFAULT, CAIRO_SUBPIXEL_ORDER_RGB,
    CAIRO_SUBPIXEL_ORDER_BGR, CAIRO_SUBPIXEL_ORDER_VRGB,
    CAIRO_SUBPIXEL_ORDER_VBGR
  cairo_hint_style_t* = enum
    CAIRO_HINT_STYLE_DEFAULT, CAIRO_HINT_STYLE_NONE, CAIRO_HINT_STYLE_SLIGHT,
    CAIRO_HINT_STYLE_MEDIUM, CAIRO_HINT_STYLE_FULL
  cairo_hint_metrics_t* = enum
    CAIRO_HINT_METRICS_DEFAULT, CAIRO_HINT_METRICS_OFF, CAIRO_HINT_METRICS_ON
  cairo_path_data_type_t* = enum
    CAIRO_PATH_MOVE_TO, CAIRO_PATH_LINE_TO, CAIRO_PATH_CURVE_TO,
    CAIRO_PATH_CLOSE_PATH
  cairo_content_t* = enum
    CAIRO_CONTENT_COLOR = 0x00001000, CAIRO_CONTENT_ALPHA = 0x00002000,
    CAIRO_CONTENT_COLOR_ALPHA = 0x00003000
  cairo_format_t* = enum
    CAIRO_FORMAT_ARGB32, CAIRO_FORMAT_RGB24, CAIRO_FORMAT_A8, CAIRO_FORMAT_A1
  cairo_extend_t* = enum
    CAIRO_EXTEND_NONE, CAIRO_EXTEND_REPEAT, CAIRO_EXTEND_REFLECT,
    CAIRO_EXTEND_PAD
  cairo_filter_t* = enum
    CAIRO_FILTER_FAST, CAIRO_FILTER_GOOD, CAIRO_FILTER_BEST,
    CAIRO_FILTER_NEAREST, CAIRO_FILTER_BILINEAR, CAIRO_FILTER_GAUSSIAN
  cairo_font_type_t* = enum
    CAIRO_FONT_TYPE_TOY, CAIRO_FONT_TYPE_FT, CAIRO_FONT_TYPE_WIN32,
    CAIRO_FONT_TYPE_ATSUI
  cairo_pattern_type_t* = enum
    CAIRO_PATTERN_TYPE_SOLID, CAIRO_PATTERN_TYPE_SURFACE,
    CAIRO_PATTERN_TYPE_LINEAR, CAIRO_PATTERN_TYPE_RADIAL
  cairo_surface_type_t* = enum
    CAIRO_SURFACE_TYPE_IMAGE, CAIRO_SURFACE_TYPE_PDF, CAIRO_SURFACE_TYPE_PS,
    CAIRO_SURFACE_TYPE_XLIB, CAIRO_SURFACE_TYPE_XCB, CAIRO_SURFACE_TYPE_GLITZ,
    CAIRO_SURFACE_TYPE_QUARTZ, CAIRO_SURFACE_TYPE_WIN32,
    CAIRO_SURFACE_TYPE_BEOS, CAIRO_SURFACE_TYPE_DIRECTFB,
    CAIRO_SURFACE_TYPE_SVG, CAIRO_SURFACE_TYPE_OS2
  cairo_svg_version_t* = enum
    CAIRO_SVG_VERSION_1_1, CAIRO_SVG_VERSION_1_2
  Pcairo_surface_t* = ref cairo_surface_t
  PPcairo_surface_t* = ref Pcairo_surface_t
  Pcairo_t* = ref cairo_t
  Pcairo_pattern_t* = ref cairo_pattern_t
  Pcairo_font_options_t* = ref cairo_font_options_t
  Pcairo_font_face_t* = ref cairo_font_face_t
  Pcairo_scaled_font_t* = ref cairo_scaled_font_t
  Pcairo_bool_t* = ref cairo_bool_t
  cairo_bool_t* = int32
  Pcairo_matrix_t* = ref cairo_matrix_t
  Pcairo_user_data_key_t* = ref cairo_user_data_key_t
  Pcairo_glyph_t* = ref cairo_glyph_t
  Pcairo_text_extents_t* = ref cairo_text_extents_t
  Pcairo_font_extents_t* = ref cairo_font_extents_t
  Pcairo_path_data_type_t* = ref cairo_path_data_type_t
  Pcairo_path_data_t* = ref cairo_path_data_t
  Pcairo_path_t* = ref cairo_path_t
  Pcairo_rectangle_t* = ref cairo_rectangle_t
  Pcairo_rectangle_list_t* = ref cairo_rectangle_list_t
  cairo_destroy_func_t* = proc (data: Pointer){.cdecl.}
  cairo_write_func_t* = proc (closure: Pointer, data: PByte, len: int32): cairo_status_t{.
      cdecl.}
  cairo_read_func_t* = proc (closure: Pointer, data: PByte, len: int32): cairo_status_t{.
      cdecl.}
  cairo_t* = record           #OPAQUE
  cairo_surface_t* = record   #OPAQUE
  cairo_pattern_t* = record   #OPAQUE
  cairo_scaled_font_t* = record #OPAQUE
  cairo_font_face_t* = record #OPAQUE
  cairo_font_options_t* = record #OPAQUE
  cairo_matrix_t* = record
    xx: float64
    yx: float64
    xy: float64
    yy: float64
    x0: float64
    y0: float64

  cairo_user_data_key_t* = record
    unused: int32

  cairo_glyph_t* = record
    index: int32
    x: float64
    y: float64

  cairo_text_extents_t* = record
    x_bearing: float64
    y_bearing: float64
    width: float64
    height: float64
    x_advance: float64
    y_advance: float64

  cairo_font_extents_t* = record
    ascent: float64
    descent: float64
    height: float64
    max_x_advance: float64
    max_y_advance: float64

  cairo_path_data_t* = record #* _type : cairo_path_data_type_t;
                              #       length : LongInt;
                              #    end
    x: float64
    y: float64

  cairo_path_t* = record
    status: cairo_status_t
    data: Pcairo_path_data_t
    num_data: int32

  cairo_rectangle_t* = record
    x, y, width, height: float64

  cairo_rectangle_list_t* = record
    status: cairo_status_t
    rectangles: Pcairo_rectangle_t
    num_rectangles: int32


proc cairo_version*(): int32{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_version_string*(): cstring{.cdecl, importc, dynlib: LIB_CAIRO.}
  #Helper function to retrieve decoded version
proc cairo_version*(major, minor, micro: var int32)
  #* Functions for manipulating state objects
proc cairo_create*(target: Pcairo_surface_t): Pcairo_t{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_reference*(cr: Pcairo_t): Pcairo_t{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_destroy*(cr: Pcairo_t){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_get_reference_count*(cr: Pcairo_t): int32{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_get_user_data*(cr: Pcairo_t, key: Pcairo_user_data_key_t): pointer{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_set_user_data*(cr: PCairo_t, key: Pcairo_user_data_key_t,
                          user_data: Pointer, destroy: cairo_destroy_func_t): cairo_status_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_save*(cr: Pcairo_t){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_restore*(cr: Pcairo_t){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_push_group*(cr: PCairo_t){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_push_group_with_content*(cr: PCairo_t, content: cairo_content_t){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pop_group*(cr: PCairo_t): Pcairo_pattern_t{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pop_group_to_source*(cr: PCairo_t){.cdecl, importc, dynlib: LIB_CAIRO.}
  #* Modify state
proc cairo_set_operator*(cr: Pcairo_t, op: cairo_operator_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_set_source*(cr: Pcairo_t, source: Pcairo_pattern_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_set_source_rgb*(cr: Pcairo_t, red, green, blue: float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_set_source_rgba*(cr: Pcairo_t, red, green, blue, alpha: float64){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_set_source_surface*(cr: Pcairo_t, surface: Pcairo_surface_t,
                               x, y: float64){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_set_tolerance*(cr: Pcairo_t, tolerance: float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_set_antialias*(cr: Pcairo_t, antialias: cairo_antialias_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_set_fill_rule*(cr: Pcairo_t, fill_rule: cairo_fill_rule_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_set_line_width*(cr: Pcairo_t, width: float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_set_line_cap*(cr: Pcairo_t, line_cap: cairo_line_cap_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_set_line_join*(cr: Pcairo_t, line_join: cairo_line_join_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_set_dash*(cr: Pcairo_t, dashes: openarray[float64],
                     offset: float64){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_set_miter_limit*(cr: Pcairo_t, limit: float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_translate*(cr: Pcairo_t, tx, ty: float64){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_scale*(cr: Pcairo_t, sx, sy: float64){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_rotate*(cr: Pcairo_t, angle: float64){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_transform*(cr: Pcairo_t, matrix: Pcairo_matrix_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_set_matrix*(cr: Pcairo_t, matrix: Pcairo_matrix_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_identity_matrix*(cr: Pcairo_t){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_user_to_device*(cr: Pcairo_t, x, y: var float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_user_to_device_distance*(cr: Pcairo_t, dx, dy: var float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_device_to_user*(cr: Pcairo_t, x, y: var float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_device_to_user_distance*(cr: Pcairo_t, dx, dy: var float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
  #* Path creation functions
proc cairo_new_path*(cr: Pcairo_t){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_move_to*(cr: Pcairo_t, x, y: float64){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_new_sub_path*(cr: Pcairo_t){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_line_to*(cr: Pcairo_t, x, y: float64){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_curve_to*(cr: Pcairo_t, x1, y1, x2, y2, x3, y3: float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_arc*(cr: Pcairo_t, xc, yc, radius, angle1, angle2: float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_arc_negative*(cr: Pcairo_t, xc, yc, radius, angle1, angle2: float64){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_rel_move_to*(cr: Pcairo_t, dx, dy: float64){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_rel_line_to*(cr: Pcairo_t, dx, dy: float64){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_rel_curve_to*(cr: Pcairo_t, dx1, dy1, dx2, dy2, dx3, dy3: float64){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_rectangle*(cr: Pcairo_t, x, y, width, height: float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_close_path*(cr: Pcairo_t){.cdecl, importc, dynlib: LIB_CAIRO.}
  #* Painting functions
proc cairo_paint*(cr: Pcairo_t){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_paint_with_alpha*(cr: Pcairo_t, alpha: float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_mask*(cr: Pcairo_t, pattern: Pcairo_pattern_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_mask_surface*(cr: Pcairo_t, surface: Pcairo_surface_t,
                         surface_x, surface_y: float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_stroke*(cr: Pcairo_t){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_stroke_preserve*(cr: Pcairo_t){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_fill*(cr: Pcairo_t){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_fill_preserve*(cr: Pcairo_t){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_copy_page*(cr: Pcairo_t){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_show_page*(cr: Pcairo_t){.cdecl, importc, dynlib: LIB_CAIRO.}
  #* Insideness testing
proc cairo_in_stroke*(cr: Pcairo_t, x, y: float64): cairo_bool_t{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_in_fill*(cr: Pcairo_t, x, y: float64): cairo_bool_t{.cdecl, importc,
    dynlib: LIB_CAIRO.}
  #* Rectangular extents
proc cairo_stroke_extents*(cr: Pcairo_t, x1, y1, x2, y2: var float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_fill_extents*(cr: Pcairo_t, x1, y1, x2, y2: var float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
  #* Clipping
proc cairo_reset_clip*(cr: Pcairo_t){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_clip*(cr: Pcairo_t){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_clip_preserve*(cr: Pcairo_t){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_clip_extents*(cr: Pcairo_t, x1, y1, x2, y2: var float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_copy_clip_rectangle_list*(cr: Pcairo_t): Pcairo_rectangle_list_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_rectangle_list_destroy*(rectangle_list: Pcairo_rectangle_list_t){.
    cdecl, importc, dynlib: LIB_CAIRO.}
  #* Font/Text functions
proc cairo_font_options_create*(): Pcairo_font_options_t{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_font_options_copy*(original: Pcairo_font_options_t): Pcairo_font_options_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_font_options_destroy*(options: Pcairo_font_options_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_font_options_status*(options: Pcairo_font_options_t): cairo_status_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_font_options_merge*(options, other: Pcairo_font_options_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_font_options_equal*(options, other: Pcairo_font_options_t): cairo_bool_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_font_options_hash*(options: Pcairo_font_options_t): int32{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_font_options_set_antialias*(options: Pcairo_font_options_t,
                                       antialias: cairo_antialias_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_font_options_get_antialias*(options: Pcairo_font_options_t): cairo_antialias_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_font_options_set_subpixel_order*(options: Pcairo_font_options_t,
    subpixel_order: cairo_subpixel_order_t){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_font_options_get_subpixel_order*(options: Pcairo_font_options_t): cairo_subpixel_order_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_font_options_set_hint_style*(options: Pcairo_font_options_t,
                                        hint_style: cairo_hint_style_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_font_options_get_hint_style*(options: Pcairo_font_options_t): cairo_hint_style_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_font_options_set_hint_metrics*(options: Pcairo_font_options_t,
    hint_metrics: cairo_hint_metrics_t){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_font_options_get_hint_metrics*(options: Pcairo_font_options_t): cairo_hint_metrics_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
  #* This interface is for dealing with text as text, not caring about the
  #   font object inside the the cairo_t.
proc cairo_select_font_face*(cr: Pcairo_t, family: cstring,
                             slant: cairo_font_slant_t,
                             weight: cairo_font_weight_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_set_font_size*(cr: Pcairo_t, size: float64){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_set_font_matrix*(cr: Pcairo_t, matrix: Pcairo_matrix_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_get_font_matrix*(cr: Pcairo_t, matrix: Pcairo_matrix_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_set_font_options*(cr: Pcairo_t, options: Pcairo_font_options_t){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_get_font_options*(cr: Pcairo_t, options: Pcairo_font_options_t){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_set_font_face*(cr: Pcairo_t, font_face: Pcairo_font_face_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_get_font_face*(cr: Pcairo_t): Pcairo_font_face_t{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_set_scaled_font*(cr: PCairo_t, scaled_font: Pcairo_scaled_font_t){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_get_scaled_font*(cr: Pcairo_t): Pcairo_scaled_font_t{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_show_text*(cr: Pcairo_t, utf8: cstring){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_show_glyphs*(cr: Pcairo_t, glyphs: Pcairo_glyph_t, num_glyphs: int32){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_text_path*(cr: Pcairo_t, utf8: cstring){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_glyph_path*(cr: Pcairo_t, glyphs: Pcairo_glyph_t, num_glyphs: int32){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_text_extents*(cr: Pcairo_t, utf8: cstring,
                         extents: Pcairo_text_extents_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_glyph_extents*(cr: Pcairo_t, glyphs: Pcairo_glyph_t,
                          num_glyphs: int32, extents: Pcairo_text_extents_t){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_font_extents*(cr: Pcairo_t, extents: Pcairo_font_extents_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
  #* Generic identifier for a font style
proc cairo_font_face_reference*(font_face: Pcairo_font_face_t): Pcairo_font_face_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_font_face_destroy*(font_face: Pcairo_font_face_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_font_face_get_reference_count*(font_face: Pcairo_font_face_t): int32{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_font_face_status*(font_face: Pcairo_font_face_t): cairo_status_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_font_face_get_type*(font_face: Pcairo_font_face_t): cairo_font_type_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_font_face_get_user_data*(font_face: Pcairo_font_face_t,
                                    key: Pcairo_user_data_key_t): pointer{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_font_face_set_user_data*(font_face: Pcairo_font_face_t,
                                    key: Pcairo_user_data_key_t,
                                    user_data: pointer,
                                    destroy: cairo_destroy_func_t): cairo_status_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
  #* Portable interface to general font features
proc cairo_scaled_font_create*(font_face: Pcairo_font_face_t,
                               font_matrix: Pcairo_matrix_t,
                               ctm: Pcairo_matrix_t,
                               options: Pcairo_font_options_t): Pcairo_scaled_font_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_scaled_font_reference*(scaled_font: Pcairo_scaled_font_t): Pcairo_scaled_font_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_scaled_font_destroy*(scaled_font: Pcairo_scaled_font_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_scaled_font_get_reference_count*(scaled_font: Pcairo_scaled_font_t): int32{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_scaled_font_status*(scaled_font: Pcairo_scaled_font_t): cairo_status_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_scaled_font_get_type*(scaled_font: Pcairo_scaled_font_t): cairo_font_type_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_scaled_font_get_user_data*(scaled_font: Pcairo_scaled_font_t,
                                      key: Pcairo_user_data_key_t): Pointer{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_scaled_font_set_user_data*(scaled_font: Pcairo_scaled_font_t,
                                      key: Pcairo_user_data_key_t,
                                      user_data: Pointer,
                                      destroy: cairo_destroy_func_t): cairo_status_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_scaled_font_extents*(scaled_font: Pcairo_scaled_font_t,
                                extents: Pcairo_font_extents_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_scaled_font_text_extents*(scaled_font: Pcairo_scaled_font_t,
                                     utf8: cstring,
                                     extents: Pcairo_text_extents_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_scaled_font_glyph_extents*(scaled_font: Pcairo_scaled_font_t,
                                      glyphs: Pcairo_glyph_t, num_glyphs: int32,
                                      extents: Pcairo_text_extents_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_scaled_font_get_font_face*(scaled_font: Pcairo_scaled_font_t): Pcairo_font_face_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_scaled_font_get_font_matrix*(scaled_font: Pcairo_scaled_font_t,
                                        font_matrix: Pcairo_matrix_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_scaled_font_get_ctm*(scaled_font: Pcairo_scaled_font_t,
                                ctm: Pcairo_matrix_t){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_scaled_font_get_font_options*(scaled_font: Pcairo_scaled_font_t,
    options: Pcairo_font_options_t){.cdecl, importc, dynlib: LIB_CAIRO.}
  #* Query functions
proc cairo_get_operator*(cr: Pcairo_t): cairo_operator_t{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_get_source*(cr: Pcairo_t): Pcairo_pattern_t{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_get_tolerance*(cr: Pcairo_t): float64{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_get_antialias*(cr: Pcairo_t): cairo_antialias_t{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_get_current_point*(cr: Pcairo_t, x, y: var float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_get_fill_rule*(cr: Pcairo_t): cairo_fill_rule_t{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_get_line_width*(cr: Pcairo_t): float64{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_get_line_cap*(cr: Pcairo_t): cairo_line_cap_t{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_get_line_join*(cr: Pcairo_t): cairo_line_join_t{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_get_miter_limit*(cr: Pcairo_t): float64{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_get_dash_count*(cr: Pcairo_t): int32{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_get_dash*(cr: Pcairo_t, dashes, offset: var float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_get_matrix*(cr: Pcairo_t, matrix: Pcairo_matrix_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_get_target*(cr: Pcairo_t): Pcairo_surface_t{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_get_group_target*(cr: Pcairo_t): Pcairo_surface_t{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_copy_path*(cr: Pcairo_t): Pcairo_path_t{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_copy_path_flat*(cr: Pcairo_t): Pcairo_path_t{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_append_path*(cr: Pcairo_t, path: Pcairo_path_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_path_destroy*(path: Pcairo_path_t){.cdecl, importc, dynlib: LIB_CAIRO.}
  #* Error status queries
proc cairo_status*(cr: Pcairo_t): cairo_status_t{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_status_to_string*(status: cairo_status_t): cstring{.cdecl, importc,
    dynlib: LIB_CAIRO.}
  #* Surface manipulation
proc cairo_surface_create_similar*(other: Pcairo_surface_t,
                                   content: cairo_content_t,
                                   width, height: int32): Pcairo_surface_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_surface_reference*(surface: Pcairo_surface_t): Pcairo_surface_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_surface_finish*(surface: Pcairo_surface_t){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_surface_destroy*(surface: Pcairo_surface_t){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_surface_get_reference_count*(surface: Pcairo_surface_t): int32{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_surface_status*(surface: Pcairo_surface_t): cairo_status_t{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_surface_get_type*(surface: Pcairo_surface_t): cairo_surface_type_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_surface_get_content*(surface: Pcairo_surface_t): cairo_content_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_surface_write_to_png*(surface: Pcairo_surface_t, filename: cstring): cairo_status_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_surface_write_to_png_stream*(surface: Pcairo_surface_t,
                                        write_func: cairo_write_func_t,
                                        closure: pointer): cairo_status_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_surface_get_user_data*(surface: Pcairo_surface_t,
                                  key: Pcairo_user_data_key_t): pointer{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_surface_set_user_data*(surface: Pcairo_surface_t,
                                  key: Pcairo_user_data_key_t,
                                  user_data: pointer,
                                  destroy: cairo_destroy_func_t): cairo_status_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_surface_get_font_options*(surface: Pcairo_surface_t,
                                     options: Pcairo_font_options_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_surface_flush*(surface: Pcairo_surface_t){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_surface_mark_dirty*(surface: Pcairo_surface_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_surface_mark_dirty_rectangle*(surface: Pcairo_surface_t,
    x, y, width, height: int32){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_surface_set_device_offset*(surface: Pcairo_surface_t,
                                      x_offset, y_offset: float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_surface_get_device_offset*(surface: Pcairo_surface_t,
                                      x_offset, y_offset: var float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_surface_set_fallback_resolution*(surface: Pcairo_surface_t,
    x_pixels_per_inch, y_pixels_per_inch: float64){.cdecl, importc, dynlib: LIB_CAIRO.}
  #* Image-surface functions
proc cairo_image_surface_create*(format: cairo_format_t, width, height: int32): Pcairo_surface_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_image_surface_create_for_data*(data: Pbyte, format: cairo_format_t,
    width, height, stride: int32): Pcairo_surface_t{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_image_surface_get_data*(surface: Pcairo_surface_t): cstring{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_image_surface_get_format*(surface: Pcairo_surface_t): cairo_format_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_image_surface_get_width*(surface: Pcairo_surface_t): int32{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_image_surface_get_height*(surface: Pcairo_surface_t): int32{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_image_surface_get_stride*(surface: Pcairo_surface_t): int32{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_image_surface_create_from_png*(filename: cstring): Pcairo_surface_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_image_surface_create_from_png_stream*(read_func: cairo_read_func_t,
    closure: pointer): Pcairo_surface_t{.cdecl, importc, dynlib: LIB_CAIRO.}
  #* Pattern creation functions
proc cairo_pattern_create_rgb*(red, green, blue: float64): Pcairo_pattern_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_create_rgba*(red, green, blue, alpha: float64): Pcairo_pattern_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_create_for_surface*(surface: Pcairo_surface_t): Pcairo_pattern_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_create_linear*(x0, y0, x1, y1: float64): Pcairo_pattern_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_create_radial*(cx0, cy0, radius0, cx1, cy1, radius1: float64): Pcairo_pattern_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_reference*(pattern: Pcairo_pattern_t): Pcairo_pattern_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_destroy*(pattern: Pcairo_pattern_t){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_get_reference_count*(pattern: Pcairo_pattern_t): int32{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_status*(pattern: Pcairo_pattern_t): cairo_status_t{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_pattern_get_user_data*(pattern: Pcairo_pattern_t,
                                  key: Pcairo_user_data_key_t): Pointer{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_pattern_set_user_data*(pattern: Pcairo_pattern_t,
                                  key: Pcairo_user_data_key_t,
                                  user_data: Pointer,
                                  destroy: cairo_destroy_func_t): cairo_status_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_get_type*(pattern: Pcairo_pattern_t): cairo_pattern_type_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_add_color_stop_rgb*(pattern: Pcairo_pattern_t,
                                       offset, red, green, blue: float64){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_add_color_stop_rgba*(pattern: Pcairo_pattern_t, offset, red,
    green, blue, alpha: float64){.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_set_matrix*(pattern: Pcairo_pattern_t,
                               matrix: Pcairo_matrix_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_pattern_get_matrix*(pattern: Pcairo_pattern_t,
                               matrix: Pcairo_matrix_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_pattern_set_extend*(pattern: Pcairo_pattern_t, extend: cairo_extend_t){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_get_extend*(pattern: Pcairo_pattern_t): cairo_extend_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_set_filter*(pattern: Pcairo_pattern_t, filter: cairo_filter_t){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_get_filter*(pattern: Pcairo_pattern_t): cairo_filter_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_get_rgba*(pattern: Pcairo_pattern_t,
                             red, green, blue, alpha: var float64): cairo_status_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_get_surface*(pattern: Pcairo_pattern_t,
                                surface: PPcairo_surface_t): cairo_status_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_get_color_stop_rgba*(pattern: Pcairo_pattern_t, index: int32,
    offset, red, green, blue, alpha: var float64): cairo_status_t{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_pattern_get_color_stop_count*(pattern: Pcairo_pattern_t,
    count: var int32): cairo_status_t{.cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_get_linear_points*(pattern: Pcairo_pattern_t,
                                      x0, y0, x1, y1: var float64): cairo_status_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pattern_get_radial_circles*(pattern: Pcairo_pattern_t,
                                       x0, y0, r0, x1, y1, r1: var float64): cairo_status_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
  #* Matrix functions
proc cairo_matrix_init*(matrix: Pcairo_matrix_t, xx, yx, xy, yy, x0, y0: float64){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_matrix_init_identity*(matrix: Pcairo_matrix_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_matrix_init_translate*(matrix: Pcairo_matrix_t, tx, ty: float64){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_matrix_init_scale*(matrix: Pcairo_matrix_t, sx, sy: float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_matrix_init_rotate*(matrix: Pcairo_matrix_t, radians: float64){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_matrix_translate*(matrix: Pcairo_matrix_t, tx, ty: float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_matrix_scale*(matrix: Pcairo_matrix_t, sx, sy: float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_matrix_rotate*(matrix: Pcairo_matrix_t, radians: float64){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_matrix_invert*(matrix: Pcairo_matrix_t): cairo_status_t{.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_matrix_multiply*(result, a, b: Pcairo_matrix_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_matrix_transform_distance*(matrix: Pcairo_matrix_t, dx, dy: var float64){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_matrix_transform_point*(matrix: Pcairo_matrix_t, x, y: var float64){.
    cdecl, importc, dynlib: LIB_CAIRO.}
  #* PDF functions
proc cairo_pdf_surface_create*(filename: cstring,
                               width_in_points, height_in_points: float64): Pcairo_surface_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pdf_surface_create_for_stream*(write_func: cairo_write_func_t,
    closure: Pointer, width_in_points, height_in_points: float64): Pcairo_surface_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_pdf_surface_set_size*(surface: Pcairo_surface_t,
                                 width_in_points, height_in_points: float64){.
    cdecl, importc, dynlib: LIB_CAIRO.}
  #* PS functions
proc cairo_ps_surface_create*(filename: cstring,
                              width_in_points, height_in_points: float64): Pcairo_surface_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_ps_surface_create_for_stream*(write_func: cairo_write_func_t,
    closure: Pointer, width_in_points, height_in_points: float64): Pcairo_surface_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_ps_surface_set_size*(surface: Pcairo_surface_t,
                                width_in_points, height_in_points: float64){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_ps_surface_dsc_comment*(surface: Pcairo_surface_t, comment: cstring){.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_ps_surface_dsc_begin_setup*(surface: Pcairo_surface_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
proc cairo_ps_surface_dsc_begin_page_setup*(surface: Pcairo_surface_t){.cdecl, importc,
    dynlib: LIB_CAIRO.}
  #* SVG functions
proc cairo_svg_surface_create*(filename: cstring,
                               width_in_points, height_in_points: float64): Pcairo_surface_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_svg_surface_create_for_stream*(write_func: cairo_write_func_t,
    closure: Pointer, width_in_points, height_in_points: float64): Pcairo_surface_t{.
    cdecl, importc, dynlib: LIB_CAIRO.}
proc cairo_svg_surface_restrict_to_version*(surface: Pcairo_surface_t,
    version: cairo_svg_version_t){.cdecl, importc, dynlib: LIB_CAIRO.}
  #todo: see how translate this
  #procedure cairo_svg_get_versions(cairo_svg_version_t const	**versions,
  #                        int                      	 *num_versions);
proc cairo_svg_version_to_string*(version: cairo_svg_version_t): cstring{.cdecl, importc,
    dynlib: LIB_CAIRO.}
  #* Functions to be used while debugging (not intended for use in production code)
proc cairo_debug_reset_static_data*(){.cdecl, importc, dynlib: LIB_CAIRO.}
# implementation

proc cairo_version(major, minor, micro: var int32) =
  var version: int32
  version = cairo_version()
  major = version div 10000
  minor = (version mod (major * 10000)) div 100
  micro = (version mod ((major * 10000) + (minor * 100)))
