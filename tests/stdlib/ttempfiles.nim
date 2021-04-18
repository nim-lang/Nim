import std/[os, tempfiles]


doAssert createTempDir("nim", "tmp") != createTempDir("nim", "tmp")

block:
  let t1 = createTempFile("nim", ".tmp")
  let t2 = createTempFile("nim", ".tmp")
  doAssert t1.path != t2.path
  close(t1.fd)
  close(t2.fd)
  removeFile(t1.path)
  removeFile(t2.path)
