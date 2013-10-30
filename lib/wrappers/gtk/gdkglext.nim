{.deadCodeElim: on.}
import
  Glib2, gdk2

when defined(WIN32):
  const
    GLExtLib = "libgdkglext-win32-1.0-0.dll"
elif defined(macosx):
  const
    GLExtLib = "libgdkglext-x11-1.0.dylib"
else:
  const
    GLExtLib = "libgdkglext-x11-1.0.so"
type
  TGLConfigAttrib* = int32
  TGLConfigCaveat* = int32
  TGLVisualType* = int32
  TGLTransparentType* = int32
  TGLDrawableTypeMask* = int32
  TGLRenderTypeMask* = int32
  TGLBufferMask* = int32
  TGLConfigError* = int32
  TGLRenderType* = int32
  TGLDrawableAttrib* = int32
  TGLPbufferAttrib* = int32
  TGLEventMask* = int32
  TGLEventType* = int32
  TGLDrawableType* = int32
  TGLProc* = Pointer
  PGLConfig* = ptr TGLConfig
  PGLContext* = ptr TGLContext
  PGLDrawable* = ptr TGLDrawable
  PGLPixmap* = ptr TGLPixmap
  PGLWindow* = ptr TGLWindow
  TGLConfig* = object of TGObject
    layer_plane*: gint
    n_aux_buffers*: gint
    n_sample_buffers*: gint
    flag0*: int16

  PGLConfigClass* = ptr TGLConfigClass
  TGLConfigClass* = object of TGObjectClass
  TGLContext* = object of TGObject
  PGLContextClass* = ptr TGLContextClass
  TGLContextClass* = object of TGObjectClass
  TGLDrawable* = object of TGObject
  PGLDrawableClass* = ptr TGLDrawableClass
  TGLDrawableClass* = object of TGTypeInterface
    create_new_context*: proc (gldrawable: PGLDrawable, share_list: PGLContext,
                               direct: gboolean, render_type: int32): PGLContext{.
        cdecl.}
    make_context_current*: proc (draw: PGLDrawable, a_read: PGLDrawable,
                                 glcontext: PGLContext): gboolean{.cdecl.}
    is_double_buffered*: proc (gldrawable: PGLDrawable): gboolean{.cdecl.}
    swap_buffers*: proc (gldrawable: PGLDrawable){.cdecl.}
    wait_gl*: proc (gldrawable: PGLDrawable){.cdecl.}
    wait_gdk*: proc (gldrawable: PGLDrawable){.cdecl.}
    gl_begin*: proc (draw: PGLDrawable, a_read: PGLDrawable,
                     glcontext: PGLContext): gboolean{.cdecl.}
    gl_end*: proc (gldrawable: PGLDrawable){.cdecl.}
    get_gl_config*: proc (gldrawable: PGLDrawable): PGLConfig{.cdecl.}
    get_size*: proc (gldrawable: PGLDrawable, width, height: PGInt){.cdecl.}

  TGLPixmap* = object of TGObject
    drawable*: PDrawable

  PGLPixmapClass* = ptr TGLPixmapClass
  TGLPixmapClass* = object of TGObjectClass
  TGLWindow* = object of TGObject
    drawable*: PDrawable

  PGLWindowClass* = ptr TGLWindowClass
  TGLWindowClass* = object of TGObjectClass

const
  HEADER_GDKGLEXT_MAJOR_VERSION* = 1
  HEADER_GDKGLEXT_MINOR_VERSION* = 0
  HEADER_GDKGLEXT_MICRO_VERSION* = 6
  HEADER_GDKGLEXT_INTERFACE_AGE* = 4
  HEADER_GDKGLEXT_BINARY_AGE* = 6

proc HEADER_GDKGLEXT_CHECK_VERSION*(major, minor, micro: guint): bool
var
  glext_major_version*{.importc, dynlib: GLExtLib.}: guint
  glext_minor_version*{.importc, dynlib: GLExtLib.}: guint
  glext_micro_version*{.importc, dynlib: GLExtLib.}: guint
  glext_interface_age*{.importc, dynlib: GLExtLib.}: guint
  glext_binary_age*{.importc, dynlib: GLExtLib.}: guint

const
  GL_SUCCESS* = 0
  GL_ATTRIB_LIST_NONE* = 0
  GL_USE_GL* = 1
  GL_BUFFER_SIZE* = 2
  GL_LEVEL* = 3
  GL_RGBA* = 4
  GL_DOUBLEBUFFER* = 5
  GL_STEREO* = 6
  GL_AUX_BUFFERS* = 7
  GL_RED_SIZE* = 8
  GL_GREEN_SIZE* = 9
  GL_BLUE_SIZE* = 10
  GL_ALPHA_SIZE* = 11
  GL_DEPTH_SIZE* = 12
  GL_STENCIL_SIZE* = 13
  GL_ACCUM_RED_SIZE* = 14
  GL_ACCUM_GREEN_SIZE* = 15
  GL_ACCUM_BLUE_SIZE* = 16
  GL_ACCUM_ALPHA_SIZE* = 17
  GL_CONFIG_CAVEAT* = 0x00000020
  GL_X_VISUAL_TYPE* = 0x00000022
  GL_TRANSPARENT_TYPE* = 0x00000023
  GL_TRANSPARENT_INDEX_VALUE* = 0x00000024
  GL_TRANSPARENT_RED_VALUE* = 0x00000025
  GL_TRANSPARENT_GREEN_VALUE* = 0x00000026
  GL_TRANSPARENT_BLUE_VALUE* = 0x00000027
  GL_TRANSPARENT_ALPHA_VALUE* = 0x00000028
  GL_DRAWABLE_TYPE* = 0x00008010
  GL_RENDER_TYPE* = 0x00008011
  GL_X_RENDERABLE* = 0x00008012
  GL_FBCONFIG_ID* = 0x00008013
  GL_MAX_PBUFFER_WIDTH* = 0x00008016
  GL_MAX_PBUFFER_HEIGHT* = 0x00008017
  GL_MAX_PBUFFER_PIXELS* = 0x00008018
  GL_VISUAL_ID* = 0x0000800B
  GL_SCREEN* = 0x0000800C
  GL_SAMPLE_BUFFERS* = 100000
  GL_SAMPLES* = 100001
  GL_DONT_CARE* = 0xFFFFFFFF
  GL_NONE* = 0x00008000
  GL_CONFIG_CAVEAT_DONT_CARE* = 0xFFFFFFFF
  GL_CONFIG_CAVEAT_NONE* = 0x00008000
  GL_SLOW_CONFIG* = 0x00008001
  GL_NON_CONFORMANT_CONFIG* = 0x0000800D
  GL_VISUAL_TYPE_DONT_CARE* = 0xFFFFFFFF
  GL_TRUE_COLOR* = 0x00008002
  GL_DIRECT_COLOR* = 0x00008003
  GL_PSEUDO_COLOR* = 0x00008004
  GL_STATIC_COLOR* = 0x00008005
  GL_GRAY_SCALE* = 0x00008006
  GL_STATIC_GRAY* = 0x00008007
  GL_TRANSPARENT_NONE* = 0x00008000
  GL_TRANSPARENT_RGB* = 0x00008008
  GL_TRANSPARENT_INDEX* = 0x00008009
  GL_WINDOW_BIT* = 1 shl 0
  GL_PIXMAP_BIT* = 1 shl 1
  GL_PBUFFER_BIT* = 1 shl 2
  GL_RGBA_BIT* = 1 shl 0
  GL_COLOR_INDEX_BIT* = 1 shl 1
  GL_FRONT_LEFT_BUFFER_BIT* = 1 shl 0
  GL_FRONT_RIGHT_BUFFER_BIT* = 1 shl 1
  GL_BACK_LEFT_BUFFER_BIT* = 1 shl 2
  GL_BACK_RIGHT_BUFFER_BIT* = 1 shl 3
  GL_AUX_BUFFERS_BIT* = 1 shl 4
  GL_DEPTH_BUFFER_BIT* = 1 shl 5
  GL_STENCIL_BUFFER_BIT* = 1 shl 6
  GL_ACCUM_BUFFER_BIT* = 1 shl 7
  GL_BAD_SCREEN* = 1
  GL_BAD_ATTRIBUTE* = 2
  GL_NO_EXTENSION* = 3
  GL_BAD_VISUAL* = 4
  GL_BAD_CONTEXT* = 5
  GL_BAD_VALUE* = 6
  GL_BAD_ENUM* = 7
  GL_RGBA_TYPE* = 0x00008014
  GL_COLOR_INDEX_TYPE* = 0x00008015
  GL_PRESERVED_CONTENTS* = 0x0000801B
  GL_LARGEST_PBUFFER* = 0x0000801C
  GL_WIDTH* = 0x0000801D
  GL_HEIGHT* = 0x0000801E
  GL_EVENT_MASK* = 0x0000801F
  GL_PBUFFER_PRESERVED_CONTENTS* = 0x0000801B
  GL_PBUFFER_LARGEST_PBUFFER* = 0x0000801C
  GL_PBUFFER_HEIGHT* = 0x00008040
  GL_PBUFFER_WIDTH* = 0x00008041
  GL_PBUFFER_CLOBBER_MASK* = 1 shl 27
  GL_DAMAGED* = 0x00008020
  GL_SAVED* = 0x00008021
  GL_WINDOW_VALUE* = 0x00008022
  GL_PBUFFER* = 0x00008023

proc gl_config_attrib_get_type*(): GType{.cdecl, dynlib: GLExtLib,
    importc: "gdk_gl_config_attrib_get_type".}
proc TYPE_GL_CONFIG_ATTRIB*(): GType{.cdecl, dynlib: GLExtLib,
                                      importc: "gdk_gl_config_attrib_get_type".}
proc gl_config_caveat_get_type*(): GType{.cdecl, dynlib: GLExtLib,
    importc: "gdk_gl_config_caveat_get_type".}
proc TYPE_GL_CONFIG_CAVEAT*(): GType{.cdecl, dynlib: GLExtLib,
                                      importc: "gdk_gl_config_caveat_get_type".}
proc gl_visual_type_get_type*(): GType{.cdecl, dynlib: GLExtLib,
                                        importc: "gdk_gl_visual_type_get_type".}
proc TYPE_GL_VISUAL_TYPE*(): GType{.cdecl, dynlib: GLExtLib,
                                    importc: "gdk_gl_visual_type_get_type".}
proc gl_transparent_type_get_type*(): GType{.cdecl, dynlib: GLExtLib,
    importc: "gdk_gl_transparent_type_get_type".}
proc TYPE_GL_TRANSPARENT_TYPE*(): GType{.cdecl, dynlib: GLExtLib,
    importc: "gdk_gl_transparent_type_get_type".}
proc gl_drawable_type_mask_get_type*(): GType{.cdecl, dynlib: GLExtLib,
    importc: "gdk_gl_drawable_type_mask_get_type".}
proc TYPE_GL_DRAWABLE_TYPE_MASK*(): GType{.cdecl, dynlib: GLExtLib,
    importc: "gdk_gl_drawable_type_mask_get_type".}
proc gl_render_type_mask_get_type*(): GType{.cdecl, dynlib: GLExtLib,
    importc: "gdk_gl_render_type_mask_get_type".}
proc TYPE_GL_RENDER_TYPE_MASK*(): GType{.cdecl, dynlib: GLExtLib,
    importc: "gdk_gl_render_type_mask_get_type".}
proc gl_buffer_mask_get_type*(): GType{.cdecl, dynlib: GLExtLib,
                                        importc: "gdk_gl_buffer_mask_get_type".}
proc TYPE_GL_BUFFER_MASK*(): GType{.cdecl, dynlib: GLExtLib,
                                    importc: "gdk_gl_buffer_mask_get_type".}
proc gl_config_error_get_type*(): GType{.cdecl, dynlib: GLExtLib,
    importc: "gdk_gl_config_error_get_type".}
proc TYPE_GL_CONFIG_ERROR*(): GType{.cdecl, dynlib: GLExtLib,
                                     importc: "gdk_gl_config_error_get_type".}
proc gl_render_type_get_type*(): GType{.cdecl, dynlib: GLExtLib,
                                        importc: "gdk_gl_render_type_get_type".}
proc TYPE_GL_RENDER_TYPE*(): GType{.cdecl, dynlib: GLExtLib,
                                    importc: "gdk_gl_render_type_get_type".}
proc gl_drawable_attrib_get_type*(): GType{.cdecl, dynlib: GLExtLib,
    importc: "gdk_gl_drawable_attrib_get_type".}
proc TYPE_GL_DRAWABLE_ATTRIB*(): GType{.cdecl, dynlib: GLExtLib, importc: "gdk_gl_drawable_attrib_get_type".}
proc gl_pbuffer_attrib_get_type*(): GType{.cdecl, dynlib: GLExtLib,
    importc: "gdk_gl_pbuffer_attrib_get_type".}
proc TYPE_GL_PBUFFER_ATTRIB*(): GType{.cdecl, dynlib: GLExtLib, importc: "gdk_gl_pbuffer_attrib_get_type".}
proc gl_event_mask_get_type*(): GType{.cdecl, dynlib: GLExtLib,
                                       importc: "gdk_gl_event_mask_get_type".}
proc TYPE_GL_EVENT_MASK*(): GType{.cdecl, dynlib: GLExtLib,
                                   importc: "gdk_gl_event_mask_get_type".}
proc gl_event_type_get_type*(): GType{.cdecl, dynlib: GLExtLib,
                                       importc: "gdk_gl_event_type_get_type".}
proc TYPE_GL_EVENT_TYPE*(): GType{.cdecl, dynlib: GLExtLib,
                                   importc: "gdk_gl_event_type_get_type".}
proc gl_drawable_type_get_type*(): GType{.cdecl, dynlib: GLExtLib,
    importc: "gdk_gl_drawable_type_get_type".}
proc TYPE_GL_DRAWABLE_TYPE*(): GType{.cdecl, dynlib: GLExtLib,
                                      importc: "gdk_gl_drawable_type_get_type".}
proc gl_config_mode_get_type*(): GType{.cdecl, dynlib: GLExtLib,
                                        importc: "gdk_gl_config_mode_get_type".}
proc TYPE_GL_CONFIG_MODE*(): GType{.cdecl, dynlib: GLExtLib,
                                    importc: "gdk_gl_config_mode_get_type".}
proc gl_parse_args*(argc: var int32, argv: ptr cstringArray): gboolean{.cdecl,
    dynlib: GLExtLib, importc: "gdk_gl_parse_args".}
proc gl_init_check*(argc: var int32, argv: ptr cstringArray): gboolean{.cdecl,
    dynlib: GLExtLib, importc: "gdk_gl_init_check".}
proc gl_init*(argc: var int32, argv: ptr cstringArray){.cdecl, dynlib: GLExtLib,
    importc: "gdk_gl_init".}
proc gl_query_gl_extension*(extension: cstring): gboolean{.cdecl,
    dynlib: GLExtLib, importc: "gdk_gl_query_gl_extension".}
proc gl_get_proc_address*(proc_name: cstring): TGLProc{.cdecl, dynlib: GLExtLib,
    importc: "gdk_gl_get_proc_address".}
const
  bm_TGdkGLConfig_is_rgba* = 1 shl 0
  bp_TGdkGLConfig_is_rgba* = 0
  bm_TGdkGLConfig_is_double_buffered* = 1 shl 1
  bp_TGdkGLConfig_is_double_buffered* = 1
  bm_TGdkGLConfig_as_single_mode* = 1 shl 2
  bp_TGdkGLConfig_as_single_mode* = 2
  bm_TGdkGLConfig_is_stereo* = 1 shl 3
  bp_TGdkGLConfig_is_stereo* = 3
  bm_TGdkGLConfig_has_alpha* = 1 shl 4
  bp_TGdkGLConfig_has_alpha* = 4
  bm_TGdkGLConfig_has_depth_buffer* = 1 shl 5
  bp_TGdkGLConfig_has_depth_buffer* = 5
  bm_TGdkGLConfig_has_stencil_buffer* = 1 shl 6
  bp_TGdkGLConfig_has_stencil_buffer* = 6
  bm_TGdkGLConfig_has_accum_buffer* = 1 shl 7
  bp_TGdkGLConfig_has_accum_buffer* = 7

const
  GL_MODE_RGB* = 0
  GL_MODE_RGBA* = 0
  GL_MODE_INDEX* = 1 shl 0
  GL_MODE_SINGLE* = 0
  GL_MODE_DOUBLE* = 1 shl 1
  GL_MODE_STEREO* = 1 shl 2
  GL_MODE_ALPHA* = 1 shl 3
  GL_MODE_DEPTH* = 1 shl 4
  GL_MODE_STENCIL* = 1 shl 5
  GL_MODE_ACCUM* = 1 shl 6
  GL_MODE_MULTISAMPLE* = 1 shl 7

type
  TGLConfigMode* = int32
  PGLConfigMode* = ptr TGLConfigMode

proc TYPE_GL_CONFIG*(): GType
proc GL_CONFIG*(anObject: Pointer): PGLConfig
proc GL_CONFIG_CLASS*(klass: Pointer): PGLConfigClass
proc IS_GL_CONFIG*(anObject: Pointer): bool
proc IS_GL_CONFIG_CLASS*(klass: Pointer): bool
proc GL_CONFIG_GET_CLASS*(obj: Pointer): PGLConfigClass
proc gl_config_get_type*(): GType{.cdecl, dynlib: GLExtLib,
                                   importc: "gdk_gl_config_get_type".}
proc get_screen*(glconfig: PGLConfig): PScreen{.cdecl,
    dynlib: GLExtLib, importc: "gdk_gl_config_get_screen".}
proc get_attrib*(glconfig: PGLConfig, attribute: int, value: var cint): gboolean{.
    cdecl, dynlib: GLExtLib, importc: "gdk_gl_config_get_attrib".}
proc get_colormap*(glconfig: PGLConfig): PColormap{.cdecl,
    dynlib: GLExtLib, importc: "gdk_gl_config_get_colormap".}
proc get_visual*(glconfig: PGLConfig): PVisual{.cdecl,
    dynlib: GLExtLib, importc: "gdk_gl_config_get_visual".}
proc get_depth*(glconfig: PGLConfig): gint{.cdecl, dynlib: GLExtLib,
    importc: "gdk_gl_config_get_depth".}
proc get_layer_plane*(glconfig: PGLConfig): gint{.cdecl,
    dynlib: GLExtLib, importc: "gdk_gl_config_get_layer_plane".}
proc get_n_aux_buffers*(glconfig: PGLConfig): gint{.cdecl,
    dynlib: GLExtLib, importc: "gdk_gl_config_get_n_aux_buffers".}
proc get_n_sample_buffers*(glconfig: PGLConfig): gint{.cdecl,
    dynlib: GLExtLib, importc: "gdk_gl_config_get_n_sample_buffers".}
proc is_rgba*(glconfig: PGLConfig): gboolean{.cdecl, dynlib: GLExtLib,
    importc: "gdk_gl_config_is_rgba".}
proc is_double_buffered*(glconfig: PGLConfig): gboolean{.cdecl,
    dynlib: GLExtLib, importc: "gdk_gl_config_is_double_buffered".}
proc is_stereo*(glconfig: PGLConfig): gboolean{.cdecl,
    dynlib: GLExtLib, importc: "gdk_gl_config_is_stereo".}
proc has_alpha*(glconfig: PGLConfig): gboolean{.cdecl,
    dynlib: GLExtLib, importc: "gdk_gl_config_has_alpha".}
proc has_depth_buffer*(glconfig: PGLConfig): gboolean{.cdecl,
    dynlib: GLExtLib, importc: "gdk_gl_config_has_depth_buffer".}
proc has_stencil_buffer*(glconfig: PGLConfig): gboolean{.cdecl,
    dynlib: GLExtLib, importc: "gdk_gl_config_has_stencil_buffer".}
proc has_accum_buffer*(glconfig: PGLConfig): gboolean{.cdecl,
    dynlib: GLExtLib, importc: "gdk_gl_config_has_accum_buffer".}
proc TYPE_GL_CONTEXT*(): GType
proc GL_CONTEXT*(anObject: Pointer): PGLContext
proc GL_CONTEXT_CLASS*(klass: Pointer): PGLContextClass
proc IS_GL_CONTEXT*(anObject: Pointer): bool
proc IS_GL_CONTEXT_CLASS*(klass: Pointer): bool
proc GL_CONTEXT_GET_CLASS*(obj: Pointer): PGLContextClass
proc gl_context_get_type*(): GType{.cdecl, dynlib: GLExtLib,
                                    importc: "gdk_gl_context_get_type".}
proc context_new*(gldrawable: PGLDrawable, share_list: PGLContext,
                     direct: gboolean, render_type: int32): PGLContext{.cdecl,
    dynlib: GLExtLib, importc: "gdk_gl_context_new".}
proc destroy*(glcontext: PGLContext){.cdecl, dynlib: GLExtLib,
    importc: "gdk_gl_context_destroy".}
proc copy*(glcontext: PGLContext, src: PGLContext, mask: int32): gboolean{.
    cdecl, dynlib: GLExtLib, importc: "gdk_gl_context_copy".}
proc get_gl_drawable*(glcontext: PGLContext): PGLDrawable{.cdecl,
    dynlib: GLExtLib, importc: "gdk_gl_context_get_gl_drawable".}
proc get_gl_config*(glcontext: PGLContext): PGLConfig{.cdecl,
    dynlib: GLExtLib, importc: "gdk_gl_context_get_gl_config".}
proc get_share_list*(glcontext: PGLContext): PGLContext{.cdecl,
    dynlib: GLExtLib, importc: "gdk_gl_context_get_share_list".}
proc is_direct*(glcontext: PGLContext): gboolean{.cdecl,
    dynlib: GLExtLib, importc: "gdk_gl_context_is_direct".}
proc get_render_type*(glcontext: PGLContext): int32{.cdecl,
    dynlib: GLExtLib, importc: "gdk_gl_context_get_render_type".}
proc gl_context_get_current*(): PGLContext{.cdecl, dynlib: GLExtLib,
    importc: "gdk_gl_context_get_current".}
proc TYPE_GL_DRAWABLE*(): GType
proc GL_DRAWABLE*(inst: Pointer): PGLDrawable
proc GL_DRAWABLE_CLASS*(vtable: Pointer): PGLDrawableClass
proc IS_GL_DRAWABLE*(inst: Pointer): bool
proc IS_GL_DRAWABLE_CLASS*(vtable: Pointer): bool
proc GL_DRAWABLE_GET_CLASS*(inst: Pointer): PGLDrawableClass
proc gl_drawable_get_type*(): GType{.cdecl, dynlib: GLExtLib,
                                     importc: "gdk_gl_drawable_get_type".}
proc make_current*(gldrawable: PGLDrawable, glcontext: PGLContext): gboolean{.
    cdecl, dynlib: GLExtLib, importc: "gdk_gl_drawable_make_current".}
proc is_double_buffered*(gldrawable: PGLDrawable): gboolean{.cdecl,
    dynlib: GLExtLib, importc: "gdk_gl_drawable_is_double_buffered".}
proc swap_buffers*(gldrawable: PGLDrawable){.cdecl,
    dynlib: GLExtLib, importc: "gdk_gl_drawable_swap_buffers".}
proc wait_gl*(gldrawable: PGLDrawable){.cdecl, dynlib: GLExtLib,
    importc: "gdk_gl_drawable_wait_gl".}
proc wait_gdk*(gldrawable: PGLDrawable){.cdecl, dynlib: GLExtLib,
    importc: "gdk_gl_drawable_wait_gdk".}
proc gl_begin*(gldrawable: PGLDrawable, glcontext: PGLContext): gboolean{.
    cdecl, dynlib: GLExtLib, importc: "gdk_gl_drawable_gl_begin".}
proc gl_end*(gldrawable: PGLDrawable){.cdecl, dynlib: GLExtLib,
    importc: "gdk_gl_drawable_gl_end".}
proc get_gl_config*(gldrawable: PGLDrawable): PGLConfig{.cdecl,
    dynlib: GLExtLib, importc: "gdk_gl_drawable_get_gl_config".}
proc get_size*(gldrawable: PGLDrawable, width, height: PGInt){.
    cdecl, dynlib: GLExtLib, importc: "gdk_gl_drawable_get_size".}
proc gl_drawable_get_current*(): PGLDrawable{.cdecl, dynlib: GLExtLib,
    importc: "gdk_gl_drawable_get_current".}
proc TYPE_GL_PIXMAP*(): GType
proc GL_PIXMAP*(anObject: Pointer): PGLPixmap
proc GL_PIXMAP_CLASS*(klass: Pointer): PGLPixmapClass
proc IS_GL_PIXMAP*(anObject: Pointer): bool
proc IS_GL_PIXMAP_CLASS*(klass: Pointer): bool
proc GL_PIXMAP_GET_CLASS*(obj: Pointer): PGLPixmapClass
proc gl_pixmap_get_type*(): GType{.cdecl, dynlib: GLExtLib,
                                   importc: "gdk_gl_pixmap_get_type".}
proc pixmap_new*(glconfig: PGLConfig, pixmap: PPixmap, attrib_list: ptr int32): PGLPixmap{.
    cdecl, dynlib: GLExtLib, importc: "gdk_gl_pixmap_new".}
proc destroy*(glpixmap: PGLPixmap){.cdecl, dynlib: GLExtLib,
    importc: "gdk_gl_pixmap_destroy".}
proc get_pixmap*(glpixmap: PGLPixmap): PPixmap{.cdecl,
    dynlib: GLExtLib, importc: "gdk_gl_pixmap_get_pixmap".}
proc set_gl_capability*(pixmap: PPixmap, glconfig: PGLConfig,
                               attrib_list: ptr int32): PGLPixmap{.cdecl,
    dynlib: GLExtLib, importc: "gdk_pixmap_set_gl_capability".}
proc unset_gl_capability*(pixmap: PPixmap){.cdecl, dynlib: GLExtLib,
    importc: "gdk_pixmap_unset_gl_capability".}
proc is_gl_capable*(pixmap: PPixmap): gboolean{.cdecl, dynlib: GLExtLib,
    importc: "gdk_pixmap_is_gl_capable".}
proc get_gl_pixmap*(pixmap: PPixmap): PGLPixmap{.cdecl, dynlib: GLExtLib,
    importc: "gdk_pixmap_get_gl_pixmap".}
proc get_gl_drawable*(pixmap: PPixmap): PGLDrawable
proc TYPE_GL_WINDOW*(): GType
proc GL_WINDOW*(anObject: Pointer): PGLWindow
proc GL_WINDOW_CLASS*(klass: Pointer): PGLWindowClass
proc IS_GL_WINDOW*(anObject: Pointer): bool
proc IS_GL_WINDOW_CLASS*(klass: Pointer): bool
proc GL_WINDOW_GET_CLASS*(obj: Pointer): PGLWindowClass
proc gl_window_get_type*(): GType{.cdecl, dynlib: GLExtLib,
                                   importc: "gdk_gl_window_get_type".}
proc window_new*(glconfig: PGLConfig, window: PWindow, attrib_list: ptr int32): PGLWindow{.
    cdecl, dynlib: GLExtLib, importc: "gdk_gl_window_new".}
proc destroy*(glwindow: PGLWindow){.cdecl, dynlib: GLExtLib,
    importc: "gdk_gl_window_destroy".}
proc get_window*(glwindow: PGLWindow): PWindow{.cdecl,
    dynlib: GLExtLib, importc: "gdk_gl_window_get_window".}
proc set_gl_capability*(window: PWindow, glconfig: PGLConfig,
                               attrib_list: ptr int32): PGLWindow{.cdecl,
    dynlib: GLExtLib, importc: "gdk_window_set_gl_capability".}
proc unset_gl_capability*(window: PWindow){.cdecl, dynlib: GLExtLib,
    importc: "gdk_window_unset_gl_capability".}
proc is_gl_capable*(window: PWindow): gboolean{.cdecl, dynlib: GLExtLib,
    importc: "gdk_window_is_gl_capable".}
proc get_gl_window*(window: PWindow): PGLWindow{.cdecl, dynlib: GLExtLib,
    importc: "gdk_window_get_gl_window".}
proc get_gl_drawable*(window: PWindow): PGLDrawable
proc gl_draw_cube*(solid: gboolean, size: float64){.cdecl, dynlib: GLExtLib,
    importc: "gdk_gl_draw_cube".}
proc gl_draw_sphere*(solid: gboolean, radius: float64, slices: int32,
                     stacks: int32){.cdecl, dynlib: GLExtLib,
                                     importc: "gdk_gl_draw_sphere".}
proc gl_draw_cone*(solid: gboolean, base: float64, height: float64,
                   slices: int32, stacks: int32){.cdecl, dynlib: GLExtLib,
    importc: "gdk_gl_draw_cone".}
proc gl_draw_torus*(solid: gboolean, inner_radius: float64,
                    outer_radius: float64, nsides: int32, rings: int32){.cdecl,
    dynlib: GLExtLib, importc: "gdk_gl_draw_torus".}
proc gl_draw_tetrahedron*(solid: gboolean){.cdecl, dynlib: GLExtLib,
    importc: "gdk_gl_draw_tetrahedron".}
proc gl_draw_octahedron*(solid: gboolean){.cdecl, dynlib: GLExtLib,
    importc: "gdk_gl_draw_octahedron".}
proc gl_draw_dodecahedron*(solid: gboolean){.cdecl, dynlib: GLExtLib,
    importc: "gdk_gl_draw_dodecahedron".}
proc gl_draw_icosahedron*(solid: gboolean){.cdecl, dynlib: GLExtLib,
    importc: "gdk_gl_draw_icosahedron".}
proc gl_draw_teapot*(solid: gboolean, scale: float64){.cdecl, dynlib: GLExtLib,
    importc: "gdk_gl_draw_teapot".}
proc HEADER_GDKGLEXT_CHECK_VERSION*(major, minor, micro: guint): bool =
  result = (HEADER_GDKGLEXT_MAJOR_VERSION > major) or
      ((HEADER_GDKGLEXT_MAJOR_VERSION == major) and
      (HEADER_GDKGLEXT_MINOR_VERSION > minor)) or
      ((HEADER_GDKGLEXT_MAJOR_VERSION == major) and
      (HEADER_GDKGLEXT_MINOR_VERSION == minor) and
      (HEADER_GDKGLEXT_MICRO_VERSION >= micro))

proc TYPE_GL_CONFIG*(): GType =
  result = gl_config_get_type()

proc GL_CONFIG*(anObject: Pointer): PGLConfig =
  result = cast[PGLConfig](G_TYPE_CHECK_INSTANCE_CAST(anObject, TYPE_GL_CONFIG()))

proc GL_CONFIG_CLASS*(klass: Pointer): PGLConfigClass =
  result = cast[PGLConfigClass](G_TYPE_CHECK_CLASS_CAST(klass, TYPE_GL_CONFIG()))

proc IS_GL_CONFIG*(anObject: Pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_GL_CONFIG())

proc IS_GL_CONFIG_CLASS*(klass: Pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_GL_CONFIG())

proc GL_CONFIG_GET_CLASS*(obj: Pointer): PGLConfigClass =
  result = cast[PGLConfigClass](G_TYPE_INSTANCE_GET_CLASS(obj, TYPE_GL_CONFIG()))

proc TYPE_GL_CONTEXT*(): GType =
  result = gl_context_get_type()

proc GL_CONTEXT*(anObject: Pointer): PGLContext =
  result = cast[PGLContext](G_TYPE_CHECK_INSTANCE_CAST(anObject,
      TYPE_GL_CONTEXT()))

proc GL_CONTEXT_CLASS*(klass: Pointer): PGLContextClass =
  result = cast[PGLContextClass](G_TYPE_CHECK_CLASS_CAST(klass,
      TYPE_GL_CONTEXT()))

proc IS_GL_CONTEXT*(anObject: Pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_GL_CONTEXT())

proc IS_GL_CONTEXT_CLASS*(klass: Pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_GL_CONTEXT())

proc GL_CONTEXT_GET_CLASS*(obj: Pointer): PGLContextClass =
  result = cast[PGLContextClass](G_TYPE_INSTANCE_GET_CLASS(obj,
      TYPE_GL_CONTEXT()))

proc TYPE_GL_DRAWABLE*(): GType =
  result = gl_drawable_get_type()

proc GL_DRAWABLE*(inst: Pointer): PGLDrawable =
  result = cast[PGLDrawable](G_TYPE_CHECK_INSTANCE_CAST(inst, TYPE_GL_DRAWABLE()))

proc GL_DRAWABLE_CLASS*(vtable: Pointer): PGLDrawableClass =
  result = cast[PGLDrawableClass](G_TYPE_CHECK_CLASS_CAST(vtable,
      TYPE_GL_DRAWABLE()))

proc IS_GL_DRAWABLE*(inst: Pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(inst, TYPE_GL_DRAWABLE())

proc IS_GL_DRAWABLE_CLASS*(vtable: Pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(vtable, TYPE_GL_DRAWABLE())

proc GL_DRAWABLE_GET_CLASS*(inst: Pointer): PGLDrawableClass =
  result = cast[PGLDrawableClass](G_TYPE_INSTANCE_GET_INTERFACE(inst,
      TYPE_GL_DRAWABLE()))

proc TYPE_GL_PIXMAP*(): GType =
  result = gl_pixmap_get_type()

proc GL_PIXMAP*(anObject: Pointer): PGLPixmap =
  result = cast[PGLPixmap](G_TYPE_CHECK_INSTANCE_CAST(anObject, TYPE_GL_PIXMAP()))

proc GL_PIXMAP_CLASS*(klass: Pointer): PGLPixmapClass =
  result = cast[PGLPixmapClass](G_TYPE_CHECK_CLASS_CAST(klass, TYPE_GL_PIXMAP()))

proc IS_GL_PIXMAP*(anObject: Pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_GL_PIXMAP())

proc IS_GL_PIXMAP_CLASS*(klass: Pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_GL_PIXMAP())

proc GL_PIXMAP_GET_CLASS*(obj: Pointer): PGLPixmapClass =
  result = cast[PGLPixmapClass](G_TYPE_INSTANCE_GET_CLASS(obj, TYPE_GL_PIXMAP()))

proc get_gl_drawable*(pixmap: PPixmap): PGLDrawable =
  result = GL_DRAWABLE(get_gl_pixmap(pixmap))

proc TYPE_GL_WINDOW*(): GType =
  result = gl_window_get_type()

proc GL_WINDOW*(anObject: Pointer): PGLWindow =
  result = cast[PGLWindow](G_TYPE_CHECK_INSTANCE_CAST(anObject, TYPE_GL_WINDOW()))

proc GL_WINDOW_CLASS*(klass: Pointer): PGLWindowClass =
  result = cast[PGLWindowClass](G_TYPE_CHECK_CLASS_CAST(klass, TYPE_GL_WINDOW()))

proc IS_GL_WINDOW*(anObject: Pointer): bool =
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, TYPE_GL_WINDOW())

proc IS_GL_WINDOW_CLASS*(klass: Pointer): bool =
  result = G_TYPE_CHECK_CLASS_TYPE(klass, TYPE_GL_WINDOW())

proc GL_WINDOW_GET_CLASS*(obj: Pointer): PGLWindowClass =
  result = cast[PGLWindowClass](G_TYPE_INSTANCE_GET_CLASS(obj, TYPE_GL_WINDOW()))

proc get_gl_drawable*(window: PWindow): PGLDrawable =
  result = GL_DRAWABLE(get_gl_window(window))
