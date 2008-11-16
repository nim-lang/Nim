import
  glib2

when defined(win32):
  const
    gdkpixbuflib = "libgdk_pixbuf-2.0-0.dll"
elif defined(darwin):
  const
    gdkpixbuflib = "gdk_pixbuf-2.0.0"
  # linklib gtk-x11-2.0
  # linklib gdk-x11-2.0
  # linklib pango-1.0.0
  # linklib glib-2.0.0
  # linklib gobject-2.0.0
  # linklib gdk_pixbuf-2.0.0
  # linklib atk-1.0.0
else:
  const
    gdkpixbuflib = "libgdk_pixbuf-2.0.so"

type
  PGdkPixbuf* = pointer
  PGdkPixbufAnimation* = pointer
  PGdkPixbufAnimationIter* = pointer
  PGdkPixbufAlphaMode* = ptr TGdkPixbufAlphaMode
  TGdkPixbufAlphaMode* = enum
    GDK_PIXBUF_ALPHA_BILEVEL, GDK_PIXBUF_ALPHA_FULL
  PGdkColorspace* = ptr TGdkColorspace
  TGdkColorspace* = enum
    GDK_COLORSPACE_RGB
  TGdkPixbufDestroyNotify* = proc (pixels: Pguchar, data: gpointer){.cdecl.}
  PGdkPixbufError* = ptr TGdkPixbufError
  TGdkPixbufError* = enum
    GDK_PIXBUF_ERROR_CORRUPT_IMAGE, GDK_PIXBUF_ERROR_INSUFFICIENT_MEMORY,
    GDK_PIXBUF_ERROR_BAD_OPTION, GDK_PIXBUF_ERROR_UNKNOWN_TYPE,
    GDK_PIXBUF_ERROR_UNSUPPORTED_OPERATION, GDK_PIXBUF_ERROR_FAILED
  PGdkInterpType* = ptr TGdkInterpType
  TGdkInterpType* = enum
    GDK_INTERP_NEAREST, GDK_INTERP_TILES, GDK_INTERP_BILINEAR, GDK_INTERP_HYPER

proc GDK_TYPE_PIXBUF*(): GType
proc GDK_PIXBUF*(anObject: pointer): PGdkPixbuf
proc GDK_IS_PIXBUF*(anObject: pointer): bool
proc GDK_TYPE_PIXBUF_ANIMATION*(): GType
proc GDK_PIXBUF_ANIMATION*(anObject: pointer): PGdkPixbufAnimation
proc GDK_IS_PIXBUF_ANIMATION*(anObject: pointer): bool
proc GDK_TYPE_PIXBUF_ANIMATION_ITER*(): GType
proc GDK_PIXBUF_ANIMATION_ITER*(anObject: pointer): PGdkPixbufAnimationIter
proc GDK_IS_PIXBUF_ANIMATION_ITER*(anObject: pointer): bool
proc GDK_PIXBUF_ERROR*(): TGQuark
proc gdk_pixbuf_error_quark*(): TGQuark{.cdecl, dynlib: gdkpixbuflib,
    importc: "gdk_pixbuf_error_quark".}
proc gdk_pixbuf_get_type*(): GType{.cdecl, dynlib: gdkpixbuflib,
                                    importc: "gdk_pixbuf_get_type".}
when not defined(GDK_PIXBUF_DISABLE_DEPRECATED):
  proc gdk_pixbuf_ref*(pixbuf: PGdkPixbuf): PGdkPixbuf{.cdecl,
      dynlib: gdkpixbuflib, importc: "gdk_pixbuf_ref".}
  proc gdk_pixbuf_unref*(pixbuf: PGdkPixbuf){.cdecl, dynlib: gdkpixbuflib,
      importc: "gdk_pixbuf_unref".}
proc gdk_pixbuf_get_colorspace*(pixbuf: PGdkPixbuf): TGdkColorspace{.cdecl,
    dynlib: gdkpixbuflib, importc: "gdk_pixbuf_get_colorspace".}
proc gdk_pixbuf_get_n_channels*(pixbuf: PGdkPixbuf): int32{.cdecl,
    dynlib: gdkpixbuflib, importc: "gdk_pixbuf_get_n_channels".}
proc gdk_pixbuf_get_has_alpha*(pixbuf: PGdkPixbuf): gboolean{.cdecl,
    dynlib: gdkpixbuflib, importc: "gdk_pixbuf_get_has_alpha".}
proc gdk_pixbuf_get_bits_per_sample*(pixbuf: PGdkPixbuf): int32{.cdecl,
    dynlib: gdkpixbuflib, importc: "gdk_pixbuf_get_bits_per_sample".}
proc gdk_pixbuf_get_pixels*(pixbuf: PGdkPixbuf): Pguchar{.cdecl,
    dynlib: gdkpixbuflib, importc: "gdk_pixbuf_get_pixels".}
proc gdk_pixbuf_get_width*(pixbuf: PGdkPixbuf): int32{.cdecl,
    dynlib: gdkpixbuflib, importc: "gdk_pixbuf_get_width".}
proc gdk_pixbuf_get_height*(pixbuf: PGdkPixbuf): int32{.cdecl,
    dynlib: gdkpixbuflib, importc: "gdk_pixbuf_get_height".}
proc gdk_pixbuf_get_rowstride*(pixbuf: PGdkPixbuf): int32{.cdecl,
    dynlib: gdkpixbuflib, importc: "gdk_pixbuf_get_rowstride".}
proc gdk_pixbuf_new*(colorspace: TGdkColorspace, has_alpha: gboolean,
                     bits_per_sample: int32, width: int32, height: int32): PGdkPixbuf{.
    cdecl, dynlib: gdkpixbuflib, importc: "gdk_pixbuf_new".}
proc gdk_pixbuf_copy*(pixbuf: PGdkPixbuf): PGdkPixbuf{.cdecl,
    dynlib: gdkpixbuflib, importc: "gdk_pixbuf_copy".}
proc gdk_pixbuf_new_subpixbuf*(src_pixbuf: PGdkPixbuf, src_x: int32,
                               src_y: int32, width: int32, height: int32): PGdkPixbuf{.
    cdecl, dynlib: gdkpixbuflib, importc: "gdk_pixbuf_new_subpixbuf".}
proc gdk_pixbuf_new_from_file*(filename: cstring, error: pointer): PGdkPixbuf{.
    cdecl, dynlib: gdkpixbuflib, importc: "gdk_pixbuf_new_from_file".}
proc gdk_pixbuf_new_from_data*(data: Pguchar, colorspace: TGdkColorspace,
                               has_alpha: gboolean, bits_per_sample: int32,
                               width: int32, height: int32, rowstride: int32,
                               destroy_fn: TGdkPixbufDestroyNotify,
                               destroy_fn_data: gpointer): PGdkPixbuf{.cdecl,
    dynlib: gdkpixbuflib, importc: "gdk_pixbuf_new_from_data".}
proc gdk_pixbuf_new_from_xpm_data*(data: PPchar): PGdkPixbuf{.cdecl,
    dynlib: gdkpixbuflib, importc: "gdk_pixbuf_new_from_xpm_data".}
proc gdk_pixbuf_new_from_inline*(data_length: gint, a: var guint8,
                                 copy_pixels: gboolean, error: pointer): PGdkPixbuf{.
    cdecl, dynlib: gdkpixbuflib, importc: "gdk_pixbuf_new_from_inline".}
proc gdk_pixbuf_new_from_file_at_size*(filename: cstring, width, height: gint,
                                       error: pointer): PGdkPixbuf{.cdecl,
    dynlib: gdkpixbuflib, importc: "gdk_pixbuf_new_from_file_at_size".}
proc gdk_pixbuf_new_from_file_at_scale*(filename: cstring, width, height: gint,
    preserve_aspect_ratio: gboolean, error: pointer): PGdkPixbuf{.cdecl,
    dynlib: gdkpixbuflib, importc: "gdk_pixbuf_new_from_file_at_scale".}
proc gdk_pixbuf_fill*(pixbuf: PGdkPixbuf, pixel: guint32){.cdecl,
    dynlib: gdkpixbuflib, importc: "gdk_pixbuf_fill".}
proc gdk_pixbuf_save*(pixbuf: PGdkPixbuf, filename: cstring, `type`: cstring,
                      error: pointer): gboolean{.cdecl, varargs,
    dynlib: gdkpixbuflib, importc: "gdk_pixbuf_save".}
proc gdk_pixbuf_savev*(pixbuf: PGdkPixbuf, filename: cstring, `type`: cstring,
                       option_keys: PPchar, option_values: PPchar,
                       error: pointer): gboolean{.cdecl, dynlib: gdkpixbuflib,
    importc: "gdk_pixbuf_savev".}
proc gdk_pixbuf_add_alpha*(pixbuf: PGdkPixbuf, substitute_color: gboolean,
                           r: guchar, g: guchar, b: guchar): PGdkPixbuf{.cdecl,
    dynlib: gdkpixbuflib, importc: "gdk_pixbuf_add_alpha".}
proc gdk_pixbuf_copy_area*(src_pixbuf: PGdkPixbuf, src_x: int32, src_y: int32,
                           width: int32, height: int32, dest_pixbuf: PGdkPixbuf,
                           dest_x: int32, dest_y: int32){.cdecl,
    dynlib: gdkpixbuflib, importc: "gdk_pixbuf_copy_area".}
proc gdk_pixbuf_saturate_and_pixelate*(src: PGdkPixbuf, dest: PGdkPixbuf,
                                       saturation: gfloat, pixelate: gboolean){.
    cdecl, dynlib: gdkpixbuflib, importc: "gdk_pixbuf_saturate_and_pixelate".}
proc gdk_pixbuf_scale*(src: PGdkPixbuf, dest: PGdkPixbuf, dest_x: int32,
                       dest_y: int32, dest_width: int32, dest_height: int32,
                       offset_x: float64, offset_y: float64, scale_x: float64,
                       scale_y: float64, interp_type: TGdkInterpType){.cdecl,
    dynlib: gdkpixbuflib, importc: "gdk_pixbuf_scale".}
proc gdk_pixbuf_composite*(src: PGdkPixbuf, dest: PGdkPixbuf, dest_x: int32,
                           dest_y: int32, dest_width: int32, dest_height: int32,
                           offset_x: float64, offset_y: float64,
                           scale_x: float64, scale_y: float64,
                           interp_type: TGdkInterpType, overall_alpha: int32){.
    cdecl, dynlib: gdkpixbuflib, importc: "gdk_pixbuf_composite".}
proc gdk_pixbuf_composite_color*(src: PGdkPixbuf, dest: PGdkPixbuf,
                                 dest_x: int32, dest_y: int32,
                                 dest_width: int32, dest_height: int32,
                                 offset_x: float64, offset_y: float64,
                                 scale_x: float64, scale_y: float64,
                                 interp_type: TGdkInterpType,
                                 overall_alpha: int32, check_x: int32,
                                 check_y: int32, check_size: int32,
                                 color1: guint32, color2: guint32){.cdecl,
    dynlib: gdkpixbuflib, importc: "gdk_pixbuf_composite_color".}
proc gdk_pixbuf_scale_simple*(src: PGdkPixbuf, dest_width: int32,
                              dest_height: int32, interp_type: TGdkInterpType): PGdkPixbuf{.
    cdecl, dynlib: gdkpixbuflib, importc: "gdk_pixbuf_scale_simple".}
proc gdk_pixbuf_composite_color_simple*(src: PGdkPixbuf, dest_width: int32,
                                        dest_height: int32,
                                        interp_type: TGdkInterpType,
                                        overall_alpha: int32, check_size: int32,
                                        color1: guint32, color2: guint32): PGdkPixbuf{.
    cdecl, dynlib: gdkpixbuflib, importc: "gdk_pixbuf_composite_color_simple".}
proc gdk_pixbuf_animation_get_type*(): GType{.cdecl, dynlib: gdkpixbuflib,
    importc: "gdk_pixbuf_animation_get_type".}
proc gdk_pixbuf_animation_new_from_file*(filename: cstring, error: pointer): PGdkPixbufAnimation{.
    cdecl, dynlib: gdkpixbuflib, importc: "gdk_pixbuf_animation_new_from_file".}
when not defined(GDK_PIXBUF_DISABLE_DEPRECATED):
  proc gdk_pixbuf_animation_ref*(animation: PGdkPixbufAnimation): PGdkPixbufAnimation{.
      cdecl, dynlib: gdkpixbuflib, importc: "gdk_pixbuf_animation_ref".}
  proc gdk_pixbuf_animation_unref*(animation: PGdkPixbufAnimation){.cdecl,
      dynlib: gdkpixbuflib, importc: "gdk_pixbuf_animation_unref".}
proc gdk_pixbuf_animation_get_width*(animation: PGdkPixbufAnimation): int32{.
    cdecl, dynlib: gdkpixbuflib, importc: "gdk_pixbuf_animation_get_width".}
proc gdk_pixbuf_animation_get_height*(animation: PGdkPixbufAnimation): int32{.
    cdecl, dynlib: gdkpixbuflib, importc: "gdk_pixbuf_animation_get_height".}
proc gdk_pixbuf_animation_is_static_image*(animation: PGdkPixbufAnimation): gboolean{.
    cdecl, dynlib: gdkpixbuflib, importc: "gdk_pixbuf_animation_is_static_image".}
proc gdk_pixbuf_animation_get_static_image*(animation: PGdkPixbufAnimation): PGdkPixbuf{.
    cdecl, dynlib: gdkpixbuflib,
    importc: "gdk_pixbuf_animation_get_static_image".}
proc gdk_pixbuf_animation_get_iter*(animation: PGdkPixbufAnimation,
                                    e: var TGTimeVal): PGdkPixbufAnimationIter{.
    cdecl, dynlib: gdkpixbuflib, importc: "gdk_pixbuf_animation_get_iter".}
proc gdk_pixbuf_animation_iter_get_type*(): GType{.cdecl, dynlib: gdkpixbuflib,
    importc: "gdk_pixbuf_animation_iter_get_type".}
proc gdk_pixbuf_animation_iter_get_delay_time*(iter: PGdkPixbufAnimationIter): int32{.
    cdecl, dynlib: gdkpixbuflib,
    importc: "gdk_pixbuf_animation_iter_get_delay_time".}
proc gdk_pixbuf_animation_iter_get_pixbuf*(iter: PGdkPixbufAnimationIter): PGdkPixbuf{.
    cdecl, dynlib: gdkpixbuflib, importc: "gdk_pixbuf_animation_iter_get_pixbuf".}
proc gdk_pixbuf_animation_iter_on_currently_loading_frame*(
    iter: PGdkPixbufAnimationIter): gboolean{.cdecl, dynlib: gdkpixbuflib,
    importc: "gdk_pixbuf_animation_iter_on_currently_loading_frame".}
proc gdk_pixbuf_animation_iter_advance*(iter: PGdkPixbufAnimationIter,
                                        e: var TGTimeVal): gboolean{.cdecl,
    dynlib: gdkpixbuflib, importc: "gdk_pixbuf_animation_iter_advance".}
proc gdk_pixbuf_get_option*(pixbuf: PGdkPixbuf, key: cstring): cstring{.cdecl,
    dynlib: gdkpixbuflib, importc: "gdk_pixbuf_get_option".}
type
  PGdkPixbufLoader* = ptr TGdkPixbufLoader
  TGdkPixbufLoader* {.final.} = object
    parent_instance*: TGObject
    priv*: gpointer

  PGdkPixbufLoaderClass* = ptr TGdkPixbufLoaderClass
  TGdkPixbufLoaderClass* {.final.} = object
    parent_class*: TGObjectClass
    area_prepared*: proc (loader: PGdkPixbufLoader){.cdecl.}
    area_updated*: proc (loader: PGdkPixbufLoader, x: int32, y: int32,
                         width: int32, height: int32){.cdecl.}
    closed*: proc (loader: PGdkPixbufLoader){.cdecl.}


proc GDK_TYPE_PIXBUF_LOADER*(): GType
proc GDK_PIXBUF_LOADER*(obj: pointer): PGdkPixbufLoader
proc GDK_PIXBUF_LOADER_CLASS*(klass: pointer): PGdkPixbufLoaderClass
proc GDK_IS_PIXBUF_LOADER*(obj: pointer): bool
proc GDK_IS_PIXBUF_LOADER_CLASS*(klass: pointer): bool
proc GDK_PIXBUF_LOADER_GET_CLASS*(obj: pointer): PGdkPixbufLoaderClass
proc gdk_pixbuf_loader_get_type*(): GType{.cdecl, dynlib: gdkpixbuflib,
    importc: "gdk_pixbuf_loader_get_type".}
proc gdk_pixbuf_loader_new*(): PGdkPixbufLoader{.cdecl, dynlib: gdkpixbuflib,
    importc: "gdk_pixbuf_loader_new".}
proc gdk_pixbuf_loader_new_with_type*(image_type: cstring, error: pointer): PGdkPixbufLoader{.
    cdecl, dynlib: gdkpixbuflib, importc: "gdk_pixbuf_loader_new_with_type".}
proc gdk_pixbuf_loader_write*(loader: PGdkPixbufLoader, buf: Pguchar,
                              count: gsize, error: pointer): gboolean{.cdecl,
    dynlib: gdkpixbuflib, importc: "gdk_pixbuf_loader_write".}
proc gdk_pixbuf_loader_get_pixbuf*(loader: PGdkPixbufLoader): PGdkPixbuf{.cdecl,
    dynlib: gdkpixbuflib, importc: "gdk_pixbuf_loader_get_pixbuf".}
proc gdk_pixbuf_loader_get_animation*(loader: PGdkPixbufLoader): PGdkPixbufAnimation{.
    cdecl, dynlib: gdkpixbuflib, importc: "gdk_pixbuf_loader_get_animation".}
proc gdk_pixbuf_loader_close*(loader: PGdkPixbufLoader, error: pointer): gboolean{.
    cdecl, dynlib: gdkpixbuflib, importc: "gdk_pixbuf_loader_close".}
proc GDK_TYPE_PIXBUF_LOADER*(): GType =
  result = gdk_pixbuf_loader_get_type()

proc GDK_PIXBUF_LOADER*(obj: pointer): PGdkPixbufLoader =
  result = cast[PGdkPixbufLoader](G_TYPE_CHECK_INSTANCE_CAST(obj,
      GDK_TYPE_PIXBUF_LOADER()))

proc GDK_PIXBUF_LOADER_CLASS*(klass: pointer): PGdkPixbufLoaderClass =
  result = cast[PGdkPixbufLoaderClass](G_TYPE_CHECK_CLASS_CAST(klass,
      GDK_TYPE_PIXBUF_LOADER()))

proc GDK_IS_PIXBUF_LOADER*(obj: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(obj, GDK_TYPE_PIXBUF_LOADER())

proc GDK_IS_PIXBUF_LOADER_CLASS*(klass: pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, GDK_TYPE_PIXBUF_LOADER())

proc GDK_PIXBUF_LOADER_GET_CLASS*(obj: pointer): PGdkPixbufLoaderClass =
  result = cast[PGdkPixbufLoaderClass](G_TYPE_INSTANCE_GET_CLASS(obj,
      GDK_TYPE_PIXBUF_LOADER()))

proc GDK_TYPE_PIXBUF*(): GType =
  result = gdk_pixbuf_get_type()

proc GDK_PIXBUF*(anObject: pointer): PGdkPixbuf =
  result = cast[PGdkPixbuf](G_TYPE_CHECK_INSTANCE_CAST(anObject, GDK_TYPE_PIXBUF()))

proc GDK_IS_PIXBUF*(anObject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, GDK_TYPE_PIXBUF())

proc GDK_TYPE_PIXBUF_ANIMATION*(): GType =
  result = gdk_pixbuf_animation_get_type()

proc GDK_PIXBUF_ANIMATION*(anObject: pointer): PGdkPixbufAnimation =
  result = cast[PGdkPixbufAnimation](G_TYPE_CHECK_INSTANCE_CAST(anObject,
      GDK_TYPE_PIXBUF_ANIMATION()))

proc GDK_IS_PIXBUF_ANIMATION*(anObject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, GDK_TYPE_PIXBUF_ANIMATION())

proc GDK_TYPE_PIXBUF_ANIMATION_ITER*(): GType =
  result = gdk_pixbuf_animation_iter_get_type()

proc GDK_PIXBUF_ANIMATION_ITER*(anObject: pointer): PGdkPixbufAnimationIter =
  result = cast[PGdkPixbufAnimationIter](G_TYPE_CHECK_INSTANCE_CAST(anObject,
    GDK_TYPE_PIXBUF_ANIMATION_ITER()))

proc GDK_IS_PIXBUF_ANIMATION_ITER*(anObject: pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, GDK_TYPE_PIXBUF_ANIMATION_ITER())

proc GDK_PIXBUF_ERROR*(): TGQuark =
  result = gdk_pixbuf_error_quark()
