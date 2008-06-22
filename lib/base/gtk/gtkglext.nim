import 
  Glib2, Gdk2, Gtk2, GdkGLExt

const 
  GtkGLExtLib* = if defined(WIN32): "libgtkglext-win32-1.0-0.dll" else: "libgtkglext-x11-1.0.so"

const 
  HEADER_GTKGLEXT_MAJOR_VERSION* = 1
  HEADER_GTKGLEXT_MINOR_VERSION* = 0
  HEADER_GTKGLEXT_MICRO_VERSION* = 6
  HEADER_GTKGLEXT_INTERFACE_AGE* = 4
  HEADER_GTKGLEXT_BINARY_AGE* = 6

proc gtk_gl_parse_args*(argc: Plongint, argv: PPPChar): gboolean{.cdecl, 
    dynlib: GtkGLExtLib, importc: "gtk_gl_parse_args".}
proc gtk_gl_init_check*(argc: Plongint, argv: PPPChar): gboolean{.cdecl, 
    dynlib: GtkGLExtLib, importc: "gtk_gl_init_check".}
proc gtk_gl_init*(argc: Plongint, argv: PPPChar){.cdecl, dynlib: GtkGLExtLib, 
    importc: "gtk_gl_init".}
proc gtk_widget_set_gl_capability*(widget: PGtkWidget, glconfig: PGdkGLConfig, 
                                   share_list: PGdkGLContext, direct: gboolean, 
                                   render_type: int): gboolean{.cdecl, 
    dynlib: GtkGLExtLib, importc: "gtk_widget_set_gl_capability".}
proc gtk_widget_is_gl_capable*(widget: PGtkWidget): gboolean{.cdecl, 
    dynlib: GtkGLExtLib, importc: "gtk_widget_is_gl_capable".}
proc gtk_widget_get_gl_config*(widget: PGtkWidget): PGdkGLConfig{.cdecl, 
    dynlib: GtkGLExtLib, importc: "gtk_widget_get_gl_config".}
proc gtk_widget_create_gl_context*(widget: PGtkWidget, 
                                   share_list: PGdkGLContext, direct: gboolean, 
                                   render_type: int): PGdkGLContext{.cdecl, 
    dynlib: GtkGLExtLib, importc: "gtk_widget_create_gl_context".}
proc gtk_widget_get_gl_context*(widget: PGtkWidget): PGdkGLContext{.cdecl, 
    dynlib: GtkGLExtLib, importc: "gtk_widget_get_gl_context".}
proc gtk_widget_get_gl_window*(widget: PGtkWidget): PGdkGLWindow{.cdecl, 
    dynlib: GtkGLExtLib, importc: "gtk_widget_get_gl_window".}
proc gtk_widget_get_gl_drawable*(widget: PGtkWidget): PGdkGLDrawable = 
  nil

proc HEADER_GTKGLEXT_CHECK_VERSION*(major, minor, micro: guint): bool = 
  result = (HEADER_GTKGLEXT_MAJOR_VERSION > major) or
      ((HEADER_GTKGLEXT_MAJOR_VERSION == major) and
      (HEADER_GTKGLEXT_MINOR_VERSION > minor)) or
      ((HEADER_GTKGLEXT_MAJOR_VERSION == major) and
      (HEADER_GTKGLEXT_MINOR_VERSION == minor) and
      (HEADER_GTKGLEXT_MICRO_VERSION >= micro))

proc gtk_widget_get_gl_drawable*(widget: PGtkWidget): PGdkGLDrawable = 
  result = GDK_GL_DRAWABLE(gtk_widget_get_gl_window(widget))
