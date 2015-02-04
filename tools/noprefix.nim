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

    ("pcre/pcre", "pcre")
  ]

proc createDirs =
  createDir("lib/newwrap/sdl")
  createDir("lib/newwrap/pcre")

for filename, prefix in items(filelist):
  var f = addFileExt(filename, "nim")
  main("lib/wrappers" / f, "lib/newwrap" / f, prefix)

