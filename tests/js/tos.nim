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

import std/sequtils

template main =
  putEnv("foo", "bar")
  doAssert getEnv("foo") == "bar"
  doAssert existsEnv("foo")

  putEnv("foo", "")
  doAssert existsEnv("foo")
  putEnv("foo", "bar2")
  doAssert getEnv("foo") == "bar2"

  when nimvm:
    discard
  else:
    # need support in vmops: envPairs, delEnv
    let s = toSeq(envPairs())
    doAssert ("foo", "bar2") in s
    doAssert ("foo", "bar") notin s

    delEnv("foo")
    doAssert not existsEnv("foo")

static: main()
main()
