{.deadCodeElim: on.}
import
  Glib2, Gdk2, gtk2, GdkGLExt

when defined(windows):
  const
    GLExtLib* = "libgtkglext-win32-1.0-0.dll"
elif defined(macosx):
  const
    GLExtLib* = "libgtkglext-x11-1.0.dylib"
else:
  const
    GLExtLib* = "libgtkglext-x11-1.0.so"

const
  HEADER_GTKGLEXT_MAJOR_VERSION* = 1
  HEADER_GTKGLEXT_MINOR_VERSION* = 0
  HEADER_GTKGLEXT_MICRO_VERSION* = 6
  HEADER_GTKGLEXT_INTERFACE_AGE* = 4
  HEADER_GTKGLEXT_BINARY_AGE* = 6

proc gl_parse_args*(argc: ptr int32, argv: PPPChar): gboolean{.cdecl,
    dynlib: GLExtLib, importc: "gtk_gl_parse_args".}
proc gl_init_check*(argc: ptr int32, argv: PPPChar): gboolean{.cdecl,
    dynlib: GLExtLib, importc: "gtk_gl_init_check".}
proc gl_init*(argc: ptr int32, argv: PPPChar){.cdecl, dynlib: GLExtLib,
    importc: "gtk_gl_init".}
proc set_gl_capability*(widget: PWidget, glconfig: PGLConfig,
                               share_list: PGLContext, direct: gboolean,
                               render_type: int): gboolean{.cdecl,
    dynlib: GLExtLib, importc: "gtk_widget_set_gl_capability".}
proc is_gl_capable*(widget: PWidget): gboolean{.cdecl, dynlib: GLExtLib,
    importc: "gtk_widget_is_gl_capable".}
proc get_gl_config*(widget: PWidget): PGLConfig{.cdecl,
    dynlib: GLExtLib, importc: "gtk_widget_get_gl_config".}
proc create_gl_context*(widget: PWidget, share_list: PGLContext,
                               direct: gboolean, render_type: int): PGLContext{.
    cdecl, dynlib: GLExtLib, importc: "gtk_widget_create_gl_context".}
proc get_gl_context*(widget: PWidget): PGLContext{.cdecl,
    dynlib: GLExtLib, importc: "gtk_widget_get_gl_context".}
proc get_gl_window*(widget: PWidget): PGLWindow{.cdecl,
    dynlib: GLExtLib, importc: "gtk_widget_get_gl_window".}

proc HEADER_GTKGLEXT_CHECK_VERSION*(major, minor, micro: guint): bool =
  result = (HEADER_GTKGLEXT_MAJOR_VERSION > major) or
      ((HEADER_GTKGLEXT_MAJOR_VERSION == major) and
      (HEADER_GTKGLEXT_MINOR_VERSION > minor)) or
      ((HEADER_GTKGLEXT_MAJOR_VERSION == major) and
      (HEADER_GTKGLEXT_MINOR_VERSION == minor) and
      (HEADER_GTKGLEXT_MICRO_VERSION >= micro))

proc get_gl_drawable*(widget: PWidget): PGLDrawable =
  result = GL_DRAWABLE(get_gl_window(widget))
