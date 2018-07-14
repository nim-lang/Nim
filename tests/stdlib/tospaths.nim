discard """
  file: "tospaths.nim"
  output: ""
"""
# test the ospaths module

import os

block unixToNativePath:
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

block normalizePathEnd:
  doAssert "".normalizePathEnd == ""
  doAssert "".normalizePathEnd(trailingSep = true) == ""
  when defined(posix):
    doAssert "/".normalizePathEnd == "/"
    doAssert "foo.bar".normalizePathEnd == "foo.bar"
    doAssert "foo.bar".normalizePathEnd(trailingSep = true) == "foo.bar/"
  when defined(Windows):
    doAssert r"C:\\".normalizePathEnd == r"C:\"
    doAssert r"C:\".normalizePathEnd(trailingSep = true) == r"C:\"
    doAssert r"C:\foo\\bar\".normalizePathEnd == r"C:\foo\\bar"

block joinPath:
  when defined(posix):
    doAssert joinPath("", "/lib") == "/lib"

