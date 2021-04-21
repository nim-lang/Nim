import std/[os, tempfiles]


doAssert createTempDir("nim", "tmp") != createTempDir("nim", "tmp")

block:
  var t1 = createTempFile("nim", ".tmp")
  var t2 = createTempFile("nim", ".tmp")
  doAssert t1.path != t2.path

  write(t1.fd, "1234")
  doAssert readAll(t2.fd) == ""

  close(t1.fd)
  close(t2.fd)
  removeFile(t1.path)
  removeFile(t2.path)
