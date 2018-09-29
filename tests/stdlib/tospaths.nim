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
  when defined(posix):
    doAssert extractFilename("foo/bar") == "bar"
    doAssert extractFilename("foo/bar.txt") == "bar.txt"
    doAssert extractFilename("foo/") == ""
    doAssert extractFilename("foo/bar.txt", ignoreTrailingSep = true) == "bar.txt"
    doAssert extractFilename("foo/", ignoreTrailingSep = true) == "foo"
when doslikeFileSystem:
    doAssert extractFilename(r"foo\bar") == "bar"
    doAssert extractFilename(r"foo\bar.txt") == "bar.txt"
    doAssert extractFilename(r"foo\") == ""
    doAssert extractFilename(r"foo\bar.txt", ignoreTrailingSep = true) == "bar.txt"
    doAssert extractFilename(r"foo\", ignoreTrailingSep = true) == "foo"
