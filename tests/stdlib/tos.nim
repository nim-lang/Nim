discard """
  output: '''
All:
__really_obscure_dir_name/are.x
__really_obscure_dir_name/created
__really_obscure_dir_name/dirs
__really_obscure_dir_name/files.q
__really_obscure_dir_name/some
__really_obscure_dir_name/test
__really_obscure_dir_name/testing.r
__really_obscure_dir_name/these.txt
Files:
__really_obscure_dir_name/are.x
__really_obscure_dir_name/files.q
__really_obscure_dir_name/testing.r
__really_obscure_dir_name/these.txt
Dirs:
__really_obscure_dir_name/created
__really_obscure_dir_name/dirs
__really_obscure_dir_name/some
__really_obscure_dir_name/test
Raises
Raises
'''
"""
# test os path creation, iteration, and deletion

import os, strutils, pathnorm
import "$nim/compiler/unittest_light"

template runTestCases*(msg: string, examples, body: untyped): bool =
  ##[
  Runs body on each example (input, expected).
  Takes care of calling unixToNativePath.
  Returns true on success.
  ]##
  block:
    var numErrors = 0
    for i, a in examples:
      let it {.inject.} = unixToNativePath a[0]
      let expected = unixToNativePath a[1]
      let actual = body
      if actual != expected:
        if msg != "":
          echo (message: msg, index: i, example: a, inputNative: it, expectedNative: expected, actual: actual)
        numErrors.inc
    # the caller can see all the errors for all test cases when working on a proc
    numErrors == 0

block fileOperations:
  let files = @["these.txt", "are.x", "testing.r", "files.q"]
  let dirs = @["some", "created", "test", "dirs"]

  let dname = "__really_obscure_dir_name"

  createDir(dname)
  doAssert dirExists(dname)

  # Test creating files and dirs
  for dir in dirs:
    createDir(dname/dir)
    doAssert dirExists(dname/dir)

  for file in files:
    let fh = open(dname/file, fmReadWrite)
    fh.close()
    doAssert fileExists(dname/file)

  echo "All:"

  template norm(x): untyped =
    (when defined(windows): x.replace('\\', '/') else: x)

  for path in walkPattern(dname/"*"):
    echo path.norm

  echo "Files:"

  for path in walkFiles(dname/"*"):
    echo path.norm

  echo "Dirs:"

  for path in walkDirs(dname/"*"):
    echo path.norm

  # Test removal of files dirs
  for dir in dirs:
    removeDir(dname/dir)
    doAssert: not dirExists(dname/dir)

  for file in files:
    removeFile(dname/file)
    doAssert: not fileExists(dname/file)

  removeDir(dname)
  doAssert: not dirExists(dname)

  # createDir should create recursive directories
  createDir(dirs[0] / dirs[1])
  doAssert dirExists(dirs[0] / dirs[1]) # true
  removeDir(dirs[0])

  # createDir should properly handle trailing separator
  createDir(dname / "")
  doAssert dirExists(dname) # true
  removeDir(dname)

  # createDir should raise IOError if the path exists
  # and is not a directory
  open(dname, fmWrite).close
  try:
    createDir(dname)
  except IOError:
    echo "Raises"
  removeFile(dname)

  # removeFile should not remove directory
  createDir(dname)
  try:
    removeFile(dname)
  except OSError:
    echo "Raises"
  removeDir(dname)

  # test copyDir:
  createDir("a/b")
  open("a/b/file.txt", fmWrite).close
  createDir("a/b/c")
  open("a/b/c/fileC.txt", fmWrite).close

  copyDir("a", "../dest/a")
  removeDir("a")

  doAssert dirExists("../dest/a/b")
  doAssert fileExists("../dest/a/b/file.txt")

  doAssert fileExists("../dest/a/b/c/fileC.txt")
  removeDir("../dest")

  # test copyDir:
  # if separator at the end of a path
  createDir("a/b")
  open("a/file.txt", fmWrite).close

  copyDir("a/", "../dest/a/")
  removeDir("a")

  doAssert dirExists("../dest/a/b")
  doAssert fileExists("../dest/a/file.txt")
  removeDir("../dest")

import times
block modificationTime:
  # Test get/set modification times
  # Should support at least microsecond resolution
  let tm = fromUnix(0) + 100.microseconds
  writeFile("a", "")
  setLastModificationTime("a", tm)

  when defined(macosx):
    doAssert true
  else:
    doAssert getLastModificationTime("a") == tm
  removeFile("a")

block walkDirRec:
  createDir("walkdir_test/a/b")
  open("walkdir_test/a/b/file_1", fmWrite).close()
  open("walkdir_test/a/file_2", fmWrite).close()

  for p in walkDirRec("walkdir_test"):
    doAssert p.fileExists
    doAssert p.startsWith("walkdir_test")

  var s: seq[string]
  for p in walkDirRec("walkdir_test", {pcFile}, {pcDir}, relative=true):
    s.add(p)

  doAssert s.len == 2
  doAssert "a" / "b" / "file_1" in s
  doAssert "a" / "file_2" in s

  removeDir("walkdir_test")

when not defined(windows):
  block walkDirRelative:
    createDir("walkdir_test")
    createSymlink(".", "walkdir_test/c")
    for k, p in walkDir("walkdir_test", true):
      doAssert k == pcLinkToDir
    removeDir("walkdir_test")

block normalizedPath:
  doAssert normalizedPath("") == ""
  block relative:
    doAssert normalizedPath(".") == "."
    doAssert normalizedPath("foo/..") == "."
    doAssert normalizedPath("foo//../bar/.") == "bar"
    doAssert normalizedPath("..") == ".."
    doAssert normalizedPath("../") == ".."
    doAssert normalizedPath("../..") == unixToNativePath"../.."
    doAssert normalizedPath("../a/..") == ".."
    doAssert normalizedPath("../a/../") == ".."
    doAssert normalizedPath("./") == "."

  block absolute:
    doAssert normalizedPath("/") == unixToNativePath"/"
    doAssert normalizedPath("/.") == unixToNativePath"/"
    doAssert normalizedPath("/..") == unixToNativePath"/.."
    doAssert normalizedPath("/../") == unixToNativePath"/.."
    doAssert normalizedPath("/../..") == unixToNativePath"/../.."
    doAssert normalizedPath("/../../") == unixToNativePath"/../.."
    doAssert normalizedPath("/../../../") == unixToNativePath"/../../.."
    doAssert normalizedPath("/a/b/../../foo") == unixToNativePath"/foo"
    doAssert normalizedPath("/a/b/../../../foo") == unixToNativePath"/../foo"
    doAssert normalizedPath("/./") == unixToNativePath"/"
    doAssert normalizedPath("//") == unixToNativePath"/"
    doAssert normalizedPath("///") == unixToNativePath"/"
    doAssert normalizedPath("/a//b") == unixToNativePath"/a/b"
    doAssert normalizedPath("/a///b") == unixToNativePath"/a/b"
    doAssert normalizedPath("/a/b/c/..") == unixToNativePath"/a/b"
    doAssert normalizedPath("/a/b/c/../") == unixToNativePath"/a/b"

block isHidden:
  when defined(posix):
    doAssert ".foo.txt".isHidden
    doAssert "bar/.foo.ext".isHidden
    doAssert: not "bar".isHidden
    doAssert: not "foo/".isHidden
    # Corner cases: paths are not normalized when determining `isHidden`
    doAssert: not ".foo/.".isHidden
    doAssert: not ".foo/..".isHidden

block absolutePath:
  doAssertRaises(ValueError): discard absolutePath("a", "b")
  doAssert absolutePath("a") == getCurrentDir() / "a"
  doAssert absolutePath("a", "/b") == "/b" / "a"
  when defined(Posix):
    doAssert absolutePath("a", "/b/") == "/b" / "a"
    doAssert absolutePath("a", "/b/c") == "/b/c" / "a"
    doAssert absolutePath("/a", "b/") == "/a"

block splitFile:
  doAssert splitFile("") == ("", "", "")
  doAssert splitFile("abc/") == ("abc", "", "")
  doAssert splitFile("/") == ("/".unixToNativePath, "", "")
  doAssert splitFile("./abc") == (".", "abc", "")
  doAssert splitFile(".txt") == ("", ".txt", "")
  doAssert splitFile("abc/.txt") == ("abc", ".txt", "")
  doAssert splitFile("abc") == ("", "abc", "")
  doAssert splitFile("abc.txt") == ("", "abc", ".txt")
  doAssert splitFile("/abc.txt") == ("/".unixToNativePath, "abc", ".txt")
  doAssert splitFile("/foo/abc.txt") == ("/foo", "abc", ".txt")
  doAssert splitFile("/foo/abc.txt.gz") == ("/foo", "abc.txt", ".gz")
  doAssert splitFile(".") == ("", ".", "")
  doAssert splitFile("abc/.") == ("abc", ".", "")
  doAssert splitFile("..") == ("", "..", "")
  doAssert splitFile("a/..") == ("a", "..", "")

# execShellCmd is tested in tosproc

block isAbsolute:
  doAssert not isAbsolute("")
  doAssert not isAbsolute(".")
  doAssert not isAbsolute("..")
  doAssert not isAbsolute("abc")
  doAssert not isAbsolute(".foo")
  doAssert isAbsolute(unixToNativePath("/"))
  doAssert isAbsolute(unixToNativePath("/", "a"))
  doAssert isAbsolute(unixToNativePath("/a"))
  doAssert isAbsolute(unixToNativePath("/a", "a"))
  doAssert isAbsolute(unixToNativePath("/a/b"))
  doAssert isAbsolute(unixToNativePath("/a/b", "a"))

block ospaths:
  doAssert unixToNativePath("") == ""
  doAssert unixToNativePath(".") == $CurDir
  doAssert unixToNativePath("..") == $ParDir
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

block parentDir:
  let examples = [
    ("/usr/local/bin", "/usr/local"),
    ("foo/bar.nim", "foo"),
    ("foo//bar.nim", "foo"),
    ("foo//bar//", "foo"),
    ("foo///bar", "foo"),
    ("foo///bar/.", "foo"),
    ("./foo///bar", "./foo"),
    (".//foo///bar", ".//foo"),
    ("/.//foo///bar", "/.//foo"),
    ("foo/bar//a/./.", "foo/bar"),
    ("/a/bar", "/a"),
    ("/bar", "/"),

    # same as in shell, `cd ..` returns `.` when pwd = "foo"; "." is not same as empty
    # see https://github.com/nim-lang/Nim/pull/10018#issuecomment-447996816
    ("a/./.", "."),
    ("./bar", "."),
    (".//bar", "."),
    ("bar", "."),

    (".git", "."),
    (".git.bak1", "."),

    # with parentDirOfRootIsEmpty=false
    # ("/", "/"),
    # ("/.", "/"),
    # ("/..", "/"),
    # ("/./", "/"),
    # fix #8734 (bug 3)
    # ("/", "/"),

    # with parentDirOfRootIsEmpty=true
    ("/", ""),
    ("/.", ""),
    ("/..", ""),
    ("/./", ""),

    # return empty when no parent possible
    ("", ""),
    (".", ""),
    ("./", ""),
    ("..", ""),
    ("../", ""),
    ("../..", ""),

    # regression tests

    # fix #8734 (bug 2)
    ("a/b//", "a"),
    ("a/b/", "a"),


    # fix #8734 (bug 4)
    ("/a.txt", "/"),
  ]

  doAssert runTestCases("parentDir", examples, parentDir(it))

import sequtils

block tailDir:
  let examples = [
    ("/usr/local/bin", "usr/local/bin"),
    ("usr/local/bin", "local/bin"),

    # issue #8395; todo: fix
    # ("//usr//local//bin//", "usr//local//bin//"),
    # ("usr//local//bin//", "local/bin//"),
  ]

  doAssert runTestCases("tailDir", examples, tailDir(it))

block parentDirs:
  template test(iter: untyped, expected: seq[string]): untyped =
    let lhs = toSeq(iter)
    let rhs = expected.mapIt(it.unixToNativePath)
    assertEquals lhs, rhs

  # fromRoot=false, inclusive=true
  test parentDirs("a/b/c".unixToNativePath), @["a/b/c", "a/b", "a"]
  test parentDirs("/a/b/c".unixToNativePath), @["/a/b/c", "/a/b", "/a", "/"]
  test parentDirs("//a/b//c//".unixToNativePath), @["//a/b//c", "//a/b", "//a", "/"]
  test parentDirs("/".unixToNativePath), @["/"]
  test parentDirs("".unixToNativePath), @[""]

  # fromRoot=true
  test parentDirs("a/b/c".unixToNativePath, fromRoot=true), @["a", "a/b", "a/b/c"]
  test parentDirs("a//b//c/".unixToNativePath, fromRoot=true), @["a", "a//b", "a//b//c"]
  test parentDirs("/a/b".unixToNativePath, fromRoot=true), @["/", "/a", "/a/b"]

  # inclusive=false
  test parentDirs("/a/b".unixToNativePath, inclusive=false), @["/a", "/"]
  test parentDirs("/a//b//".unixToNativePath, inclusive=false), @["/a", "/"]
  test parentDirs("/a/b//".unixToNativePath, inclusive=false), @["/a", "/"]
  test parentDirs("".unixToNativePath, inclusive=false), seq[string](@[])

  # fromRoot=true, inclusive=false
  test parentDirs("/a/b/c/".unixToNativePath, fromRoot=true, inclusive=false), @["/", "/a", "/a/b"]

  # regression test
  # fix #8353
  test parentDirs("/a/b".unixToNativePath), @["/a/b", "/a", "/"]

block runTestCasesTest:
  const examples = [("foo", "foobar"), ("foo2", "foo2bar")]
  doAssert runTestCases("identity", examples, it & "bar")
  doAssert not runTestCases("intentional failure", examples, it & "baz")
