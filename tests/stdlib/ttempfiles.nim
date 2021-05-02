import std/[os, tempfiles]


doAssert createTempDir("nim", "tmp") != createTempDir("nim", "tmp")

block:
  var t1 = createTempFile("nim", ".tmp")
  var t2 = createTempFile("nim", ".tmp")
  defer:
    close(t1.cfile)
    close(t2.cfile)
    removeFile(t1.path)
    removeFile(t2.path)

  doAssert t1.path != t2.path

  let s = "1234"
  write(t1.cfile, s)
  doAssert readAll(t2.cfile) == ""
  doAssert readAll(t1.cfile) == ""
  t1.cfile.setFilePos 0
  doAssert readAll(t1.cfile) == s

