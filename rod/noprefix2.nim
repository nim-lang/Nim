# strip those silly GTK/ATK prefixes...

import
  expandimportc, os

const
  filelist = [
    ("gtk/pango", "pango"),
    ("gtk/pangoutils", "pango")
  ]

for filename, prefix in items(filelist):
  var f = addFileExt(filename, "nim")
  main("lib/newwrap" / f, "lib/newwrap" / filename & ".new.nim", prefix)

