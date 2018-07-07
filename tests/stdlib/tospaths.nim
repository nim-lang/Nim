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

doAssert splitPathComponents("").len == 0
doAssert splitPathComponents("/").len == 0
doAssert splitPathComponents("foo") == @["foo"]
doAssert splitPathComponents("/foo") == @["foo"]
doAssert splitPathComponents("foo/bar") == @["foo", "bar"]
doAssert splitPathComponents("/foo/bar") == @["foo", "bar"]
doAssert splitPathComponents("foo/bar/") == @["foo", "bar"]
doAssert splitPathComponents("/foo/bar/") == @["foo", "bar"]
