{.deadCodeElim: on.}

import 
  Glib2, Gdk2

when defined(WIN32): 
  const 
    GdkGLExtLib = "libgdkglext-win32-1.0-0.dll"
else: 
  const 
    GdkGLExtLib = "libgdkglext-x11-1.0.so"
type 
  TGdkGLConfigAttrib* = int32
  TGdkGLConfigCaveat* = int32
  TGdkGLVisualType* = int32
  TGdkGLTransparentType* = int32
  TGdkGLDrawableTypeMask* = int32
  TGdkGLRenderTypeMask* = int32
  TGdkGLBufferMask* = int32
  TGdkGLConfigError* = int32
  TGdkGLRenderType* = int32
  TGdkGLDrawableAttrib* = int32
  TGdkGLPbufferAttrib* = int32
  TGdkGLEventMask* = int32
  TGdkGLEventType* = int32
  TGdkGLDrawableType* = int32
  TGdkGLProc* = Pointer
  PGdkGLConfig* = ptr TGdkGLConfig
  PGdkGLContext* = ptr TGdkGLContext
  PGdkGLDrawable* = ptr TGdkGLDrawable
  PGdkGLPixmap* = ptr TGdkGLPixmap
  PGdkGLWindow* = ptr TGdkGLWindow
  TGdkGLConfig* = object of TGObject
    layer_plane*: gint
    n_aux_buffers*: gint
    n_sample_buffers*: gint
    flag0*: int16

  PGdkGLConfigClass* = ptr TGdkGLConfigClass
  TGdkGLConfigClass* = object of TGObjectClass

  TGdkGLContext* = object of TGObject

  PGdkGLContextClass* = ptr TGdkGLContextClass
  TGdkGLContextClass* = object of TGObjectClass

  TGdkGLDrawable* = object of TGObject

  PGdkGLDrawableClass* = ptr TGdkGLDrawableClass
  TGdkGLDrawableClass* = object of TGTypeInterface
    create_new_context*: proc (gldrawable: PGdkGLDrawable, 
                               share_list: PGdkGLContext, direct: gboolean, 
                               render_type: int32): PGdkGLContext{.cdecl.}
    make_context_current*: proc (draw: PGdkGLDrawable, a_read: PGdkGLDrawable, 
                                 glcontext: PGdkGLContext): gboolean{.cdecl.}
    is_double_buffered*: proc (gldrawable: PGdkGLDrawable): gboolean{.cdecl.}
    swap_buffers*: proc (gldrawable: PGdkGLDrawable){.cdecl.}
    wait_gl*: proc (gldrawable: PGdkGLDrawable){.cdecl.}
    wait_gdk*: proc (gldrawable: PGdkGLDrawable){.cdecl.}
    gl_begin*: proc (draw: PGdkGLDrawable, a_read: PGdkGLDrawable, 
                     glcontext: PGdkGLContext): gboolean{.cdecl.}
    gl_end*: proc (gldrawable: PGdkGLDrawable){.cdecl.}
    get_gl_config*: proc (gldrawable: PGdkGLDrawable): PGdkGLConfig{.cdecl.}
    get_size*: proc (gldrawable: PGdkGLDrawable, width, height: PGInt){.cdecl.}

  TGdkGLPixmap* = object of TGObject
    drawable*: PGdkDrawable

  PGdkGLPixmapClass* = ptr TGdkGLPixmapClass
  TGdkGLPixmapClass* = object of TGObjectClass

  TGdkGLWindow* = object of TGObject
    drawable*: PGdkDrawable

  PGdkGLWindowClass* = ptr TGdkGLWindowClass
  TGdkGLWindowClass* = object of TGObjectClass


const 
  HEADER_GDKGLEXT_MAJOR_VERSION* = 1
  HEADER_GDKGLEXT_MINOR_VERSION* = 0
  HEADER_GDKGLEXT_MICRO_VERSION* = 6
  HEADER_GDKGLEXT_INTERFACE_AGE* = 4
  HEADER_GDKGLEXT_BINARY_AGE* = 6

proc HEADER_GDKGLEXT_CHECK_VERSION*(major, minor, micro: guint): bool
var 
  gdkglext_major_version*{.importc, dynlib: GdkGLExtLib.}: guint
  gdkglext_minor_version*{.importc, dynlib: GdkGLExtLib.}: guint
  gdkglext_micro_version*{.importc, dynlib: GdkGLExtLib.}: guint
  gdkglext_interface_age*{.importc, dynlib: GdkGLExtLib.}: guint
  gdkglext_binary_age*{.importc, dynlib: GdkGLExtLib.}: guint

const 
  GDK_GL_SUCCESS* = 0
  GDK_GL_ATTRIB_LIST_NONE* = 0
  GDK_GL_USE_GL* = 1
  GDK_GL_BUFFER_SIZE* = 2
  GDK_GL_LEVEL* = 3
  GDK_GL_RGBA* = 4
  GDK_GL_DOUBLEBUFFER* = 5
  GDK_GL_STEREO* = 6
  GDK_GL_AUX_BUFFERS* = 7
  GDK_GL_RED_SIZE* = 8
  GDK_GL_GREEN_SIZE* = 9
  GDK_GL_BLUE_SIZE* = 10
  GDK_GL_ALPHA_SIZE* = 11
  GDK_GL_DEPTH_SIZE* = 12
  GDK_GL_STENCIL_SIZE* = 13
  GDK_GL_ACCUM_RED_SIZE* = 14
  GDK_GL_ACCUM_GREEN_SIZE* = 15
  GDK_GL_ACCUM_BLUE_SIZE* = 16
  GDK_GL_ACCUM_ALPHA_SIZE* = 17
  GDK_GL_CONFIG_CAVEAT* = 0x00000020
  GDK_GL_X_VISUAL_TYPE* = 0x00000022
  GDK_GL_TRANSPARENT_TYPE* = 0x00000023
  GDK_GL_TRANSPARENT_INDEX_VALUE* = 0x00000024
  GDK_GL_TRANSPARENT_RED_VALUE* = 0x00000025
  GDK_GL_TRANSPARENT_GREEN_VALUE* = 0x00000026
  GDK_GL_TRANSPARENT_BLUE_VALUE* = 0x00000027
  GDK_GL_TRANSPARENT_ALPHA_VALUE* = 0x00000028
  GDK_GL_DRAWABLE_TYPE* = 0x00008010
  GDK_GL_RENDER_TYPE* = 0x00008011
  GDK_GL_X_RENDERABLE* = 0x00008012
  GDK_GL_FBCONFIG_ID* = 0x00008013
  GDK_GL_MAX_PBUFFER_WIDTH* = 0x00008016
  GDK_GL_MAX_PBUFFER_HEIGHT* = 0x00008017
  GDK_GL_MAX_PBUFFER_PIXELS* = 0x00008018
  GDK_GL_VISUAL_ID* = 0x0000800B
  GDK_GL_SCREEN* = 0x0000800C
  GDK_GL_SAMPLE_BUFFERS* = 100000
  GDK_GL_SAMPLES* = 100001
  GDK_GL_DONT_CARE* = 0xFFFFFFFF
  GDK_GL_NONE* = 0x00008000
  GDK_GL_CONFIG_CAVEAT_DONT_CARE* = 0xFFFFFFFF
  GDK_GL_CONFIG_CAVEAT_NONE* = 0x00008000
  GDK_GL_SLOW_CONFIG* = 0x00008001
  GDK_GL_NON_CONFORMANT_CONFIG* = 0x0000800D
  GDK_GL_VISUAL_TYPE_DONT_CARE* = 0xFFFFFFFF
  GDK_GL_TRUE_COLOR* = 0x00008002
  GDK_GL_DIRECT_COLOR* = 0x00008003
  GDK_GL_PSEUDO_COLOR* = 0x00008004
  GDK_GL_STATIC_COLOR* = 0x00008005
  GDK_GL_GRAY_SCALE* = 0x00008006
  GDK_GL_STATIC_GRAY* = 0x00008007
  GDK_GL_TRANSPARENT_NONE* = 0x00008000
  GDK_GL_TRANSPARENT_RGB* = 0x00008008
  GDK_GL_TRANSPARENT_INDEX* = 0x00008009
  GDK_GL_WINDOW_BIT* = 1 shl 0
  GDK_GL_PIXMAP_BIT* = 1 shl 1
  GDK_GL_PBUFFER_BIT* = 1 shl 2
  GDK_GL_RGBA_BIT* = 1 shl 0
  GDK_GL_COLOR_INDEX_BIT* = 1 shl 1
  GDK_GL_FRONT_LEFT_BUFFER_BIT* = 1 shl 0
  GDK_GL_FRONT_RIGHT_BUFFER_BIT* = 1 shl 1
  GDK_GL_BACK_LEFT_BUFFER_BIT* = 1 shl 2
  GDK_GL_BACK_RIGHT_BUFFER_BIT* = 1 shl 3
  GDK_GL_AUX_BUFFERS_BIT* = 1 shl 4
  GDK_GL_DEPTH_BUFFER_BIT* = 1 shl 5
  GDK_GL_STENCIL_BUFFER_BIT* = 1 shl 6
  GDK_GL_ACCUM_BUFFER_BIT* = 1 shl 7
  GDK_GL_BAD_SCREEN* = 1
  GDK_GL_BAD_ATTRIBUTE* = 2
  GDK_GL_NO_EXTENSION* = 3
  GDK_GL_BAD_VISUAL* = 4
  GDK_GL_BAD_CONTEXT* = 5
  GDK_GL_BAD_VALUE* = 6
  GDK_GL_BAD_ENUM* = 7
  GDK_GL_RGBA_TYPE* = 0x00008014
  GDK_GL_COLOR_INDEX_TYPE* = 0x00008015
  GDK_GL_PRESERVED_CONTENTS* = 0x0000801B
  GDK_GL_LARGEST_PBUFFER* = 0x0000801C
  GDK_GL_WIDTH* = 0x0000801D
  GDK_GL_HEIGHT* = 0x0000801E
  GDK_GL_EVENT_MASK* = 0x0000801F
  GDK_GL_PBUFFER_PRESERVED_CONTENTS* = 0x0000801B
  GDK_GL_PBUFFER_LARGEST_PBUFFER* = 0x0000801C
  GDK_GL_PBUFFER_HEIGHT* = 0x00008040
  GDK_GL_PBUFFER_WIDTH* = 0x00008041
  GDK_GL_PBUFFER_CLOBBER_MASK* = 1 shl 27
  GDK_GL_DAMAGED* = 0x00008020
  GDK_GL_SAVED* = 0x00008021
  GDK_GL_WINDOW_VALUE* = 0x00008022
  GDK_GL_PBUFFER* = 0x00008023

proc gdk_gl_config_attrib_get_type*(): GType{.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_config_attrib_get_type".}
proc GDK_TYPE_GL_CONFIG_ATTRIB*(): GType{.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_config_attrib_get_type".}
proc gdk_gl_config_caveat_get_type*(): GType{.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_config_caveat_get_type".}
proc GDK_TYPE_GL_CONFIG_CAVEAT*(): GType{.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_config_caveat_get_type".}
proc gdk_gl_visual_type_get_type*(): GType{.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_visual_type_get_type".}
proc GDK_TYPE_GL_VISUAL_TYPE*(): GType{.cdecl, dynlib: GdkGLExtLib, 
                                        importc: "gdk_gl_visual_type_get_type".}
proc gdk_gl_transparent_type_get_type*(): GType{.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_transparent_type_get_type".}
proc GDK_TYPE_GL_TRANSPARENT_TYPE*(): GType{.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_transparent_type_get_type".}
proc gdk_gl_drawable_type_mask_get_type*(): GType{.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_drawable_type_mask_get_type".}
proc GDK_TYPE_GL_DRAWABLE_TYPE_MASK*(): GType{.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_drawable_type_mask_get_type".}
proc gdk_gl_render_type_mask_get_type*(): GType{.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_render_type_mask_get_type".}
proc GDK_TYPE_GL_RENDER_TYPE_MASK*(): GType{.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_render_type_mask_get_type".}
proc gdk_gl_buffer_mask_get_type*(): GType{.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_buffer_mask_get_type".}
proc GDK_TYPE_GL_BUFFER_MASK*(): GType{.cdecl, dynlib: GdkGLExtLib, 
                                        importc: "gdk_gl_buffer_mask_get_type".}
proc gdk_gl_config_error_get_type*(): GType{.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_config_error_get_type".}
proc GDK_TYPE_GL_CONFIG_ERROR*(): GType{.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_config_error_get_type".}
proc gdk_gl_render_type_get_type*(): GType{.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_render_type_get_type".}
proc GDK_TYPE_GL_RENDER_TYPE*(): GType{.cdecl, dynlib: GdkGLExtLib, 
                                        importc: "gdk_gl_render_type_get_type".}
proc gdk_gl_drawable_attrib_get_type*(): GType{.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_drawable_attrib_get_type".}
proc GDK_TYPE_GL_DRAWABLE_ATTRIB*(): GType{.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_drawable_attrib_get_type".}
proc gdk_gl_pbuffer_attrib_get_type*(): GType{.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_pbuffer_attrib_get_type".}
proc GDK_TYPE_GL_PBUFFER_ATTRIB*(): GType{.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_pbuffer_attrib_get_type".}
proc gdk_gl_event_mask_get_type*(): GType{.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_event_mask_get_type".}
proc GDK_TYPE_GL_EVENT_MASK*(): GType{.cdecl, dynlib: GdkGLExtLib, 
                                       importc: "gdk_gl_event_mask_get_type".}
proc gdk_gl_event_type_get_type*(): GType{.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_event_type_get_type".}
proc GDK_TYPE_GL_EVENT_TYPE*(): GType{.cdecl, dynlib: GdkGLExtLib, 
                                       importc: "gdk_gl_event_type_get_type".}
proc gdk_gl_drawable_type_get_type*(): GType{.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_drawable_type_get_type".}
proc GDK_TYPE_GL_DRAWABLE_TYPE*(): GType{.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_drawable_type_get_type".}
proc gdk_gl_config_mode_get_type*(): GType{.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_config_mode_get_type".}
proc GDK_TYPE_GL_CONFIG_MODE*(): GType{.cdecl, dynlib: GdkGLExtLib, 
                                        importc: "gdk_gl_config_mode_get_type".}
proc gdk_gl_parse_args*(argc: var int32, argv: ptr cstringArray): gboolean{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_parse_args".}
proc gdk_gl_init_check*(argc: var int32, argv: ptr cstringArray): gboolean{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_init_check".}
proc gdk_gl_init*(argc: var int32, argv: ptr cstringArray){.
    cdecl, dynlib: GdkGLExtLib, importc: "gdk_gl_init".}
proc gdk_gl_query_gl_extension*(extension: cstring): gboolean{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_query_gl_extension".}
proc gdk_gl_get_proc_address*(proc_name: cstring): TGdkGLProc{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_get_proc_address".}
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
  GDK_GL_MODE_RGB* = 0
  GDK_GL_MODE_RGBA* = 0
  GDK_GL_MODE_INDEX* = 1 shl 0
  GDK_GL_MODE_SINGLE* = 0
  GDK_GL_MODE_DOUBLE* = 1 shl 1
  GDK_GL_MODE_STEREO* = 1 shl 2
  GDK_GL_MODE_ALPHA* = 1 shl 3
  GDK_GL_MODE_DEPTH* = 1 shl 4
  GDK_GL_MODE_STENCIL* = 1 shl 5
  GDK_GL_MODE_ACCUM* = 1 shl 6
  GDK_GL_MODE_MULTISAMPLE* = 1 shl 7

type 
  TGdkGLConfigMode* = int32
  PGdkGLConfigMode* = ptr TGdkGLConfigMode

proc GDK_TYPE_GL_CONFIG*(): GType
proc GDK_GL_CONFIG*(anObject: Pointer): PGdkGLConfig
proc GDK_GL_CONFIG_CLASS*(klass: Pointer): PGdkGLConfigClass
proc GDK_IS_GL_CONFIG*(anObject: Pointer): bool
proc GDK_IS_GL_CONFIG_CLASS*(klass: Pointer): bool
proc GDK_GL_CONFIG_GET_CLASS*(obj: Pointer): PGdkGLConfigClass
proc gdk_gl_config_get_type*(): GType{.cdecl, dynlib: GdkGLExtLib, 
                                       importc: "gdk_gl_config_get_type".}
proc gdk_gl_config_get_screen*(glconfig: PGdkGLConfig): PGdkScreen{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_config_get_screen".}
proc gdk_gl_config_get_attrib*(glconfig: PGdkGLConfig, attribute: int, 
                               value: var cint): gboolean{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_config_get_attrib".}
proc gdk_gl_config_get_colormap*(glconfig: PGdkGLConfig): PGdkColormap{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_config_get_colormap".}
proc gdk_gl_config_get_visual*(glconfig: PGdkGLConfig): PGdkVisual{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_config_get_visual".}
proc gdk_gl_config_get_depth*(glconfig: PGdkGLConfig): gint{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_config_get_depth".}
proc gdk_gl_config_get_layer_plane*(glconfig: PGdkGLConfig): gint{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_config_get_layer_plane".}
proc gdk_gl_config_get_n_aux_buffers*(glconfig: PGdkGLConfig): gint{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_config_get_n_aux_buffers".}
proc gdk_gl_config_get_n_sample_buffers*(glconfig: PGdkGLConfig): gint{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_config_get_n_sample_buffers".}
proc gdk_gl_config_is_rgba*(glconfig: PGdkGLConfig): gboolean{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_config_is_rgba".}
proc gdk_gl_config_is_double_buffered*(glconfig: PGdkGLConfig): gboolean{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_config_is_double_buffered".}
proc gdk_gl_config_is_stereo*(glconfig: PGdkGLConfig): gboolean{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_config_is_stereo".}
proc gdk_gl_config_has_alpha*(glconfig: PGdkGLConfig): gboolean{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_config_has_alpha".}
proc gdk_gl_config_has_depth_buffer*(glconfig: PGdkGLConfig): gboolean{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_config_has_depth_buffer".}
proc gdk_gl_config_has_stencil_buffer*(glconfig: PGdkGLConfig): gboolean{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_config_has_stencil_buffer".}
proc gdk_gl_config_has_accum_buffer*(glconfig: PGdkGLConfig): gboolean{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_config_has_accum_buffer".}
proc GDK_TYPE_GL_CONTEXT*(): GType
proc GDK_GL_CONTEXT*(anObject: Pointer): PGdkGLContext
proc GDK_GL_CONTEXT_CLASS*(klass: Pointer): PGdkGLContextClass
proc GDK_IS_GL_CONTEXT*(anObject: Pointer): bool
proc GDK_IS_GL_CONTEXT_CLASS*(klass: Pointer): bool
proc GDK_GL_CONTEXT_GET_CLASS*(obj: Pointer): PGdkGLContextClass
proc gdk_gl_context_get_type*(): GType{.cdecl, dynlib: GdkGLExtLib, 
                                        importc: "gdk_gl_context_get_type".}
proc gdk_gl_context_new*(gldrawable: PGdkGLDrawable, share_list: PGdkGLContext, 
                         direct: gboolean, render_type: int32): PGdkGLContext{.
    cdecl, dynlib: GdkGLExtLib, importc: "gdk_gl_context_new".}
proc gdk_gl_context_destroy*(glcontext: PGdkGLContext){.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_context_destroy".}
proc gdk_gl_context_copy*(glcontext: PGdkGLContext, src: PGdkGLContext, 
                          mask: int32): gboolean{.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_context_copy".}
proc gdk_gl_context_get_gl_drawable*(glcontext: PGdkGLContext): PGdkGLDrawable{.
    cdecl, dynlib: GdkGLExtLib, importc: "gdk_gl_context_get_gl_drawable".}
proc gdk_gl_context_get_gl_config*(glcontext: PGdkGLContext): PGdkGLConfig{.
    cdecl, dynlib: GdkGLExtLib, importc: "gdk_gl_context_get_gl_config".}
proc gdk_gl_context_get_share_list*(glcontext: PGdkGLContext): PGdkGLContext{.
    cdecl, dynlib: GdkGLExtLib, importc: "gdk_gl_context_get_share_list".}
proc gdk_gl_context_is_direct*(glcontext: PGdkGLContext): gboolean{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_context_is_direct".}
proc gdk_gl_context_get_render_type*(glcontext: PGdkGLContext): int32{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_context_get_render_type".}
proc gdk_gl_context_get_current*(): PGdkGLContext{.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_context_get_current".}
proc GDK_TYPE_GL_DRAWABLE*(): GType
proc GDK_GL_DRAWABLE*(inst: Pointer): PGdkGLDrawable
proc GDK_GL_DRAWABLE_CLASS*(vtable: Pointer): PGdkGLDrawableClass
proc GDK_IS_GL_DRAWABLE*(inst: Pointer): bool
proc GDK_IS_GL_DRAWABLE_CLASS*(vtable: Pointer): bool
proc GDK_GL_DRAWABLE_GET_CLASS*(inst: Pointer): PGdkGLDrawableClass
proc gdk_gl_drawable_get_type*(): GType{.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_drawable_get_type".}
proc gdk_gl_drawable_make_current*(gldrawable: PGdkGLDrawable, 
                                   glcontext: PGdkGLContext): gboolean{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_drawable_make_current".}
proc gdk_gl_drawable_is_double_buffered*(gldrawable: PGdkGLDrawable): gboolean{.
    cdecl, dynlib: GdkGLExtLib, importc: "gdk_gl_drawable_is_double_buffered".}
proc gdk_gl_drawable_swap_buffers*(gldrawable: PGdkGLDrawable){.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_drawable_swap_buffers".}
proc gdk_gl_drawable_wait_gl*(gldrawable: PGdkGLDrawable){.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_drawable_wait_gl".}
proc gdk_gl_drawable_wait_gdk*(gldrawable: PGdkGLDrawable){.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_drawable_wait_gdk".}
proc gdk_gl_drawable_gl_begin*(gldrawable: PGdkGLDrawable, 
                               glcontext: PGdkGLContext): gboolean{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_drawable_gl_begin".}
proc gdk_gl_drawable_gl_end*(gldrawable: PGdkGLDrawable){.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_drawable_gl_end".}
proc gdk_gl_drawable_get_gl_config*(gldrawable: PGdkGLDrawable): PGdkGLConfig{.
    cdecl, dynlib: GdkGLExtLib, importc: "gdk_gl_drawable_get_gl_config".}
proc gdk_gl_drawable_get_size*(gldrawable: PGdkGLDrawable, width, height: PGInt){.
    cdecl, dynlib: GdkGLExtLib, importc: "gdk_gl_drawable_get_size".}
proc gdk_gl_drawable_get_current*(): PGdkGLDrawable{.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_drawable_get_current".}
proc GDK_TYPE_GL_PIXMAP*(): GType
proc GDK_GL_PIXMAP*(anObject: Pointer): PGdkGLPixmap
proc GDK_GL_PIXMAP_CLASS*(klass: Pointer): PGdkGLPixmapClass
proc GDK_IS_GL_PIXMAP*(anObject: Pointer): bool
proc GDK_IS_GL_PIXMAP_CLASS*(klass: Pointer): bool
proc GDK_GL_PIXMAP_GET_CLASS*(obj: Pointer): PGdkGLPixmapClass
proc gdk_gl_pixmap_get_type*(): GType{.cdecl, dynlib: GdkGLExtLib, 
                                       importc: "gdk_gl_pixmap_get_type".}
proc gdk_gl_pixmap_new*(glconfig: PGdkGLConfig, pixmap: PGdkPixmap, 
                        attrib_list: ptr int32): PGdkGLPixmap{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_pixmap_new".}
proc gdk_gl_pixmap_destroy*(glpixmap: PGdkGLPixmap){.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_pixmap_destroy".}
proc gdk_gl_pixmap_get_pixmap*(glpixmap: PGdkGLPixmap): PGdkPixmap{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_pixmap_get_pixmap".}
proc gdk_pixmap_set_gl_capability*(pixmap: PGdkPixmap, glconfig: PGdkGLConfig, 
                                   attrib_list: ptr int32): PGdkGLPixmap{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_pixmap_set_gl_capability".}
proc gdk_pixmap_unset_gl_capability*(pixmap: PGdkPixmap){.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_pixmap_unset_gl_capability".}
proc gdk_pixmap_is_gl_capable*(pixmap: PGdkPixmap): gboolean{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_pixmap_is_gl_capable".}
proc gdk_pixmap_get_gl_pixmap*(pixmap: PGdkPixmap): PGdkGLPixmap{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_pixmap_get_gl_pixmap".}
proc gdk_pixmap_get_gl_drawable*(pixmap: PGdkPixmap): PGdkGLDrawable
proc GDK_TYPE_GL_WINDOW*(): GType
proc GDK_GL_WINDOW*(anObject: Pointer): PGdkGLWindow
proc GDK_GL_WINDOW_CLASS*(klass: Pointer): PGdkGLWindowClass
proc GDK_IS_GL_WINDOW*(anObject: Pointer): bool
proc GDK_IS_GL_WINDOW_CLASS*(klass: Pointer): bool
proc GDK_GL_WINDOW_GET_CLASS*(obj: Pointer): PGdkGLWindowClass
proc gdk_gl_window_get_type*(): GType{.cdecl, dynlib: GdkGLExtLib, 
                                       importc: "gdk_gl_window_get_type".}
proc gdk_gl_window_new*(glconfig: PGdkGLConfig, window: PGdkWindow, 
                        attrib_list: ptr int32): PGdkGLWindow{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_window_new".}
proc gdk_gl_window_destroy*(glwindow: PGdkGLWindow){.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_window_destroy".}
proc gdk_gl_window_get_window*(glwindow: PGdkGLWindow): PGdkWindow{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_window_get_window".}
proc gdk_window_set_gl_capability*(window: PGdkWindow, glconfig: PGdkGLConfig, 
                                   attrib_list: ptr int32): PGdkGLWindow{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_window_set_gl_capability".}
proc gdk_window_unset_gl_capability*(window: PGdkWindow){.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_window_unset_gl_capability".}
proc gdk_window_is_gl_capable*(window: PGdkWindow): gboolean{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_window_is_gl_capable".}
proc gdk_window_get_gl_window*(window: PGdkWindow): PGdkGLWindow{.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_window_get_gl_window".}
proc gdk_window_get_gl_drawable*(window: PGdkWindow): PGdkGLDrawable
proc gdk_gl_draw_cube*(solid: gboolean, size: float64){.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_draw_cube".}
proc gdk_gl_draw_sphere*(solid: gboolean, radius: float64, slices: int32, 
                         stacks: int32){.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_draw_sphere".}
proc gdk_gl_draw_cone*(solid: gboolean, base: float64, height: float64, 
                       slices: int32, stacks: int32){.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_draw_cone".}
proc gdk_gl_draw_torus*(solid: gboolean, inner_radius: float64, 
                        outer_radius: float64, nsides: int32, rings: int32){.
    cdecl, dynlib: GdkGLExtLib, importc: "gdk_gl_draw_torus".}
proc gdk_gl_draw_tetrahedron*(solid: gboolean){.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_draw_tetrahedron".}
proc gdk_gl_draw_octahedron*(solid: gboolean){.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_draw_octahedron".}
proc gdk_gl_draw_dodecahedron*(solid: gboolean){.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_draw_dodecahedron".}
proc gdk_gl_draw_icosahedron*(solid: gboolean){.cdecl, dynlib: GdkGLExtLib, 
    importc: "gdk_gl_draw_icosahedron".}
proc gdk_gl_draw_teapot*(solid: gboolean, scale: float64){.cdecl, 
    dynlib: GdkGLExtLib, importc: "gdk_gl_draw_teapot".}
proc HEADER_GDKGLEXT_CHECK_VERSION*(major, minor, micro: guint): bool = 
  result = (HEADER_GDKGLEXT_MAJOR_VERSION > major) or
      ((HEADER_GDKGLEXT_MAJOR_VERSION == major) and
      (HEADER_GDKGLEXT_MINOR_VERSION > minor)) or
      ((HEADER_GDKGLEXT_MAJOR_VERSION == major) and
      (HEADER_GDKGLEXT_MINOR_VERSION == minor) and
      (HEADER_GDKGLEXT_MICRO_VERSION >= micro))

proc GDK_TYPE_GL_CONFIG*(): GType = 
  result = gdk_gl_config_get_type()

proc GDK_GL_CONFIG*(anObject: Pointer): PGdkGLConfig = 
  result = cast[PGdkGLConfig](G_TYPE_CHECK_INSTANCE_CAST(anObject, GDK_TYPE_GL_CONFIG()))

proc GDK_GL_CONFIG_CLASS*(klass: Pointer): PGdkGLConfigClass = 
  result = cast[PGdkGLConfigClass](G_TYPE_CHECK_CLASS_CAST(klass, GDK_TYPE_GL_CONFIG()))

proc GDK_IS_GL_CONFIG*(anObject: Pointer): bool = 
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, GDK_TYPE_GL_CONFIG())

proc GDK_IS_GL_CONFIG_CLASS*(klass: Pointer): bool = 
  result = G_TYPE_CHECK_CLASS_TYPE(klass, GDK_TYPE_GL_CONFIG())

proc GDK_GL_CONFIG_GET_CLASS*(obj: Pointer): PGdkGLConfigClass = 
  result = cast[PGdkGLConfigClass](G_TYPE_INSTANCE_GET_CLASS(obj, GDK_TYPE_GL_CONFIG()))

proc GDK_TYPE_GL_CONTEXT*(): GType = 
  result = gdk_gl_context_get_type()

proc GDK_GL_CONTEXT*(anObject: Pointer): PGdkGLContext = 
  result = cast[PGdkGLContext](G_TYPE_CHECK_INSTANCE_CAST(anObject, 
      GDK_TYPE_GL_CONTEXT()))

proc GDK_GL_CONTEXT_CLASS*(klass: Pointer): PGdkGLContextClass = 
  result = cast[PGdkGLContextClass](G_TYPE_CHECK_CLASS_CAST(klass, GDK_TYPE_GL_CONTEXT()))

proc GDK_IS_GL_CONTEXT*(anObject: Pointer): bool = 
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, GDK_TYPE_GL_CONTEXT())

proc GDK_IS_GL_CONTEXT_CLASS*(klass: Pointer): bool = 
  result = G_TYPE_CHECK_CLASS_TYPE(klass, GDK_TYPE_GL_CONTEXT())

proc GDK_GL_CONTEXT_GET_CLASS*(obj: Pointer): PGdkGLContextClass = 
  result = cast[PGdkGLContextClass](G_TYPE_INSTANCE_GET_CLASS(obj, GDK_TYPE_GL_CONTEXT()))

proc GDK_TYPE_GL_DRAWABLE*(): GType = 
  result = gdk_gl_drawable_get_type()

proc GDK_GL_DRAWABLE*(inst: Pointer): PGdkGLDrawable = 
  result = cast[PGdkGLDrawable](G_TYPE_CHECK_INSTANCE_CAST(inst, GDK_TYPE_GL_DRAWABLE()))

proc GDK_GL_DRAWABLE_CLASS*(vtable: Pointer): PGdkGLDrawableClass = 
  result = cast[PGdkGLDrawableClass](G_TYPE_CHECK_CLASS_CAST(vtable, 
      GDK_TYPE_GL_DRAWABLE()))

proc GDK_IS_GL_DRAWABLE*(inst: Pointer): bool = 
  result = G_TYPE_CHECK_INSTANCE_TYPE(inst, GDK_TYPE_GL_DRAWABLE())

proc GDK_IS_GL_DRAWABLE_CLASS*(vtable: Pointer): bool = 
  result = G_TYPE_CHECK_CLASS_TYPE(vtable, GDK_TYPE_GL_DRAWABLE())

proc GDK_GL_DRAWABLE_GET_CLASS*(inst: Pointer): PGdkGLDrawableClass = 
  result = cast[PGdkGLDrawableClass](G_TYPE_INSTANCE_GET_INTERFACE(inst, 
      GDK_TYPE_GL_DRAWABLE()))

proc GDK_TYPE_GL_PIXMAP*(): GType = 
  result = gdk_gl_pixmap_get_type()

proc GDK_GL_PIXMAP*(anObject: Pointer): PGdkGLPixmap = 
  result = cast[PGdkGLPixmap](G_TYPE_CHECK_INSTANCE_CAST(anObject, GDK_TYPE_GL_PIXMAP()))

proc GDK_GL_PIXMAP_CLASS*(klass: Pointer): PGdkGLPixmapClass = 
  result = cast[PGdkGLPixmapClass](G_TYPE_CHECK_CLASS_CAST(klass, GDK_TYPE_GL_PIXMAP()))

proc GDK_IS_GL_PIXMAP*(anObject: Pointer): bool = 
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, GDK_TYPE_GL_PIXMAP())

proc GDK_IS_GL_PIXMAP_CLASS*(klass: Pointer): bool = 
  result = G_TYPE_CHECK_CLASS_TYPE(klass, GDK_TYPE_GL_PIXMAP())

proc GDK_GL_PIXMAP_GET_CLASS*(obj: Pointer): PGdkGLPixmapClass = 
  result = cast[PGdkGLPixmapClass](G_TYPE_INSTANCE_GET_CLASS(obj, GDK_TYPE_GL_PIXMAP()))

proc gdk_pixmap_get_gl_drawable*(pixmap: PGdkPixmap): PGdkGLDrawable = 
  result = GDK_GL_DRAWABLE(gdk_pixmap_get_gl_pixmap(pixmap))

proc GDK_TYPE_GL_WINDOW*(): GType = 
  result = gdk_gl_window_get_type()

proc GDK_GL_WINDOW*(anObject: Pointer): PGdkGLWindow = 
  result = cast[PGdkGLWindow](G_TYPE_CHECK_INSTANCE_CAST(anObject, GDK_TYPE_GL_WINDOW()))

proc GDK_GL_WINDOW_CLASS*(klass: Pointer): PGdkGLWindowClass = 
  result = cast[PGdkGLWindowClass](G_TYPE_CHECK_CLASS_CAST(klass, GDK_TYPE_GL_WINDOW()))

proc GDK_IS_GL_WINDOW*(anObject: Pointer): bool = 
  result = G_TYPE_CHECK_INSTANCE_TYPE(anObject, GDK_TYPE_GL_WINDOW())

proc GDK_IS_GL_WINDOW_CLASS*(klass: Pointer): bool = 
  result = G_TYPE_CHECK_CLASS_TYPE(klass, GDK_TYPE_GL_WINDOW())

proc GDK_GL_WINDOW_GET_CLASS*(obj: Pointer): PGdkGLWindowClass = 
  result = cast[PGdkGLWindowClass](G_TYPE_INSTANCE_GET_CLASS(obj, GDK_TYPE_GL_WINDOW()))

proc gdk_window_get_gl_drawable*(window: PGdkWindow): PGdkGLDrawable = 
  result = GDK_GL_DRAWABLE(gdk_window_get_gl_window(window))
