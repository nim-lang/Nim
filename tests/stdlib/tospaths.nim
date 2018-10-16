discard """
  file: "tospaths.nim"
  output: ""
"""
# test the ospaths module

import os

doAssert unixToNativePath("") == ""
doAssert unixToNativePath(".") == $CurDir
doAssert unixToNativePath("..") == $ParDir
doAssert isAbsolute(unixToNativePath("/"))
doAssert isAbsolute(unixToNativePath("/", "a"))
doAssert isAbsolute(unixToNativePath("/a"))
doAssert isAbsolute(unixToNativePath("/a", "a"))
doAssert isAbsolute(unixToNativePath("/a/b"))
doAssert isAbsolute(unixToNativePath("/a/b", "a"))
doAssert unixToNativePath("a/b") == joinPath("a", "b")

when defined(macos):
  doAssert unixToNativePath("./") == ":"
  doAssert unixToNativePath("./abc") == ":abc"
  doAssert unixToNativePath("../abc") == "::abc"
  doAssert unixToNativePath("../../abc") == ":::abc"
  doAssert unixToNativePath("/abc", "a") == "abc"
  doAssert unixToNativePath("/abc/def", "a") == "abc:def"
elif doslikeFileSystem:
  doAssert unixToNativePath("./") == ".\\"
  doAssert unixToNativePath("./abc") == ".\\abc"
  doAssert unixToNativePath("../abc") == "..\\abc"
  doAssert unixToNativePath("../../abc") == "..\\..\\abc"
  doAssert unixToNativePath("/abc", "a") == "a:\\abc"
  doAssert unixToNativePath("/abc/def", "a") == "a:\\abc\\def"
else:
  #Tests for unix
  doAssert unixToNativePath("./") == "./"
  doAssert unixToNativePath("./abc") == "./abc"
  doAssert unixToNativePath("../abc") == "../abc"
  doAssert unixToNativePath("../../abc") == "../../abc"
  doAssert unixToNativePath("/abc", "a") == "/abc"
  doAssert unixToNativePath("/abc/def", "a") == "/abc/def"

block extractFilenameTest:
  doAssert extractFilename("") == ""
  when defined(posix):
    doAssert extractFilename("foo/bar") == "bar"
    doAssert extractFilename("foo/bar.txt") == "bar.txt"
    doAssert extractFilename("foo/") == ""
    doAssert extractFilename("/") == ""
  when doslikeFileSystem:
    doAssert extractFilename(r"foo\bar") == "bar"
    doAssert extractFilename(r"foo\bar.txt") == "bar.txt"
    doAssert extractFilename(r"foo\") == ""
    doAssert extractFilename(r"C:\") == ""

block lastPathPartTest:
  doAssert lastPathPart("") == ""
  when defined(posix):
    doAssert lastPathPart("foo/bar.txt") == "bar.txt"
    doAssert lastPathPart("foo/") == "foo"
    doAssert lastPathPart("/") == ""
  when doslikeFileSystem:
    doAssert lastPathPart(r"foo\bar.txt") == "bar.txt"
    doAssert lastPathPart(r"foo\") == "foo"

block:
  proc testRelativePath(path, baseDir, curDir = "", res: string): bool {.noSideEffect.} =
    #debugEcho path, ", ", baseDir, ", ", curDir, ", ", res
    let r =
      relativePath(
        path.unixToNativePath("a"),
        baseDir.unixToNativePath("a"),
        curDir.unixToNativePath("a"))
    #debugEcho r
    return r == res.unixToNativePath

  proc testRelativePathRaise(path, baseDir, curDir = "") {.noSideEffect.} =
    try:
      discard testRelativePath(path, baseDir, curDir, "")
      doAssert false, "Should raise ValueError"
    except ValueError:
      discard

  #Absolute path and absolute path
  doAssert testRelativePath("/", "/", res = ".")
  doAssert testRelativePath("/b", "/a", res = "../b")
  doAssert testRelativePath("/ab", "/a", res = "../ab")
  doAssert testRelativePath("/a", "/ab", res = "../a")
  doAssert testRelativePath("/x/a", "/x/a", res = ".")
  doAssert testRelativePath("/x/a", "/x/a/y", res = "..")
  doAssert testRelativePath("/x/a", "/x/a/y/z", res = "../..")
  doAssert testRelativePath("/x/a", "/x/ab/c", res = "../../a")
  doAssert testRelativePath("/x/a/bc", "/x/a", res = "bc")
  doAssert testRelativePath("/x/a/bc/d", "/x/a", res = "bc/d")
  doAssert testRelativePath("/x/ab", "/x/a/", res = "../ab")
  doAssert testRelativePath("/x/ab", "/x/a", res = "../ab")
  doAssert testRelativePath("/x/y/z/", "/u/v/w", res = "../../../x/y/z/")

  when doslikeFileSystem:
    doAssert relativePath("a:\\a", "b:\\") == "a:\\a"

  #Relative path and Relative path
  proc testRelativePathFromRelative(path, baseDir, curDir = "", res: string) =
    for i in ["", "./"]:
      for j in ["", "/"]:
        for k in ["", "./"]:
          for l in ["", "/"]:
            for m in ["", "/"]:
              let r = if path == "." or res == "." or res == "..": res else: res & j
              doAssert testRelativePath(i & path & j, k & baseDir & l, m & curDir, r)

  testRelativePathFromRelative("a", "a", "", ".")
  testRelativePathFromRelative("a", "b", "", "../a")
  testRelativePathFromRelative("a", "ab", "", "../a")
  testRelativePathFromRelative("ab", "a", "", "../ab")
  testRelativePathFromRelative("a", "a/b", "", "..")
  testRelativePathFromRelative("a/b", "a", "", "b")
  testRelativePathFromRelative("a/a", "ab", "", "../a/a")
  testRelativePathFromRelative("a/ab", "a/a", "", "../ab")
  testRelativePathFromRelative("a/a", "a/ab", "", "../a")
  testRelativePathFromRelative(".", "..", "a", "a")
  testRelativePathFromRelative("..", "..", "a", ".")
  testRelativePathFromRelative("../a", "../b", "a", "../a")
  testRelativePathFromRelative("../c", "b", "a", "../../c")
  testRelativePathFromRelative("../d", "./", "a", "../d")
  testRelativePathFromRelative("b", "..", "a", "a/b")
  testRelativePathFromRelative("b", "../b", "a", "../a/b")
  testRelativePathFromRelative("b", "../bb", "a", "../a/b")
  testRelativePathFromRelative("x", "../..", "a/b", "a/b/x")

  testRelativePathRaise("a", "..", "")

  #Relative and absolute
  doAssert testRelativePath("a", "/a", "/", ".")
  doAssert testRelativePath("/a", "a", "/", ".")
  doAssert testRelativePath("/a", "a", "/x", "../../a")
  doAssert testRelativePath("a", "/a", "/x", "../x/a")
  doAssert testRelativePath("..", "/a", "/x", "..")
  doAssert testRelativePath("../a", "/a", "/x", ".")
  doAssert testRelativePath("/a", "..", "/x", "a")
  doAssert testRelativePath("/a", "../b", "/x", "../a")
  doAssert testRelativePath("/a", "../a", "/x", ".")
  doAssert testRelativePath("/a", "../../", "/x/y", "a")

  testRelativePathRaise("a", "/a", "")
  testRelativePathRaise("/", "..", "/")
  testRelativePathRaise("..", "/", "/")
  testRelativePathRaise("/", "../../", "/x")
  testRelativePathRaise("../../", "/", "/x")
