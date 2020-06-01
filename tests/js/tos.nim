static: doAssert defined(nodejs)

import os

template fn() =
  doAssert "./foo//./bar/".normalizedPath == "foo/bar"
  doAssert relativePath(".//foo/bar", "foo") == "bar"
  doAssert "/".isAbsolute
  doAssert not "".isAbsolute
  doAssert not ".".isAbsolute
  doAssert not "foo".isAbsolute
  doAssert relativePath("", "bar") == ""
  doAssert normalizedPath(".///foo//./") == "foo"
  doAssert getHomeDir() == getHomeDir().static
  doAssert relativePath("foo/bar", "baz") == "../foo/bar".unixToNativePath
  when nimvm: discard
  else:
    let cwd = getCurrentDir()
    doAssert cwd.isAbsolute
    doAssert relativePath(cwd / "foo", "bar") == ".." / "foo"
static: fn()
fn()
