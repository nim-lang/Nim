# xxx consider merging this in tests/stdlib/tos.nim for increased coverage (with selecting disabling)

static: doAssert defined(nodejs)

import os

block:
  doAssert "./foo//./bar/".normalizedPath == "foo/bar"
  doAssert relativePath(".//foo/bar", "foo") == "bar"
  doAssert "/".isAbsolute
  doAssert not "".isAbsolute
  doAssert not ".".isAbsolute
  doAssert not "foo".isAbsolute
  doAssert relativePath("", "bar") == ""
  doAssert normalizedPath(".///foo//./") == "foo"
  let cwd = getCurrentDir()

  let isWindows = '\\' in cwd
  # defined(windows) doesn't work with -d:nodejs but should
  # these actually break because of that (see https://github.com/nim-lang/Nim/issues/13469)
  if not isWindows:
    doAssert cwd.isAbsolute
    doAssert relativePath(getCurrentDir() / "foo", "bar") == "../foo"
