# strip those silly GTK/ATK prefixes...

import
  expandimportc, os

const
  filelist = [
    ("sdl/sdl", "sdl"),
    ("sdl/sdl_net", "sdl"),
    ("sdl/sdl_gfx", "sdl"),
    ("sdl/sdl_image", "sdl"),
    ("sdl/sdl_mixer_nosmpeg", "sdl"),
    ("sdl/sdl_mixer", "sdl"),
    ("sdl/sdl_ttf", "sdl"),
    ("sdl/smpeg", "sdl"),

    ("libcurl", "curl"),
    ("mysql", "mysql"),
    ("postgres", ""),
    ("sqlite3", "sqlite3"),
    ("tcl", "tcl"),
    ("cairo/cairo", "cairo"),
    ("cairo/cairoft", "cairo"),
    ("cairo/cairowin32", "cairo"),
    ("cairo/cairoxlib", "cairo"),

    ("gtk/atk", "atk"),
    ("gtk/gdk2", "gdk"),
    ("gtk/gdk2pixbuf", "gdk"),
    ("gtk/gdkglext", "gdk"),
    ("gtk/glib2", ""),
    ("gtk/gtk2", "gtk"),
    ("gtk/gtkglext", "gtk"),
    ("gtk/gtkhtml", "gtk"),
    ("gtk/libglade2", "glade"),
    ("gtk/pango", "pango"),
    ("gtk/pangoutils", "pango"),

    ("lua/lua", "lua"),
    ("lua/lauxlib", "luaL"),
    ("lua/lualib", "lua"),

    ("opengl/gl", ""),
    ("opengl/glext", ""),
    ("opengl/wingl", ""),
    ("opengl/glu", ""),
    ("opengl/glut", ""),
    ("opengl/glx", ""),

    ("pcre/pcre", "pcre")
  ]

proc createDirs =
  createDir("lib/newwrap/sdl")
  createDir("lib/newwrap/cairo")
  createDir("lib/newwrap/gtk")
  createDir("lib/newwrap/lua")
  createDir("lib/newwrap/opengl")
  createDir("lib/newwrap/pcre")

for filename, prefix in items(filelist):
  var f = addFileExt(filename, "nim")
  main("lib/wrappers" / f, "lib/newwrap" / f, prefix)

