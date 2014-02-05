discard """
  disabled: true
"""

# Test wether the bindings at least compile...

import
  unicode, cgi, terminal, libcurl, 
  parsexml, parseopt, parsecfg,
  osproc, complex,
  sdl, smpeg, sdl_gfx, sdl_net, sdl_mixer, sdl_ttf,
  sdl_image, sdl_mixer_nosmpeg,
  cursorfont, xatom, xf86vmode, xkb, xrandr, xshm, xvlib, keysym, xcms, xi,
  xkblib, xrender, xutil, x, xf86dga, xinerama, xlib, xresource, xv,
  gtk2, glib2, pango, gdk2,
  cairowin32, cairoxlib,
  odbcsql,
  gl, glut, glu, glx, glext, wingl,
  lua, lualib, lauxlib, mysql, sqlite3, python, tcl,
  db_postgres, db_mysql, db_sqlite, ropes, sockets, browsers, httpserver,
  httpclient, parseutils, unidecode, xmldom, xmldomparser, xmltree, xmlparser,
  htmlparser, re, graphics, colors, pegs, subexes, dialogs
  
when defined(linux):
  import
    zlib, zipfiles

writeln(stdout, "test compilation of binding modules")
