{.deadCodeElim: on.}
import
  glib2

when defined(win32):
  const
    pixbuflib = "libgdk_pixbuf-2.0-0.dll"
elif defined(macosx):
  const
    pixbuflib = "libgdk_pixbuf-2.0.0.dylib"
  # linklib gtk-x11-2.0
  # linklib gdk-x11-2.0
  # linklib pango-1.0.0
  # linklib glib-2.0.0
  # linklib gobject-2.0.0
  # linklib gdk_pixbuf-2.0.0
  # linklib atk-1.0.0
else:
  const
    pixbuflib = "libgdk_pixbuf-2.0.so"
type
  PPixbuf* = pointer
  PPixbufAnimation* = pointer
  PPixbufAnimationIter* = pointer
  PPixbufAlphaMode* = ptr TPixbufAlphaMode
  TPixbufAlphaMode* = enum
    PIXBUF_ALPHA_BILEVEL, PIXBUF_ALPHA_FULL
  PColorspace* = ptr TColorspace
  TColorspace* = enum
    COLORSPACE_RGB
  TPixbufDestroyNotify* = proc (pixels: Pguchar, data: gpointer){.cdecl.}
  PPixbufError* = ptr TPixbufError
  TPixbufError* = enum
    PIXBUF_ERROR_CORRUPT_IMAGE, PIXBUF_ERROR_INSUFFICIENT_MEMORY,
    PIXBUF_ERROR_BAD_OPTION, PIXBUF_ERROR_UNKNOWN_TYPE,
    PIXBUF_ERROR_UNSUPPORTED_OPERATION, PIXBUF_ERROR_FAILED
  PInterpType* = ptr TInterpType
  TInterpType* = enum
    INTERP_NEAREST, INTERP_TILES, INTERP_BILINEAR, INTERP_HYPER

proc TYPE_PIXBUF*(): GType
proc PIXBUF*(anObject: pointer): PPixbuf
proc IS_PIXBUF*(anObject: pointer): bool
proc TYPE_PIXBUF_ANIMATION*(): GType
proc PIXBUF_ANIMATION*(anObject: pointer): PPixbufAnimation
proc IS_PIXBUF_ANIMATION*(anObject: pointer): bool
proc TYPE_PIXBUF_ANIMATION_ITER*(): GType
proc PIXBUF_ANIMATION_ITER*(anObject: pointer): PPixbufAnimationIter
proc IS_PIXBUF_ANIMATION_ITER*(anObject: pointer): bool
proc PIXBUF_ERROR*(): TGQuark
proc pixbuf_error_quark*(): TGQuark{.cdecl, dynlib: pixbuflib,
                                     importc: "gdk_pixbuf_error_quark".}
proc pixbuf_get_type*(): GType{.cdecl, dynlib: pixbuflib,
                                importc: "gdk_pixbuf_get_type".}
when not defined(PIXBUF_DISABLE_DEPRECATED):
  proc pixbuf_ref*(pixbuf: PPixbuf): PPixbuf{.cdecl, dynlib: pixbuflib,
      importc: "gdk_pixbuf_ref".}
  proc pixbuf_unref*(pixbuf: PPixbuf){.cdecl, dynlib: pixbuflib,
                                       importc: "gdk_pixbuf_unref".}
proc get_colorspace*(pixbuf: PPixbuf): TColorspace{.cdecl,
    dynlib: pixbuflib, importc: "gdk_pixbuf_get_colorspace".}
proc get_n_channels*(pixbuf: PPixbuf): int32{.cdecl, dynlib: pixbuflib,
    importc: "gdk_pixbuf_get_n_channels".}
proc get_has_alpha*(pixbuf: PPixbuf): gboolean{.cdecl, dynlib: pixbuflib,
    importc: "gdk_pixbuf_get_has_alpha".}
proc get_bits_per_sample*(pixbuf: PPixbuf): int32{.cdecl,
    dynlib: pixbuflib, importc: "gdk_pixbuf_get_bits_per_sample".}
proc get_pixels*(pixbuf: PPixbuf): Pguchar{.cdecl, dynlib: pixbuflib,
    importc: "gdk_pixbuf_get_pixels".}
proc get_width*(pixbuf: PPixbuf): int32{.cdecl, dynlib: pixbuflib,
    importc: "gdk_pixbuf_get_width".}
proc get_height*(pixbuf: PPixbuf): int32{.cdecl, dynlib: pixbuflib,
    importc: "gdk_pixbuf_get_height".}
proc get_rowstride*(pixbuf: PPixbuf): int32{.cdecl, dynlib: pixbuflib,
    importc: "gdk_pixbuf_get_rowstride".}
proc pixbuf_new*(colorspace: TColorspace, has_alpha: gboolean,
                 bits_per_sample: int32, width: int32, height: int32): PPixbuf{.
    cdecl, dynlib: pixbuflib, importc: "gdk_pixbuf_new".}
proc copy*(pixbuf: PPixbuf): PPixbuf{.cdecl, dynlib: pixbuflib,
    importc: "gdk_pixbuf_copy".}
proc new_subpixbuf*(src_pixbuf: PPixbuf, src_x: int32, src_y: int32,
                           width: int32, height: int32): PPixbuf{.cdecl,
    dynlib: pixbuflib, importc: "gdk_pixbuf_new_subpixbuf".}
proc pixbuf_new_from_file*(filename: cstring, error: pointer): PPixbuf{.cdecl,
    dynlib: pixbuflib, importc: "gdk_pixbuf_new_from_file".}
proc pixbuf_new_from_data*(data: Pguchar, colorspace: TColorspace,
                           has_alpha: gboolean, bits_per_sample: int32,
                           width: int32, height: int32, rowstride: int32,
                           destroy_fn: TPixbufDestroyNotify,
                           destroy_fn_data: gpointer): PPixbuf{.cdecl,
    dynlib: pixbuflib, importc: "gdk_pixbuf_new_from_data".}
proc pixbuf_new_from_xpm_data*(data: PPchar): PPixbuf{.cdecl, dynlib: pixbuflib,
    importc: "gdk_pixbuf_new_from_xpm_data".}
proc pixbuf_new_from_inline*(data_length: gint, a: var guint8,
                             copy_pixels: gboolean, error: pointer): PPixbuf{.
    cdecl, dynlib: pixbuflib, importc: "gdk_pixbuf_new_from_inline".}
proc pixbuf_new_from_file_at_size*(filename: cstring, width, height: gint,
                                   error: pointer): PPixbuf{.cdecl,
    dynlib: pixbuflib, importc: "gdk_pixbuf_new_from_file_at_size".}
proc pixbuf_new_from_file_at_scale*(filename: cstring, width, height: gint,
                                    preserve_aspect_ratio: gboolean,
                                    error: pointer): PPixbuf{.cdecl,
    dynlib: pixbuflib, importc: "gdk_pixbuf_new_from_file_at_scale".}
proc fill*(pixbuf: PPixbuf, pixel: guint32){.cdecl, dynlib: pixbuflib,
    importc: "gdk_pixbuf_fill".}
proc save*(pixbuf: PPixbuf, filename: cstring, `type`: cstring,
                  error: pointer): gboolean{.cdecl, varargs, dynlib: pixbuflib,
    importc: "gdk_pixbuf_save".}
proc savev*(pixbuf: PPixbuf, filename: cstring, `type`: cstring,
                   option_keys: PPchar, option_values: PPchar, error: pointer): gboolean{.
    cdecl, dynlib: pixbuflib, importc: "gdk_pixbuf_savev".}
proc add_alpha*(pixbuf: PPixbuf, substitute_color: gboolean, r: guchar,
                       g: guchar, b: guchar): PPixbuf{.cdecl, dynlib: pixbuflib,
    importc: "gdk_pixbuf_add_alpha".}
proc copy_area*(src_pixbuf: PPixbuf, src_x: int32, src_y: int32,
                       width: int32, height: int32, dest_pixbuf: PPixbuf,
                       dest_x: int32, dest_y: int32){.cdecl, dynlib: pixbuflib,
    importc: "gdk_pixbuf_copy_area".}
proc saturate_and_pixelate*(src: PPixbuf, dest: PPixbuf,
                                   saturation: gfloat, pixelate: gboolean){.
    cdecl, dynlib: pixbuflib, importc: "gdk_pixbuf_saturate_and_pixelate".}
proc scale*(src: PPixbuf, dest: PPixbuf, dest_x: int32, dest_y: int32,
                   dest_width: int32, dest_height: int32, offset_x: float64,
                   offset_y: float64, scale_x: float64, scale_y: float64,
                   interp_type: TInterpType){.cdecl, dynlib: pixbuflib,
    importc: "gdk_pixbuf_scale".}
proc composite*(src: PPixbuf, dest: PPixbuf, dest_x: int32,
                       dest_y: int32, dest_width: int32, dest_height: int32,
                       offset_x: float64, offset_y: float64, scale_x: float64,
                       scale_y: float64, interp_type: TInterpType,
                       overall_alpha: int32){.cdecl, dynlib: pixbuflib,
    importc: "gdk_pixbuf_composite".}
proc composite_color*(src: PPixbuf, dest: PPixbuf, dest_x: int32,
                             dest_y: int32, dest_width: int32,
                             dest_height: int32, offset_x: float64,
                             offset_y: float64, scale_x: float64,
                             scale_y: float64, interp_type: TInterpType,
                             overall_alpha: int32, check_x: int32,
                             check_y: int32, check_size: int32, color1: guint32,
                             color2: guint32){.cdecl, dynlib: pixbuflib,
    importc: "gdk_pixbuf_composite_color".}
proc scale_simple*(src: PPixbuf, dest_width: int32, dest_height: int32,
                          interp_type: TInterpType): PPixbuf{.cdecl,
    dynlib: pixbuflib, importc: "gdk_pixbuf_scale_simple".}
proc composite_color_simple*(src: PPixbuf, dest_width: int32,
                                    dest_height: int32,
                                    interp_type: TInterpType,
                                    overall_alpha: int32, check_size: int32,
                                    color1: guint32, color2: guint32): PPixbuf{.
    cdecl, dynlib: pixbuflib, importc: "gdk_pixbuf_composite_color_simple".}
proc pixbuf_animation_get_type*(): GType{.cdecl, dynlib: pixbuflib,
    importc: "gdk_pixbuf_animation_get_type".}
proc pixbuf_animation_new_from_file*(filename: cstring, error: pointer): PPixbufAnimation{.
    cdecl, dynlib: pixbuflib, importc: "gdk_pixbuf_animation_new_from_file".}
when not defined(PIXBUF_DISABLE_DEPRECATED):
  proc pixbuf_animation_ref*(animation: PPixbufAnimation): PPixbufAnimation{.
      cdecl, dynlib: pixbuflib, importc: "gdk_pixbuf_animation_ref".}
  proc pixbuf_animation_unref*(animation: PPixbufAnimation){.cdecl,
      dynlib: pixbuflib, importc: "gdk_pixbuf_animation_unref".}
proc get_width*(animation: PPixbufAnimation): int32{.cdecl,
    dynlib: pixbuflib, importc: "gdk_pixbuf_animation_get_width".}
proc get_height*(animation: PPixbufAnimation): int32{.cdecl,
    dynlib: pixbuflib, importc: "gdk_pixbuf_animation_get_height".}
proc is_static_image*(animation: PPixbufAnimation): gboolean{.
    cdecl, dynlib: pixbuflib, importc: "gdk_pixbuf_animation_is_static_image".}
proc get_static_image*(animation: PPixbufAnimation): PPixbuf{.
    cdecl, dynlib: pixbuflib, importc: "gdk_pixbuf_animation_get_static_image".}
proc get_iter*(animation: PPixbufAnimation, e: var TGTimeVal): PPixbufAnimationIter{.
    cdecl, dynlib: pixbuflib, importc: "gdk_pixbuf_animation_get_iter".}
proc pixbuf_animation_iter_get_type*(): GType{.cdecl, dynlib: pixbuflib,
    importc: "gdk_pixbuf_animation_iter_get_type".}
proc iter_get_delay_time*(iter: PPixbufAnimationIter): int32{.
    cdecl, dynlib: pixbuflib,
    importc: "gdk_pixbuf_animation_iter_get_delay_time".}
proc iter_get_pixbuf*(iter: PPixbufAnimationIter): PPixbuf{.
    cdecl, dynlib: pixbuflib, importc: "gdk_pixbuf_animation_iter_get_pixbuf".}
proc pixbuf_animation_iter_on_currently_loading_frame*(
    iter: PPixbufAnimationIter): gboolean{.cdecl, dynlib: pixbuflib,
    importc: "gdk_pixbuf_animation_iter_on_currently_loading_frame".}
proc iter_advance*(iter: PPixbufAnimationIter, e: var TGTimeVal): gboolean{.
    cdecl, dynlib: pixbuflib, importc: "gdk_pixbuf_animation_iter_advance".}
proc get_option*(pixbuf: PPixbuf, key: cstring): cstring{.cdecl,
    dynlib: pixbuflib, importc: "gdk_pixbuf_get_option".}
type
  PPixbufLoader* = ptr TPixbufLoader
  TPixbufLoader*{.final, pure.} = object
    parent_instance*: TGObject
    priv*: gpointer

  PPixbufLoaderClass* = ptr TPixbufLoaderClass
  TPixbufLoaderClass*{.final, pure.} = object
    parent_class*: TGObjectClass
    area_prepared*: proc (loader: PPixbufLoader){.cdecl.}
    area_updated*: proc (loader: PPixbufLoader, x: int32, y: int32,
                         width: int32, height: int32){.cdecl.}
    closed*: proc (loader: PPixbufLoader){.cdecl.}


proc TYPE_PIXBUF_LOADER*(): GType
proc PIXBUF_LOADER*(obj: pointer): PPixbufLoader
proc PIXBUF_LOADER_CLASS*(klass: pointer): PPixbufLoaderClass
proc IS_PIXBUF_LOADER*(obj: pointer): bool
proc IS_PIXBUF_LOADER_CLASS*(klass: pointer): bool
proc PIXBUF_LOADER_GET_CLASS*(obj: pointer): PPixbufLoaderClass
proc pixbuf_loader_get_type*(): GType{.cdecl, dynlib: pixbuflib,
                                       importc: "gdk_pixbuf_loader_get_type".}
proc pixbuf_loader_new*(): PPixbufLoader{.cdecl, dynlib: pixbuflib,
    importc: "gdk_pixbuf_loader_new".}
proc pixbuf_loader_new*(image_type: cstring, error: pointer): PPixbufLoader{.
    cdecl, dynlib: pixbuflib, importc: "gdk_pixbuf_loader_new_with_type".}
proc write*(loader: PPixbufLoader, buf: Pguchar, count: gsize,
                          error: pointer): gboolean{.cdecl, dynlib: pixbuflib,
    importc: "gdk_pixbuf_loader_write".}
proc get_pixbuf*(loader: PPixbufLoader): PPixbuf{.cdecl,
    dynlib: pixbuflib, importc: "gdk_pixbuf_loader_get_pixbuf".}
proc get_animation*(loader: PPixbufLoader): PPixbufAnimation{.
    cdecl, dynlib: pixbuflib, importc: "gdk_pixbuf_loader_get_animation".}
proc close*(loader: PPixbufLoader, error: pointer): gboolean{.
    cdecl, dynlib: pixbuflib, importc: "gdk_pixbuf_loader_close".}
proc TYPE_PIXBUF_LOADER*(): GType =
  result = pixbuf_loader_get_type()

proc PIXBUF_LOADER*(obj: pointer): PPixbufLoader =
  result = cast[PPixbufLoader](G_TYPE_CHECK_INSTANCE_CAST(obj,
      TYPE_PIXBUF_LOADER()))

proc PIXBUF_LOADER_CLASS*(klass: pointer): PPixbufLoaderClass =
  result = cast[PPixbufLoaderClass](G_TYPE_CHECK_CLASS_CAST(klass,
      TYPE_PIXBUF_LOADER()))

proc IS_PIXBUF_LOADER*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, TYPE_PIXBUF_LOADER())

proc IS_PIXBUF_LOADER_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_PIXBUF_LOADER())

proc PIXBUF_LOADER_GET_CLASS*(obj: pointer): PPixbufLoaderClass =
  result = cast[PPixbufLoaderClass](G_TYPE_INSTANCE_GET_CLASS(obj,
      TYPE_PIXBUF_LOADER()))

proc TYPE_PIXBUF*(): GType =
  result = pixbuf_get_type()

proc PIXBUF*(anObject: pointer): PPixbuf =
  result = cast[PPixbuf](G_TYPE_CHECK_INSTANCE_CAST(anObject, TYPE_PIXBUF()))

proc IS_PIXBUF*(anObject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_PIXBUF())

proc TYPE_PIXBUF_ANIMATION*(): GType =
  result = pixbuf_animation_get_type()

proc PIXBUF_ANIMATION*(anObject: pointer): PPixbufAnimation =
  result = cast[PPixbufAnimation](G_TYPE_CHECK_INSTANCE_CAST(anObject,
      TYPE_PIXBUF_ANIMATION()))

proc IS_PIXBUF_ANIMATION*(anObject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_PIXBUF_ANIMATION())

proc TYPE_PIXBUF_ANIMATION_ITER*(): GType =
  result = pixbuf_animation_iter_get_type()

proc PIXBUF_ANIMATION_ITER*(anObject: pointer): PPixbufAnimationIter =
  result = cast[PPixbufAnimationIter](G_TYPE_CHECK_INSTANCE_CAST(anObject,
      TYPE_PIXBUF_ANIMATION_ITER()))

proc IS_PIXBUF_ANIMATION_ITER*(anObject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_PIXBUF_ANIMATION_ITER())

proc PIXBUF_ERROR*(): TGQuark =
  result = pixbuf_error_quark()
