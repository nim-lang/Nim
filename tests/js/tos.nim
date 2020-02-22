static: doAssert defined(nodejs)

import os

block:
  doAssert "./foo//./bar/".normalizedPath == "foo/bar"
  doAssert relativePath(".//foo/bar", "foo") == "bar"
  doAssert "/".isAbsolute
  doAssert not "".isAbsolute
  doAssert not ".".isAbsolute
  doAssert not "foo".isAbsolute
  doAssert relativePath(getCurrentDir()) == "."
  doAssert relativePath(getCurrentDir() / "foo", "bar") == "../foo"
  doAssert relativePath("", "bar") == ""
  doAssert normalizedPath(".///foo//./") == "foo"
