discard """
  file: "tospaths.nim"
  output: ""
"""

import ospaths

block isAbsoluteTest:
  doAssert: not "".isAbsolute
  doAssert: not ".".isAbsolute
  doAssert: not "foo".isAbsolute
  when defined(posix):
    doAssert "/".isAbsolute
    doAssert: not "a/".isAbsolute
  when defined(Windows):
    doAssert "C:\\foo".isAbsolute

block unixToNativePathTest:
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

block quoteShellWindowsTest:
  assert quoteShellWindows("aaa") == "aaa"
  assert quoteShellWindows("aaa\"") == "aaa\\\""
  assert quoteShellWindows("") == "\"\""

block quoteShellPosixTest:
  assert quoteShellPosix("aaa") == "aaa"
  assert quoteShellPosix("aaa a") == "'aaa a'"
  assert quoteShellPosix("") == "''"
  assert quoteShellPosix("a'a") == "'a'\"'\"'a'"

block quoteShellTest:
  when defined(posix):
    assert quoteShell("") == "''"

block joinPathTest:
  when defined(posix):
    doAssert joinPath("usr", "lib") == "usr/lib"
    doAssert joinPath("usr", "") == "usr/"
    doAssert joinPath("", "lib") == "lib"
    doAssert joinPath("usr/", "/lib") == "usr/lib"
    doAssert joinPath("usr/", "/lib", absOverrides = true) == "/lib"
    doAssert joinPath("usr///", "//lib") == "usr/lib" ## `//` gets compressed
    doAssert joinPath("//", "lib") == "/lib" ## ditto
  when defined(Windows):
    ## Note: network paths are removed in this example:
    doAssert joinPath(r"E:\foo", r"D:\bar") == r"E:\foo\bar"
    doAssert joinPath("", r"D:\bar") == r"D:\bar"
    doAssert joinPath(r"/foo", r"\bar") == r"/foo\bar"
    doAssert joinPath(r"\foo", r"\bar", absOverrides = true) == r"\bar"

block joinPathVarargsTest:
  when defined(posix):
    doAssert joinPath("foo", "bar") == "foo/bar"
    doAssert joinPath("foo//", "bar/", absOverrides = true) == "foo/bar/"
    doAssert joinPath("foo//", "bar/") == "foo/bar/"
