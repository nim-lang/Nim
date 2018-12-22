discard """
  output: ""
"""
# test the ospaths module

import os, pathnorm

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

template canon(x): untyped = normalizePath(x, '/')
doAssert canon"/foo/../bar" == "/bar"
doAssert canon"foo/../bar" == "bar"

doAssert canon"/f/../bar///" == "/bar"
doAssert canon"f/..////bar" == "bar"

doAssert canon"../bar" == "../bar"
doAssert canon"/../bar" == "/../bar"

doAssert canon("foo/../../bar/") == "../bar"
doAssert canon("./bla/blob/") == "bla/blob"
doAssert canon(".hiddenFile") == ".hiddenFile"
doAssert canon("./bla/../../blob/./zoo.nim") == "../blob/zoo.nim"

doAssert canon("C:/file/to/this/long") == "C:/file/to/this/long"
doAssert canon("") == ""
doAssert canon("foobar") == "foobar"
doAssert canon("f/////////") == "f"

doAssert relativePath("/foo/bar//baz.nim", "/foo", '/') == "bar/baz.nim"
doAssert normalizePath("./foo//bar/../baz", '/') == "foo/baz"

doAssert relativePath("/Users/me/bar/z.nim", "/Users/other/bad", '/') == "../../me/bar/z.nim"

doAssert relativePath("/Users/me/bar/z.nim", "/Users/other", '/') == "../me/bar/z.nim"
doAssert relativePath("/Users///me/bar//z.nim", "//Users/", '/') == "me/bar/z.nim"
doAssert relativePath("/Users/me/bar/z.nim", "/Users/me", '/') == "bar/z.nim"
doAssert relativePath("", "/users/moo", '/') == ""
doAssert relativePath("foo", "", '/') == "foo"

doAssert joinPath("usr", "") == unixToNativePath"usr/"
doAssert joinPath("", "lib") == "lib"
doAssert joinPath("", "/lib") == unixToNativePath"/lib"
doAssert joinPath("usr/", "/lib") == unixToNativePath"usr/lib"
