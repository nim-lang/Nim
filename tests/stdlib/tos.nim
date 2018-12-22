discard """
  output: '''true
true
true
true
true
true
true
true
true
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
false
false
false
false
false
false
false
false
false
true
true
Raises
Raises
true
true
true
true
true
true

'''
"""
# test os path creation, iteration, and deletion

import os, strutils

block fileOperations:
  let files = @["these.txt", "are.x", "testing.r", "files.q"]
  let dirs = @["some", "created", "test", "dirs"]

  let dname = "__really_obscure_dir_name"

  createDir(dname)
  echo dirExists(dname)

  # Test creating files and dirs
  for dir in dirs:
    createDir(dname/dir)
    echo dirExists(dname/dir)

  for file in files:
    let fh = open(dname/file, fmReadWrite)
    fh.close()
    echo fileExists(dname/file)

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
    echo dirExists(dname/dir)

  for file in files:
    removeFile(dname/file)
    echo fileExists(dname/file)

  removeDir(dname)
  echo dirExists(dname)

  # createDir should create recursive directories
  createDir(dirs[0] / dirs[1])
  echo dirExists(dirs[0] / dirs[1]) # true
  removeDir(dirs[0])

  # createDir should properly handle trailing separator
  createDir(dname / "")
  echo dirExists(dname) # true
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

  echo dirExists("../dest/a/b")
  echo fileExists("../dest/a/b/file.txt")

  echo fileExists("../dest/a/b/c/fileC.txt")
  removeDir("../dest")

  # test copyDir:
  # if separator at the end of a path
  createDir("a/b")
  open("a/file.txt", fmWrite).close

  copyDir("a/", "../dest/a/")
  removeDir("a")

  echo dirExists("../dest/a/b")
  echo fileExists("../dest/a/file.txt")
  removeDir("../dest")

import times
block modificationTime:
  # Test get/set modification times
  # Should support at least microsecond resolution
  let tm = fromUnix(0) + 100.microseconds
  writeFile("a", "")
  setLastModificationTime("a", tm)

  when defined(macosx):
    echo "true"
  else:
    echo getLastModificationTime("a") == tm
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
  doAssert splitFile("/") == ("/", "", "")
  doAssert splitFile("./abc") == (".", "abc", "")
  doAssert splitFile(".txt") == ("", ".txt", "")
  doAssert splitFile("abc/.txt") == ("abc", ".txt", "")
  doAssert splitFile("abc") == ("", "abc", "")
  doAssert splitFile("abc.txt") == ("", "abc", ".txt")
  doAssert splitFile("/abc.txt") == ("/", "abc", ".txt")
  doAssert splitFile("/foo/abc.txt") == ("/foo", "abc", ".txt")
  doAssert splitFile("/foo/abc.txt.gz") == ("/foo", "abc.txt", ".gz")
  doAssert splitFile(".") == ("", ".", "")
  doAssert splitFile("abc/.") == ("abc", ".", "")
  doAssert splitFile("..") == ("", "..", "")
  doAssert splitFile("a/..") == ("a", "..", "")
