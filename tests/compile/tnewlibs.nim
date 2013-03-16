# Test wether the bindings at least compile...

import
  tcl,
  sdl, smpeg, sdl_gfx, sdl_net, sdl_mixer, sdl_ttf,
  sdl_image, sdl_mixer_nosmpeg,
  gtk2, glib2, pango, gdk2,
  unicode, cgi, terminal, libcurl, 
  parsexml, parseopt, parsecfg,
  osproc,
  cairowin32, cairoxlib,
  gl, glut, glu, glx, glext, wingl,
  lua, lualib, lauxlib, mysql, sqlite3, db_mongo, md5, asyncio, mimetypes,
  cookies, events, ftpclient, scgi, irc
  

writeln(stdout, "test compilation of binding modules")
