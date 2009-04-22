# Test wether the bindings at least compile...

import
  unicode, cgi, terminal, libcurl, web, 
  parsexml, parseopt, parsecfg,
  osproc, zipfiles,
  sdl, smpeg, sdl_gfx, sdl_net, sdl_mixer, sdl_ttf,
  sdl_image, sdl_mixer_nosmpeg,
  cursorfont, xatom, xf86vmode, xkb, xrandr, xshm, xvlib, keysym, xcms, xi,
  xkblib, xrender, xutil, x, xf86dga, xinerama, xlib, xresource, xv,
  gtk2, glib2, pango, gdk2,
  cairowin32, cairoxlib,
  odbcsql,
  gl, glut, glu, glx, glext, wingl,
  zlib

import "lib/base/lua/lua"
import "lib/base/lua/lualib"
import "lib/base/lua/lauxlib"

writeln(stdout, "test compilation of binding modules")
