discard """
  joinable: false # not strictly necessary
"""

import std/tempfiles
import std/[os, nre]

const
  prefix = "D20210502T100442" # safety precaution to only affect files/dirs with this prefix
  suffix = ".tmp"

block:
  var t1 = createTempFile(prefix, suffix)
  var t2 = createTempFile(prefix, suffix)
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

block: # createTempDir
  doAssertRaises(OSError): discard createTempDir(prefix, suffix, "nonexistent")

  block:
    let dir1 = createTempDir(prefix, suffix)
    let dir2 = createTempDir(prefix, suffix)
    defer:
      removeDir(dir1)
      removeDir(dir2)
    doAssert dir1 != dir2

    doAssert dirExists(dir1)
    doAssert dir1.lastPathPart.contains(re"^D20210502T100442(\w+).tmp$")
    doAssert dir1.parentDir == getTempDir().normalizePathEnd()

  block:
    let dir3 = createTempDir(prefix, "_mytmp", ".")
    doAssert dir3.lastPathPart.contains(re"^D20210502T100442(\w+)_mytmp$")
    doAssert dir3.parentDir == "." # not getCurrentDir(): we honor the absolute/relative state of input `dir`
    removeDir(dir3)
