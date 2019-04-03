#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains basic operating system facilities like
## retrieving environment variables, reading command line arguments,
## working with directories, running shell commands, etc.
##
## .. code-block::
##   import os
##
##   let myFile = "/path/to/my/file.nim"
##
##   let splittedPath = splitPath(myFile)
##   assert splittedPath.head == "/path/to/my"
##   assert splittedPath.tail == "file.nim"
##
##   assert parentDir(myFile) == "/path/to/my"
##
##   let splittedFile = splitFile(myFile)
##   assert splittedFile.dir == "/path/to/my"
##   assert splittedFile.name == "file"
##   assert splittedFile.ext == ".nim"
##
##   assert myFile.changeFileExt("c") == "/path/to/my/file.c"
##
##
## **See also:**
## * `osproc module <osproc.html>`_ for process communication beyond
##   `execShellCmd proc <#execShellCmd,string>`_
## * `parseopt module <parseopt.html>`_ for command-line parser beyond
##   `parseCmdLine proc <#parseCmdLine,string>`_
## * `uri module <uri.html>`_
## * `distros module <distros.html>`_
## * `dynlib module <dynlib.html>`_
## * `streams module <streams.html>`_


{.deadCodeElim: on.}  # dce option deprecated

{.push debugger: off.}

include "system/inclrtl"

import
  strutils, pathnorm

const weirdTarget = defined(nimscript) or defined(js)

when weirdTarget:
  discard
elif defined(windows):
  import winlean, times
elif defined(posix):
  import posix, times

  proc toTime(ts: Timespec): times.Time {.inline.} =
    result = initTime(ts.tv_sec.int64, ts.tv_nsec.int)
else:
  {.error: "OS module not ported to your operating system!".}

when weirdTarget and defined(nimErrorProcCanHaveBody):
  {.pragma: noNimScript, error: "this proc is not available on the NimScript target".}
else:
  {.pragma: noNimScript.}

type
  ReadEnvEffect* = object of ReadIOEffect   ## Effect that denotes a read
                                            ## from an environment variable.
  WriteEnvEffect* = object of WriteIOEffect ## Effect that denotes a write
                                            ## to an environment variable.

  ReadDirEffect* = object of ReadIOEffect   ## Effect that denotes a read
                                            ## operation from the directory
                                            ## structure.
  WriteDirEffect* = object of WriteIOEffect ## Effect that denotes a write
                                            ## operation to
                                            ## the directory structure.

  OSErrorCode* = distinct int32 ## Specifies an OS Error Code.

include "includes/osseps"

proc normalizePathEnd(path: var string, trailingSep = false) =
  ## Ensures ``path`` has exactly 0 or 1 trailing `DirSep`, depending on
  ## ``trailingSep``, and taking care of edge cases: it preservers whether
  ## a path is absolute or relative, and makes sure trailing sep is `DirSep`,
  ## not `AltSep`.
  if path.len == 0: return
  var i = path.len
  while i >= 1 and path[i-1] in {DirSep, AltSep}: dec(i)
  if trailingSep:
    # foo// => foo
    path.setLen(i)
    # foo => foo/
    path.add DirSep
  elif i > 0:
    # foo// => foo
    path.setLen(i)
  else:
    # // => / (empty case was already taken care of)
    path = $DirSep

proc normalizePathEnd(path: string, trailingSep = false): string =
  result = path
  result.normalizePathEnd(trailingSep)

proc joinPath*(head, tail: string): string {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Joins two directory names to one.
  ##
  ## If `head` is the empty string, `tail` is returned. If `tail` is the empty
  ## string, `head` is returned with a trailing path separator. If `tail` starts
  ## with a path separator it will be removed when concatenated to `head`.
  ## Path separators will be normalized.
  ##
  ## See also:
  ## * `joinPath(varargs) proc <#joinPath,varargs[string]>`_
  ## * `/ proc <#/,string,string>`_
  ## * `splitPath proc <#splitPath,string>`_
  ## * `uri.combine proc <uri.html#combine,Uri,Uri>`_
  ## * `uri./ proc <uri.html#/,Uri,string>`_
  runnableExamples:
    when defined(posix):
      assert joinPath("usr", "lib") == "usr/lib"
      assert joinPath("usr", "") == "usr/"
      assert joinPath("", "lib") == "lib"
      assert joinPath("", "/lib") == "/lib"
      assert joinPath("usr/", "/lib") == "usr/lib"
      assert joinPath("usr/lib", "../bin") == "usr/bin"

  result = newStringOfCap(head.len + tail.len)
  var state = 0
  addNormalizePath(head, result, state, DirSep)
  if tail.len == 0:
    result.add DirSep
  else:
    addNormalizePath(tail, result, state, DirSep)
  when false:
    if len(head) == 0:
      result = tail
    elif head[len(head)-1] in {DirSep, AltSep}:
      if tail.len > 0 and tail[0] in {DirSep, AltSep}:
        result = head & substr(tail, 1)
      else:
        result = head & tail
    else:
      if tail.len > 0 and tail[0] in {DirSep, AltSep}:
        result = head & tail
      else:
        result = head & DirSep & tail

proc joinPath*(parts: varargs[string]): string {.noSideEffect,
  rtl, extern: "nos$1OpenArray".} =
  ## The same as `joinPath(head, tail) proc <#joinPath,string,string>`_,
  ## but works with any number of directory parts.
  ##
  ## You need to pass at least one element or the proc
  ## will assert in debug builds and crash on release builds.
  ##
  ## See also:
  ## * `joinPath(head, tail) proc <#joinPath,string,string>`_
  ## * `/ proc <#/,string,string>`_
  ## * `/../ proc <#/../,string,string>`_
  ## * `splitPath proc <#splitPath,string>`_
  runnableExamples:
    when defined(posix):
      assert joinPath("a") == "a"
      assert joinPath("a", "b", "c") == "a/b/c"
      assert joinPath("usr/lib", "../../var", "log") == "var/log"

  var estimatedLen = 0
  for p in parts: estimatedLen += p.len
  result = newStringOfCap(estimatedLen)
  var state = 0
  for i in 0..high(parts):
    addNormalizePath(parts[i], result, state, DirSep)

proc `/`*(head, tail: string): string {.noSideEffect.} =
  ## The same as `joinPath(head, tail) proc <#joinPath,string,string>`_.
  ##
  ## See also:
  ## * `/../ proc <#/../,string,string>`_
  ## * `joinPath(head, tail) proc <#joinPath,string,string>`_
  ## * `joinPath(varargs) proc <#joinPath,varargs[string]>`_
  ## * `splitPath proc <#splitPath,string>`_
  ## * `uri.combine proc <uri.html#combine,Uri,Uri>`_
  ## * `uri./ proc <uri.html#/,Uri,string>`_
  runnableExamples:
    when defined(posix):
      assert "usr" / "" == "usr/"
      assert "" / "lib" == "lib"
      assert "" / "/lib" == "/lib"
      assert "usr/" / "/lib" == "usr/lib"
      assert "usr" / "lib" / "../bin" == "usr/bin"

  return joinPath(head, tail)

proc splitPath*(path: string): tuple[head, tail: string] {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Splits a directory into `(head, tail)` tuple, so that
  ## ``head / tail == path`` (except for edge cases like "/usr").
  ##
  ## See also:
  ## * `joinPath(head, tail) proc <#joinPath,string,string>`_
  ## * `joinPath(varargs) proc <#joinPath,varargs[string]>`_
  ## * `/ proc <#/,string,string>`_
  ## * `/../ proc <#/../,string,string>`_
  ## * `relativePath proc <#relativePath,string,string>`_
  runnableExamples:
    assert splitPath("usr/local/bin") == ("usr/local", "bin")
    assert splitPath("usr/local/bin/") == ("usr/local/bin", "")
    assert splitPath("bin") == ("", "bin")
    assert splitPath("/bin") == ("", "bin")
    assert splitPath("") == ("", "")

  var sepPos = -1
  for i in countdown(len(path)-1, 0):
    if path[i] in {DirSep, AltSep}:
      sepPos = i
      break
  if sepPos >= 0:
    result.head = substr(path, 0, sepPos-1)
    result.tail = substr(path, sepPos+1)
  else:
    result.head = ""
    result.tail = path

when FileSystemCaseSensitive:
  template `!=?`(a, b: char): bool = toLowerAscii(a) != toLowerAscii(b)
else:
  template `!=?`(a, b: char): bool = a != b

proc relativePath*(path, base: string; sep = DirSep): string {.
  noSideEffect, rtl, extern: "nos$1", raises: [].} =
  ## Converts `path` to a path relative to `base`.
  ##
  ## The `sep` (default: `DirSep <#DirSep>`_) is used for the path normalizations,
  ## this can be useful to ensure the relative path only contains `'/'`
  ## so that it can be used for URL constructions.
  ##
  ## See also:
  ## * `splitPath proc <#splitPath,string>`_
  ## * `parentDir proc <#parentDir,string>`_
  ## * `tailDir proc <#tailDir,string>`_
  runnableExamples:
    assert relativePath("/Users/me/bar/z.nim", "/Users/other/bad", '/') == "../../me/bar/z.nim"
    assert relativePath("/Users/me/bar/z.nim", "/Users/other", '/') == "../me/bar/z.nim"
    assert relativePath("/Users///me/bar//z.nim", "//Users/", '/') == "me/bar/z.nim"
    assert relativePath("/Users/me/bar/z.nim", "/Users/me", '/') == "bar/z.nim"
    assert relativePath("", "/users/moo", '/') == ""

  # Todo: If on Windows, path and base do not agree on the drive letter,
  # return `path` as is.
  if path.len == 0: return ""
  var f, b: PathIter
  var ff = (0, -1)
  var bb = (0, -1) # (int, int)
  result = newStringOfCap(path.len)
  # skip the common prefix:
  while f.hasNext(path) and b.hasNext(base):
    ff = next(f, path)
    bb = next(b, base)
    let diff = ff[1] - ff[0]
    if diff != bb[1] - bb[0]: break
    var same = true
    for i in 0..diff:
      if path[i + ff[0]] !=? base[i + bb[0]]:
        same = false
        break
    if not same: break
    ff = (0, -1)
    bb = (0, -1)
  #  for i in 0..diff:
  #    result.add base[i + bb[0]]

  # /foo/bar/xxx/ -- base
  # /foo/bar/baz  -- path path
  #   ../baz
  # every directory that is in 'base', needs to add '..'
  while true:
    if bb[1] >= bb[0]:
      if result.len > 0 and result[^1] != sep:
        result.add sep
      result.add ".."
    if not b.hasNext(base): break
    bb = b.next(base)

  # add the rest of 'path':
  while true:
    if ff[1] >= ff[0]:
      if result.len > 0 and result[^1] != sep:
        result.add sep
      for i in 0..ff[1] - ff[0]:
        result.add path[i + ff[0]]
    if not f.hasNext(path): break
    ff = f.next(path)

proc parentDirPos(path: string): int =
  var q = 1
  if len(path) >= 1 and path[len(path)-1] in {DirSep, AltSep}: q = 2
  for i in countdown(len(path)-q, 0):
    if path[i] in {DirSep, AltSep}: return i
  result = -1

proc parentDir*(path: string): string {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Returns the parent directory of `path`.
  ##
  ## This is the same as ``splitPath(path).head`` when ``path`` doesn't end
  ## in a dir separator.
  ## The remainder can be obtained with `lastPathPart(path) proc
  ## <#lastPathPart,string>`_.
  ##
  ## See also:
  ## * `relativePath proc <#relativePath,string,string>`_
  ## * `splitPath proc <#splitPath,string>`_
  ## * `tailDir proc <#tailDir,string>`_
  ## * `parentDirs iterator <#parentDirs.i,string>`_
  runnableExamples:
    assert parentDir("") == ""
    when defined(posix):
      assert parentDir("/usr/local/bin") == "/usr/local"
      assert parentDir("foo/bar/") == "foo"
      assert parentDir("./foo") == "."
      assert parentDir("/foo") == ""

  let sepPos = parentDirPos(path)
  if sepPos >= 0:
    result = substr(path, 0, sepPos-1)
  else:
    result = ""

proc tailDir*(path: string): string {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Returns the tail part of `path`.
  ##
  ## See also:
  ## * `relativePath proc <#relativePath,string,string>`_
  ## * `splitPath proc <#splitPath,string>`_
  ## * `parentDir proc <#parentDir,string>`_
  runnableExamples:
    assert tailDir("/bin") == "bin"
    assert tailDir("bin") == ""
    assert tailDir("/usr/local/bin") == "usr/local/bin"
    assert tailDir("usr/local/bin") == "local/bin"

  var q = 1
  if len(path) >= 1 and path[len(path)-1] in {DirSep, AltSep}: q = 2
  for i in 0..len(path)-q:
    if path[i] in {DirSep, AltSep}:
      return substr(path, i+1)
  result = ""

proc isRootDir*(path: string): bool {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Checks whether a given `path` is a root directory.
  runnableExamples:
    assert isRootDir("")
    assert isRootDir(".")
    assert isRootDir("/")
    assert isRootDir("a")
    assert not isRootDir("/a")
    assert not isRootDir("a/b/c")

  result = parentDirPos(path) < 0

iterator parentDirs*(path: string, fromRoot=false, inclusive=true): string =
  ## Walks over all parent directories of a given `path`.
  ##
  ## If `fromRoot` is true (default: false), the traversal will start from
  ## the file system root diretory.
  ## If `inclusive` is true (default), the original argument will be included
  ## in the traversal.
  ##
  ## Relative paths won't be expanded by this iterator. Instead, it will traverse
  ## only the directories appearing in the relative path.
  ##
  ## See also:
  ## * `parentDir proc <#parentDir,string>`_
  ##
  ## **Examples:**
  ##
  ## .. code-block::
  ##   let g = "a/b/c"
  ##
  ##   for p in g.parentDirs:
  ##     echo p
  ##   # a/b/c
  ##   # a/b
  ##   # a
  ##
  ##   for p in g.parentDirs(fromRoot=true):
  ##     echo p
  ##   # a/
  ##   # a/b/
  ##   # a/b/c
  ##
  ##   for p in g.parentDirs(inclusive=false):
  ##     echo p
  ##   # a/b
  ##   # a

  if not fromRoot:
    var current = path
    if inclusive: yield path
    while true:
      if current.isRootDir: break
      current = current.parentDir
      yield current
  else:
    for i in countup(0, path.len - 2): # ignore the last /
      # deal with non-normalized paths such as /foo//bar//baz
      if path[i] in {DirSep, AltSep} and
          (i == 0 or path[i-1] notin {DirSep, AltSep}):
        yield path.substr(0, i)

    if inclusive: yield path

proc `/../`*(head, tail: string): string {.noSideEffect.} =
  ## The same as ``parentDir(head) / tail``, unless there is no parent
  ## directory. Then ``head / tail`` is performed instead.
  ##
  ## See also:
  ## * `/ proc <#/,string,string>`_
  ## * `parentDir proc <#parentDir,string>`_
  runnableExamples:
    when defined(posix):
      assert "a/b/c" /../ "d/e" == "a/b/d/e"
      assert "a" /../ "d/e" == "a/d/e"

  let sepPos = parentDirPos(head)
  if sepPos >= 0:
    result = substr(head, 0, sepPos-1) / tail
  else:
    result = head / tail

proc normExt(ext: string): string =
  if ext == "" or ext[0] == ExtSep: result = ext # no copy needed here
  else: result = ExtSep & ext

proc searchExtPos*(path: string): int =
  ## Returns index of the `'.'` char in `path` if it signifies the beginning
  ## of extension. Returns -1 otherwise.
  ##
  ## See also:
  ## * `splitFile proc <#splitFile,string>`_
  ## * `extractFilename proc <#extractFilename,string>`_
  ## * `lastPathPart proc <#lastPathPart,string>`_
  ## * `changeFileExt proc <#changeFileExt,string,string>`_
  ## * `addFileExt proc <#addFileExt,string,string>`_
  runnableExamples:
    assert searchExtPos("a/b/c") == -1
    assert searchExtPos("c.nim") == 1
    assert searchExtPos("a/b/c.nim") == 5
    assert searchExtPos("a.b.c.nim") == 5

  # BUGFIX: do not search until 0! .DS_Store is no file extension!
  result = -1
  for i in countdown(len(path)-1, 1):
    if path[i] == ExtSep:
      result = i
      break
    elif path[i] in {DirSep, AltSep}:
      break # do not skip over path

proc splitFile*(path: string): tuple[dir, name, ext: string] {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Splits a filename into `(dir, name, extension)` tuple.
  ##
  ## `dir` does not end in `DirSep <#DirSep>`_.
  ## `extension` includes the leading dot.
  ##
  ## If `path` has no extension, `ext` is the empty string.
  ## If `path` has no directory component, `dir` is the empty string.
  ## If `path` has no filename component, `name` and `ext` are empty strings.
  ##
  ## See also:
  ## * `searchExtPos proc <#searchExtPos,string>`_
  ## * `extractFilename proc <#extractFilename,string>`_
  ## * `lastPathPart proc <#lastPathPart,string>`_
  ## * `changeFileExt proc <#changeFileExt,string,string>`_
  ## * `addFileExt proc <#addFileExt,string,string>`_
  runnableExamples:
    var (dir, name, ext) = splitFile("usr/local/nimc.html")
    assert dir == "usr/local"
    assert name == "nimc"
    assert ext == ".html"
    (dir, name, ext) = splitFile("/usr/local/os")
    assert dir == "/usr/local"
    assert name == "os"
    assert ext == ""
    (dir, name, ext) = splitFile("/usr/local/")
    assert dir == "/usr/local"
    assert name == ""
    assert ext == ""

  if path.len == 0:
    result = ("", "", "")
  elif path[^1] in {DirSep, AltSep}:
    if path.len == 1:
      # issue #8255
      result = ($path[0], "", "")
    else:
      result = (path[0 ..< ^1], "", "")
  else:
    var sepPos = -1
    var dotPos = path.len
    for i in countdown(len(path)-1, 0):
      if path[i] == ExtSep:
        if dotPos == path.len and i > 0 and
            path[i-1] notin {DirSep, AltSep, ExtSep}: dotPos = i
      elif path[i] in {DirSep, AltSep}:
        sepPos = i
        break
    if sepPos-1 >= 0:
      result.dir = substr(path, 0, sepPos-1)
    elif path[0] in {DirSep, AltSep}:
      # issue #8255
      result.dir = $path[0]

    result.name = substr(path, sepPos+1, dotPos-1)
    result.ext = substr(path, dotPos)

proc extractFilename*(path: string): string {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Extracts the filename of a given `path`.
  ##
  ## This is the same as ``name & ext`` from `splitFile(path) proc
  ## <#splitFile,string>`_.
  ##
  ## See also:
  ## * `searchExtPos proc <#searchExtPos,string>`_
  ## * `splitFile proc <#splitFile,string>`_
  ## * `lastPathPart proc <#lastPathPart,string>`_
  ## * `changeFileExt proc <#changeFileExt,string,string>`_
  ## * `addFileExt proc <#addFileExt,string,string>`_
  runnableExamples:
    assert extractFilename("foo/bar/") == ""
    assert extractFilename("foo/bar") == "bar"
    assert extractFilename("foo/bar.baz") == "bar.baz"

  if path.len == 0 or path[path.len-1] in {DirSep, AltSep}:
    result = ""
  else:
    result = splitPath(path).tail

proc lastPathPart*(path: string): string {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Like `extractFilename proc <#extractFilename,string>`_, but ignores
  ## trailing dir separator; aka: `baseName`:idx: in some other languages.
  ##
  ## See also:
  ## * `searchExtPos proc <#searchExtPos,string>`_
  ## * `splitFile proc <#splitFile,string>`_
  ## * `extractFilename proc <#extractFilename,string>`_
  ## * `changeFileExt proc <#changeFileExt,string,string>`_
  ## * `addFileExt proc <#addFileExt,string,string>`_
  runnableExamples:
    assert lastPathPart("foo/bar/") == "bar"
    assert lastPathPart("foo/bar") == "bar"

  let path = path.normalizePathEnd(trailingSep = false)
  result = extractFilename(path)

proc changeFileExt*(filename, ext: string): string {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Changes the file extension to `ext`.
  ##
  ## If the `filename` has no extension, `ext` will be added.
  ## If `ext` == "" then any extension is removed.
  ##
  ## `Ext` should be given without the leading `'.'`, because some
  ## filesystems may use a different character. (Although I know
  ## of none such beast.)
  ##
  ## See also:
  ## * `searchExtPos proc <#searchExtPos,string>`_
  ## * `splitFile proc <#splitFile,string>`_
  ## * `extractFilename proc <#extractFilename,string>`_
  ## * `lastPathPart proc <#lastPathPart,string>`_
  ## * `addFileExt proc <#addFileExt,string,string>`_
  runnableExamples:
    assert changeFileExt("foo.bar", "baz") == "foo.baz"
    assert changeFileExt("foo.bar", "") == "foo"
    assert changeFileExt("foo", "baz") == "foo.baz"

  var extPos = searchExtPos(filename)
  if extPos < 0: result = filename & normExt(ext)
  else: result = substr(filename, 0, extPos-1) & normExt(ext)

proc addFileExt*(filename, ext: string): string {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Adds the file extension `ext` to `filename`, unless
  ## `filename` already has an extension.
  ##
  ## `Ext` should be given without the leading `'.'`, because some
  ## filesystems may use a different character.
  ## (Although I know of none such beast.)
  ##
  ## See also:
  ## * `searchExtPos proc <#searchExtPos,string>`_
  ## * `splitFile proc <#splitFile,string>`_
  ## * `extractFilename proc <#extractFilename,string>`_
  ## * `lastPathPart proc <#lastPathPart,string>`_
  ## * `changeFileExt proc <#changeFileExt,string,string>`_
  runnableExamples:
    assert addFileExt("foo.bar", "baz") == "foo.bar"
    assert addFileExt("foo.bar", "") == "foo.bar"
    assert addFileExt("foo", "baz") == "foo.baz"

  var extPos = searchExtPos(filename)
  if extPos < 0: result = filename & normExt(ext)
  else: result = filename

proc cmpPaths*(pathA, pathB: string): int {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Compares two paths.
  ##
  ## On a case-sensitive filesystem this is done
  ## case-sensitively otherwise case-insensitively. Returns:
  ##
  ## | 0 iff pathA == pathB
  ## | < 0 iff pathA < pathB
  ## | > 0 iff pathA > pathB
  runnableExamples:
    when defined(macosx):
      assert cmpPaths("foo", "Foo") == 0
    elif defined(posix):
      assert cmpPaths("foo", "Foo") > 0

  let a = normalizePath(pathA)
  let b = normalizePath(pathB)
  if FileSystemCaseSensitive:
    result = cmp(a, b)
  else:
    when defined(nimscript):
      result = cmpic(a, b)
    elif defined(nimdoc): discard
    else:
      result = cmpIgnoreCase(a, b)

proc isAbsolute*(path: string): bool {.rtl, noSideEffect, extern: "nos$1".} =
  ## Checks whether a given `path` is absolute.
  ##
  ## On Windows, network paths are considered absolute too.
  runnableExamples:
    assert not "".isAbsolute
    assert not ".".isAbsolute
    when defined(posix):
      assert "/".isAbsolute
      assert not "a/".isAbsolute
      assert "/a/".isAbsolute

  if len(path) == 0: return false

  when doslikeFileSystem:
    var len = len(path)
    result = (path[0] in {'/', '\\'}) or
              (len > 1 and path[0] in {'a'..'z', 'A'..'Z'} and path[1] == ':')
  elif defined(macos):
    # according to https://perldoc.perl.org/File/Spec/Mac.html `:a` is a relative path
    result = path[0] != ':'
  elif defined(RISCOS):
    result = path[0] == '$'
  elif defined(posix):
    result = path[0] == '/'

proc unixToNativePath*(path: string, drive=""): string {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Converts an UNIX-like path to a native one.
  ##
  ## On an UNIX system this does nothing. Else it converts
  ## `'/'`, `'.'`, `'..'` to the appropriate things.
  ##
  ## On systems with a concept of "drives", `drive` is used to determine
  ## which drive label to use during absolute path conversion.
  ## `drive` defaults to the drive of the current working directory, and is
  ## ignored on systems that do not have a concept of "drives".
  when defined(unix):
    result = path
  else:
    if path.len == 0: return ""

    var start: int
    if path[0] == '/':
      # an absolute path
      when doslikeFileSystem:
        if drive != "":
          result = drive & ":" & DirSep
        else:
          result = $DirSep
      elif defined(macos):
        result = "" # must not start with ':'
      else:
        result = $DirSep
      start = 1
    elif path[0] == '.' and (path.len == 1 or path[1] == '/'):
      # current directory
      result = $CurDir
      start = when doslikeFileSystem: 1 else: 2
    else:
      result = ""
      start = 0

    var i = start
    while i < len(path): # ../../../ --> ::::
      if i+2 < path.len and path[i] == '.' and path[i+1] == '.' and path[i+2] == '/':
        # parent directory
        when defined(macos):
          if result[high(result)] == ':':
            add result, ':'
          else:
            add result, ParDir
        else:
          add result, ParDir & DirSep
        inc(i, 3)
      elif path[i] == '/':
        add result, DirSep
        inc(i)
      else:
        add result, path[i]
        inc(i)

include "includes/oserr"
when not defined(nimscript):
  include "includes/osenv"

proc getHomeDir*(): string {.rtl, extern: "nos$1",
  tags: [ReadEnvEffect, ReadIOEffect].} =
  ## Returns the home directory of the current user.
  ##
  ## This proc is wrapped by the `expandTilde proc <#expandTilde,string>`_
  ## for the convenience of processing paths coming from user configuration files.
  ##
  ## See also:
  ## * `getConfigDir proc <#getConfigDir>`_
  ## * `getTempDir proc <#getTempDir>`_
  ## * `expandTilde proc <#expandTilde,string>`_
  ## * `getCurrentDir proc <#getCurrentDir>`_
  ## * `setCurrentDir proc <#setCurrentDir,string>`_
  runnableExamples:
    assert getHomeDir() == expandTilde("~")

  when defined(windows): return string(getEnv("USERPROFILE")) & "\\"
  else: return string(getEnv("HOME")) & "/"

proc getConfigDir*(): string {.rtl, extern: "nos$1",
  tags: [ReadEnvEffect, ReadIOEffect].} =
  ## Returns the config directory of the current user for applications.
  ##
  ## On non-Windows OSs, this proc conforms to the XDG Base Directory
  ## spec. Thus, this proc returns the value of the `XDG_CONFIG_HOME` environment
  ## variable if it is set, otherwise it returns the default configuration
  ## directory ("~/.config/").
  ##
  ## An OS-dependent trailing slash is always present at the end of the
  ## returned string: `\\` on Windows and `/` on all other OSs.
  ##
  ## See also:
  ## * `getHomeDir proc <#getHomeDir>`_
  ## * `getTempDir proc <#getTempDir>`_
  ## * `expandTilde proc <#expandTilde,string>`_
  ## * `getCurrentDir proc <#getCurrentDir>`_
  ## * `setCurrentDir proc <#setCurrentDir,string>`_
  when defined(windows):
    result = getEnv("APPDATA").string
  else:
    result = getEnv("XDG_CONFIG_HOME", getEnv("HOME").string / ".config").string
  result.normalizePathEnd(trailingSep = true)

proc getTempDir*(): string {.rtl, extern: "nos$1",
  tags: [ReadEnvEffect, ReadIOEffect].} =
  ## Returns the temporary directory of the current user for applications to
  ## save temporary files in.
  ##
  ## **Please do not use this**: On Android, it currently
  ## returns ``getHomeDir()``, and on other Unix based systems it can cause
  ## security problems too. That said, you can override this implementation
  ## by adding ``-d:tempDir=mytempname`` to your compiler invokation.
  ##
  ## See also:
  ## * `getHomeDir proc <#getHomeDir>`_
  ## * `getConfigDir proc <#getConfigDir>`_
  ## * `expandTilde proc <#expandTilde,string>`_
  ## * `getCurrentDir proc <#getCurrentDir>`_
  ## * `setCurrentDir proc <#setCurrentDir,string>`_
  when defined(tempDir):
    const tempDir {.strdefine.}: string = nil
    return tempDir
  elif defined(windows): return string(getEnv("TEMP")) & "\\"
  elif defined(android): return getHomeDir()
  else: return "/tmp/"

proc expandTilde*(path: string): string {.
  tags: [ReadEnvEffect, ReadIOEffect].} =
  ## Expands ``~`` or a path starting with ``~/`` to a full path, replacing
  ## ``~`` with `getHomeDir() <#getHomeDir>`_ (otherwise returns ``path`` unmodified).
  ##
  ## Windows: this is still supported despite Windows platform not having this
  ## convention; also, both ``~/`` and ``~\`` are handled.
  ##
  ## See also:
  ## * `getHomeDir proc <#getHomeDir>`_
  ## * `getConfigDir proc <#getConfigDir>`_
  ## * `getTempDir proc <#getTempDir>`_
  ## * `getCurrentDir proc <#getCurrentDir>`_
  ## * `setCurrentDir proc <#setCurrentDir,string>`_
  runnableExamples:
    assert expandTilde("~" / "appname.cfg") == getHomeDir() / "appname.cfg"
    assert expandTilde("~/foo/bar") == getHomeDir() / "foo/bar"
    assert expandTilde("/foo/bar") == "/foo/bar"

  if len(path) == 0 or path[0] != '~':
    result = path
  elif len(path) == 1:
    result = getHomeDir()
  elif (path[1] in {DirSep, AltSep}):
    result = getHomeDir() / path.substr(2)
  else:
    # TODO: handle `~bob` and `~bob/` which means home of bob
    result = path

# TODO: consider whether quoteShellPosix, quoteShellWindows, quoteShell, quoteShellCommand
# belong in `strutils` instead; they are not specific to paths
proc quoteShellWindows*(s: string): string {.noSideEffect, rtl, extern: "nosp$1".} =
  ## Quote `s`, so it can be safely passed to Windows API.
  ##
  ## Based on Python's `subprocess.list2cmdline`.
  ## See `this link <http://msdn.microsoft.com/en-us/library/17w5ykft.aspx>`_
  ## for more details.

  let needQuote = {' ', '\t'} in s or s.len == 0
  result = ""
  var backslashBuff = ""
  if needQuote:
    result.add("\"")

  for c in s:
    if c == '\\':
      backslashBuff.add(c)
    elif c == '\"':
      result.add(backslashBuff)
      result.add(backslashBuff)
      backslashBuff.setLen(0)
      result.add("\\\"")
    else:
      if backslashBuff.len != 0:
        result.add(backslashBuff)
        backslashBuff.setLen(0)
      result.add(c)

  if needQuote:
    result.add("\"")

proc quoteShellPosix*(s: string): string {.noSideEffect, rtl, extern: "nosp$1".} =
  ## Quote ``s``, so it can be safely passed to POSIX shell.
  ## Based on Python's `pipes.quote`.
  const safeUnixChars = {'%', '+', '-', '.', '/', '_', ':', '=', '@',
                         '0'..'9', 'A'..'Z', 'a'..'z'}
  if s.len == 0:
    return "''"

  let safe = s.allCharsInSet(safeUnixChars)

  if safe:
    return s
  else:
    return "'" & s.replace("'", "'\"'\"'") & "'"

when defined(windows) or defined(posix) or defined(nintendoswitch):
  proc quoteShell*(s: string): string {.noSideEffect, rtl, extern: "nosp$1".} =
    ## Quote ``s``, so it can be safely passed to shell.
    ##
    ## When on Windows, it calls `quoteShellWindows proc
    ## <#quoteShellWindows,string>`_. Otherwise, calls `quoteShellPosix proc
    ## <#quoteShellPosix,string>`_.
    when defined(windows):
      return quoteShellWindows(s)
    else:
      return quoteShellPosix(s)

  proc quoteShellCommand*(args: openArray[string]): string =
    ## Concatenates and quotes shell arguments `args`.
    runnableExamples:
      when defined(posix):
        assert quoteShellCommand(["aaa", "", "c d"]) == "aaa '' 'c d'"
      when defined(windows):
        assert quoteShellCommand(["aaa", "", "c d"]) == "aaa \"\" \"c d\""

    # can't use `map` pending https://github.com/nim-lang/Nim/issues/8303
    for i in 0..<args.len:
      if i > 0: result.add " "
      result.add quoteShell(args[i])

when not weirdTarget:
  proc c_rename(oldname, newname: cstring): cint {.
    importc: "rename", header: "<stdio.h>".}
  proc c_system(cmd: cstring): cint {.
    importc: "system", header: "<stdlib.h>".}
  proc c_strlen(a: cstring): cint {.
    importc: "strlen", header: "<string.h>", noSideEffect.}
  proc c_free(p: pointer) {.
    importc: "free", header: "<stdlib.h>".}


when defined(windows) and not weirdTarget:
  when useWinUnicode:
    template wrapUnary(varname, winApiProc, arg: untyped) =
      var varname = winApiProc(newWideCString(arg))

    template wrapBinary(varname, winApiProc, arg, arg2: untyped) =
      var varname = winApiProc(newWideCString(arg), arg2)
    proc findFirstFile(a: string, b: var WIN32_FIND_DATA): Handle =
      result = findFirstFileW(newWideCString(a), b)
    template findNextFile(a, b: untyped): untyped = findNextFileW(a, b)
    template getCommandLine(): untyped = getCommandLineW()

    template getFilename(f: untyped): untyped =
      $cast[WideCString](addr(f.cFilename[0]))
  else:
    template findFirstFile(a, b: untyped): untyped = findFirstFileA(a, b)
    template findNextFile(a, b: untyped): untyped = findNextFileA(a, b)
    template getCommandLine(): untyped = getCommandLineA()

    template getFilename(f: untyped): untyped = $f.cFilename

  proc skipFindData(f: WIN32_FIND_DATA): bool {.inline.} =
    # Note - takes advantage of null delimiter in the cstring
    const dot = ord('.')
    result = f.cFileName[0].int == dot and (f.cFileName[1].int == 0 or
             f.cFileName[1].int == dot and f.cFileName[2].int == 0)

proc existsFile*(filename: string): bool {.rtl, extern: "nos$1",
                                          tags: [ReadDirEffect], noNimScript.} =
  ## Returns true if `filename` exists and is a regular file or symlink.
  ##
  ## Directories, device files, named pipes and sockets return false.
  ##
  ## See also:
  ## * `existsDir proc <#existsDir,string>`_
  ## * `symlinkExists proc <#symlinkExists,string>`_
  when defined(windows):
    when useWinUnicode:
      wrapUnary(a, getFileAttributesW, filename)
    else:
      var a = getFileAttributesA(filename)
    if a != -1'i32:
      result = (a and FILE_ATTRIBUTE_DIRECTORY) == 0'i32
  else:
    var res: Stat
    return stat(filename, res) >= 0'i32 and S_ISREG(res.st_mode)

proc existsDir*(dir: string): bool {.rtl, extern: "nos$1", tags: [ReadDirEffect],
                                     noNimScript.} =
  ## Returns true iff the directory `dir` exists. If `dir` is a file, false
  ## is returned. Follows symlinks.
  ##
  ## See also:
  ## * `existsFile proc <#existsFile,string>`_
  ## * `symlinkExists proc <#symlinkExists,string>`_
  when defined(windows):
    when useWinUnicode:
      wrapUnary(a, getFileAttributesW, dir)
    else:
      var a = getFileAttributesA(dir)
    if a != -1'i32:
      result = (a and FILE_ATTRIBUTE_DIRECTORY) != 0'i32
  else:
    var res: Stat
    return stat(dir, res) >= 0'i32 and S_ISDIR(res.st_mode)

proc symlinkExists*(link: string): bool {.rtl, extern: "nos$1",
                                          tags: [ReadDirEffect],
                                          noNimScript.} =
  ## Returns true iff the symlink `link` exists. Will return true
  ## regardless of whether the link points to a directory or file.
  ##
  ## See also:
  ## * `existsFile proc <#existsFile,string>`_
  ## * `existsDir proc <#existsDir,string>`_
  when defined(windows):
    when useWinUnicode:
      wrapUnary(a, getFileAttributesW, link)
    else:
      var a = getFileAttributesA(link)
    if a != -1'i32:
      result = (a and FILE_ATTRIBUTE_REPARSE_POINT) != 0'i32
  else:
    var res: Stat
    return lstat(link, res) >= 0'i32 and S_ISLNK(res.st_mode)

proc fileExists*(filename: string): bool {.inline, noNimScript.} =
  ## Alias for `existsFile proc <#existsFile,string>`_.
  ##
  ## See also:
  ## * `existsDir proc <#existsDir,string>`_
  ## * `symlinkExists proc <#symlinkExists,string>`_
  existsFile(filename)

proc dirExists*(dir: string): bool {.inline, noNimScript.} =
  ## Alias for `existsDir proc <#existsDir,string>`_.
  ##
  ## See also:
  ## * `existsFile proc <#existsFile,string>`_
  ## * `symlinkExists proc <#symlinkExists,string>`_
  existsDir(dir)

when not defined(windows) and not weirdTarget:
  proc checkSymlink(path: string): bool =
    var rawInfo: Stat
    if lstat(path, rawInfo) < 0'i32: result = false
    else: result = S_ISLNK(rawInfo.st_mode)

const
  ExeExts* = ## Platform specific file extension for executables.
    ## On Windows ``["exe", "cmd", "bat"]``, on Posix ``[""]``.
    when defined(windows): ["exe", "cmd", "bat"] else: [""]

proc findExe*(exe: string, followSymlinks: bool = true;
              extensions: openarray[string]=ExeExts): string {.
  tags: [ReadDirEffect, ReadEnvEffect, ReadIOEffect], noNimScript.} =
  ## Searches for `exe` in the current working directory and then
  ## in directories listed in the ``PATH`` environment variable.
  ##
  ## Returns `""` if the `exe` cannot be found. `exe`
  ## is added the `ExeExts <#ExeExts>`_ file extensions if it has none.
  ##
  ## If the system supports symlinks it also resolves them until it
  ## meets the actual file. This behavior can be disabled if desired
  ## by setting `followSymlinks = false`.

  if exe.len == 0: return
  template checkCurrentDir() =
    for ext in extensions:
      result = addFileExt(exe, ext)
      if existsFile(result): return
  when defined(posix):
    if '/' in exe: checkCurrentDir()
  else:
    checkCurrentDir()
  let path = string(getEnv("PATH"))
  for candidate in split(path, PathSep):
    if candidate.len == 0: continue
    when defined(windows):
      var x = (if candidate[0] == '"' and candidate[^1] == '"':
                substr(candidate, 1, candidate.len-2) else: candidate) /
              exe
    else:
      var x = expandTilde(candidate) / exe
    for ext in extensions:
      var x = addFileExt(x, ext)
      if existsFile(x):
        when not defined(windows):
          while followSymlinks: # doubles as if here
            if x.checkSymlink:
              var r = newString(256)
              var len = readlink(x, r, 256)
              if len < 0:
                raiseOSError(osLastError())
              if len > 256:
                r = newString(len+1)
                len = readlink(x, r, len)
              setLen(r, len)
              if isAbsolute(r):
                x = r
              else:
                x = parentDir(x) / r
            else:
              break
        return x
  result = ""

when weirdTarget:
  const times = "fake const"
  template Time(x: untyped): untyped = string

proc getLastModificationTime*(file: string): times.Time {.rtl, extern: "nos$1", noNimScript.} =
  ## Returns the `file`'s last modification time.
  ##
  ## See also:
  ## * `getLastAccessTime proc <#getLastAccessTime,string>`_
  ## * `getCreationTime proc <#getCreationTime,string>`_
  ## * `fileNewer proc <#fileNewer,string,string>`_
  when defined(posix):
    var res: Stat
    if stat(file, res) < 0'i32: raiseOSError(osLastError())
    result = res.st_mtim.toTime
  else:
    var f: WIN32_FIND_DATA
    var h = findFirstFile(file, f)
    if h == -1'i32: raiseOSError(osLastError())
    result = fromWinTime(rdFileTime(f.ftLastWriteTime))
    findClose(h)

proc getLastAccessTime*(file: string): times.Time {.rtl, extern: "nos$1", noNimScript.} =
  ## Returns the `file`'s last read or write access time.
  ##
  ## See also:
  ## * `getLastModificationTime proc <#getLastModificationTime,string>`_
  ## * `getCreationTime proc <#getCreationTime,string>`_
  ## * `fileNewer proc <#fileNewer,string,string>`_
  when defined(posix):
    var res: Stat
    if stat(file, res) < 0'i32: raiseOSError(osLastError())
    result = res.st_atim.toTime
  else:
    var f: WIN32_FIND_DATA
    var h = findFirstFile(file, f)
    if h == -1'i32: raiseOSError(osLastError())
    result = fromWinTime(rdFileTime(f.ftLastAccessTime))
    findClose(h)

proc getCreationTime*(file: string): times.Time {.rtl, extern: "nos$1", noNimScript.} =
  ## Returns the `file`'s creation time.
  ##
  ## **Note:** Under POSIX OS's, the returned time may actually be the time at
  ## which the file's attribute's were last modified. See
  ## `here <https://github.com/nim-lang/Nim/issues/1058>`_ for details.
  ##
  ## See also:
  ## * `getLastModificationTime proc <#getLastModificationTime,string>`_
  ## * `getLastAccessTime proc <#getLastAccessTime,string>`_
  ## * `fileNewer proc <#fileNewer,string,string>`_
  when defined(posix):
    var res: Stat
    if stat(file, res) < 0'i32: raiseOSError(osLastError())
    result = res.st_ctim.toTime
  else:
    var f: WIN32_FIND_DATA
    var h = findFirstFile(file, f)
    if h == -1'i32: raiseOSError(osLastError())
    result = fromWinTime(rdFileTime(f.ftCreationTime))
    findClose(h)

proc fileNewer*(a, b: string): bool {.rtl, extern: "nos$1", noNimScript.} =
  ## Returns true if the file `a` is newer than file `b`, i.e. if `a`'s
  ## modification time is later than `b`'s.
  ##
  ## See also:
  ## * `getLastModificationTime proc <#getLastModificationTime,string>`_
  ## * `getLastAccessTime proc <#getLastAccessTime,string>`_
  ## * `getCreationTime proc <#getCreationTime,string>`_
  when defined(posix):
    # If we don't have access to nanosecond resolution, use '>='
    when not StatHasNanoseconds:
      result = getLastModificationTime(a) >= getLastModificationTime(b)
    else:
      result = getLastModificationTime(a) > getLastModificationTime(b)
  else:
    result = getLastModificationTime(a) > getLastModificationTime(b)

proc getCurrentDir*(): string {.rtl, extern: "nos$1", tags: [], noNimScript.} =
  ## Returns the `current working directory`:idx:.
  ##
  ## See also:
  ## * `getHomeDir proc <#getHomeDir>`_
  ## * `getConfigDir proc <#getConfigDir>`_
  ## * `getTempDir proc <#getTempDir>`_
  ## * `setCurrentDir proc <#setCurrentDir,string>`_
  when defined(windows):
    var bufsize = MAX_PATH.int32
    when useWinUnicode:
      var res = newWideCString("", bufsize)
      while true:
        var L = getCurrentDirectoryW(bufsize, res)
        if L == 0'i32:
          raiseOSError(osLastError())
        elif L > bufsize:
          res = newWideCString("", L)
          bufsize = L
        else:
          result = res$L
          break
    else:
      result = newString(bufsize)
      while true:
        var L = getCurrentDirectoryA(bufsize, result)
        if L == 0'i32:
          raiseOSError(osLastError())
        elif L > bufsize:
          result = newString(L)
          bufsize = L
        else:
          setLen(result, L)
          break
  else:
    var bufsize = 1024 # should be enough
    result = newString(bufsize)
    while true:
      if getcwd(result, bufsize) != nil:
        setLen(result, c_strlen(result))
        break
      else:
        let err = osLastError()
        if err.int32 == ERANGE:
          bufsize = bufsize shl 1
          doAssert(bufsize >= 0)
          result = newString(bufsize)
        else:
          raiseOSError(osLastError())

proc setCurrentDir*(newDir: string) {.inline, tags: [], noNimScript.} =
  ## Sets the `current working directory`:idx:; `OSError`
  ## is raised if `newDir` cannot been set.
  ##
  ## See also:
  ## * `getHomeDir proc <#getHomeDir>`_
  ## * `getConfigDir proc <#getConfigDir>`_
  ## * `getTempDir proc <#getTempDir>`_
  ## * `getCurrentDir proc <#getCurrentDir>`_
  when defined(Windows):
    when useWinUnicode:
      if setCurrentDirectoryW(newWideCString(newDir)) == 0'i32:
        raiseOSError(osLastError())
    else:
      if setCurrentDirectoryA(newDir) == 0'i32: raiseOSError(osLastError())
  else:
    if chdir(newDir) != 0'i32: raiseOSError(osLastError())

when not weirdTarget:
  proc absolutePath*(path: string, root = getCurrentDir()): string {.noNimScript.} =
    ## Returns the absolute path of `path`, rooted at `root` (which must be absolute;
    ## default: current directory).
    ## If `path` is absolute, return it, ignoring `root`.
    ##
    ## See also:
    ## * `normalizedPath proc <#normalizedPath,string>`_
    ## * `normalizePath proc <#normalizePath,string>`_
    runnableExamples:
      assert absolutePath("a") == getCurrentDir() / "a"

    if isAbsolute(path): path
    else:
      if not root.isAbsolute:
        raise newException(ValueError, "The specified root is not absolute: " & root)
      joinPath(root, path)

proc normalizePath*(path: var string) {.rtl, extern: "nos$1", tags: [], noNimScript.} =
  ## Normalize a path.
  ##
  ## Consecutive directory separators are collapsed, including an initial double slash.
  ##
  ## On relative paths, double dot (`..`) sequences are collapsed if possible.
  ## On absolute paths they are always collapsed.
  ##
  ## Warning: URL-encoded and Unicode attempts at directory traversal are not detected.
  ## Triple dot is not handled.
  ##
  ## See also:
  ## * `absolutePath proc <#absolutePath,string>`_
  ## * `normalizedPath proc <#normalizedPath,string>`_ for a version which returns
  ##   a new string
  runnableExamples:
    when defined(posix):
      var a = "a///b//..//c///d"
      a.normalizePath()
      assert a == "a/c/d"

  path = pathnorm.normalizePath(path)
  when false:
    let isAbs = isAbsolute(path)
    var stack: seq[string] = @[]
    for p in split(path, {DirSep}):
      case p
      of "", ".":
        continue
      of "..":
        if stack.len == 0:
          if isAbs:
            discard  # collapse all double dots on absoluta paths
          else:
            stack.add(p)
        elif stack[^1] == "..":
          stack.add(p)
        else:
          discard stack.pop()
      else:
        stack.add(p)

    if isAbs:
      path = DirSep & join(stack, $DirSep)
    elif stack.len > 0:
      path = join(stack, $DirSep)
    else:
      path = "."

proc normalizedPath*(path: string): string {.rtl, extern: "nos$1", tags: [], noNimScript.} =
  ## Returns a normalized path for the current OS.
  ##
  ## See also:
  ## * `absolutePath proc <#absolutePath,string>`_
  ## * `normalizePath proc <#normalizePath,string>`_ for the in-place version
  runnableExamples:
    when defined(posix):
      assert normalizedPath("a///b//..//c///d") == "a/c/d"
  result = pathnorm.normalizePath(path)

when defined(Windows) and not weirdTarget:
  proc openHandle(path: string, followSymlink=true, writeAccess=false): Handle =
    var flags = FILE_FLAG_BACKUP_SEMANTICS or FILE_ATTRIBUTE_NORMAL
    if not followSymlink:
      flags = flags or FILE_FLAG_OPEN_REPARSE_POINT
    let access = if writeAccess: GENERIC_WRITE else: 0'i32

    when useWinUnicode:
      result = createFileW(
        newWideCString(path), access,
        FILE_SHARE_DELETE or FILE_SHARE_READ or FILE_SHARE_WRITE,
        nil, OPEN_EXISTING, flags, 0
        )
    else:
      result = createFileA(
        path, access,
        FILE_SHARE_DELETE or FILE_SHARE_READ or FILE_SHARE_WRITE,
        nil, OPEN_EXISTING, flags, 0
        )

proc sameFile*(path1, path2: string): bool {.rtl, extern: "nos$1",
  tags: [ReadDirEffect], noNimScript.} =
  ## Returns true if both pathname arguments refer to the same physical
  ## file or directory.
  ##
  ## Raises `OSError` if any of the files does not
  ## exist or information about it can not be obtained.
  ##
  ## This proc will return true if given two alternative hard-linked or
  ## sym-linked paths to the same file or directory.
  ##
  ## See also:
  ## * `sameFileContent proc <#sameFileContent,string,string>`_
  when defined(Windows):
    var success = true
    var f1 = openHandle(path1)
    var f2 = openHandle(path2)

    var lastErr: OSErrorCode
    if f1 != INVALID_HANDLE_VALUE and f2 != INVALID_HANDLE_VALUE:
      var fi1, fi2: BY_HANDLE_FILE_INFORMATION

      if getFileInformationByHandle(f1, addr(fi1)) != 0 and
         getFileInformationByHandle(f2, addr(fi2)) != 0:
        result = fi1.dwVolumeSerialNumber == fi2.dwVolumeSerialNumber and
                 fi1.nFileIndexHigh == fi2.nFileIndexHigh and
                 fi1.nFileIndexLow == fi2.nFileIndexLow
      else:
        lastErr = osLastError()
        success = false
    else:
      lastErr = osLastError()
      success = false

    discard closeHandle(f1)
    discard closeHandle(f2)

    if not success: raiseOSError(lastErr)
  else:
    var a, b: Stat
    if stat(path1, a) < 0'i32 or stat(path2, b) < 0'i32:
      raiseOSError(osLastError())
    else:
      result = a.st_dev == b.st_dev and a.st_ino == b.st_ino

proc sameFileContent*(path1, path2: string): bool {.rtl, extern: "nos$1",
  tags: [ReadIOEffect], noNimScript.} =
  ## Returns true if both pathname arguments refer to files with identical
  ## binary content.
  ##
  ## See also:
  ## * `sameFile proc <#sameFile,string,string>`_
  const
    bufSize = 8192 # 8K buffer
  var
    a, b: File
  if not open(a, path1): return false
  if not open(b, path2):
    close(a)
    return false
  var bufA = alloc(bufSize)
  var bufB = alloc(bufSize)
  while true:
    var readA = readBuffer(a, bufA, bufSize)
    var readB = readBuffer(b, bufB, bufSize)
    if readA != readB:
      result = false
      break
    if readA == 0:
      result = true
      break
    result = equalMem(bufA, bufB, readA)
    if not result: break
    if readA != bufSize: break # end of file
  dealloc(bufA)
  dealloc(bufB)
  close(a)
  close(b)

type
  FilePermission* = enum   ## File access permission, modelled after UNIX.
    ##
    ## See also:
    ## * `getFilePermissions <#getFilePermissions,string>`_
    ## * `setFilePermissions <#setFilePermissions,string,set[FilePermission]>`_
    ## * `FileInfo object <#FileInfo>`_
    fpUserExec,            ## execute access for the file owner
    fpUserWrite,           ## write access for the file owner
    fpUserRead,            ## read access for the file owner
    fpGroupExec,           ## execute access for the group
    fpGroupWrite,          ## write access for the group
    fpGroupRead,           ## read access for the group
    fpOthersExec,          ## execute access for others
    fpOthersWrite,         ## write access for others
    fpOthersRead           ## read access for others

proc getFilePermissions*(filename: string): set[FilePermission] {.
  rtl, extern: "nos$1", tags: [ReadDirEffect], noNimScript.} =
  ## Retrieves file permissions for `filename`.
  ##
  ## `OSError` is raised in case of an error.
  ## On Windows, only the ``readonly`` flag is checked, every other
  ## permission is available in any case.
  ##
  ## See also:
  ## * `setFilePermissions proc <#setFilePermissions,string,set[FilePermission]>`_
  ## * `FilePermission enum <#FilePermission>`_
  when defined(posix):
    var a: Stat
    if stat(filename, a) < 0'i32: raiseOSError(osLastError())
    result = {}
    if (a.st_mode and S_IRUSR) != 0'i32: result.incl(fpUserRead)
    if (a.st_mode and S_IWUSR) != 0'i32: result.incl(fpUserWrite)
    if (a.st_mode and S_IXUSR) != 0'i32: result.incl(fpUserExec)

    if (a.st_mode and S_IRGRP) != 0'i32: result.incl(fpGroupRead)
    if (a.st_mode and S_IWGRP) != 0'i32: result.incl(fpGroupWrite)
    if (a.st_mode and S_IXGRP) != 0'i32: result.incl(fpGroupExec)

    if (a.st_mode and S_IROTH) != 0'i32: result.incl(fpOthersRead)
    if (a.st_mode and S_IWOTH) != 0'i32: result.incl(fpOthersWrite)
    if (a.st_mode and S_IXOTH) != 0'i32: result.incl(fpOthersExec)
  else:
    when useWinUnicode:
      wrapUnary(res, getFileAttributesW, filename)
    else:
      var res = getFileAttributesA(filename)
    if res == -1'i32: raiseOSError(osLastError())
    if (res and FILE_ATTRIBUTE_READONLY) != 0'i32:
      result = {fpUserExec, fpUserRead, fpGroupExec, fpGroupRead,
                fpOthersExec, fpOthersRead}
    else:
      result = {fpUserExec..fpOthersRead}

proc setFilePermissions*(filename: string, permissions: set[FilePermission]) {.
  rtl, extern: "nos$1", tags: [WriteDirEffect], noNimScript.} =
  ## Sets the file permissions for `filename`.
  ##
  ## `OSError` is raised in case of an error.
  ## On Windows, only the ``readonly`` flag is changed, depending on
  ## ``fpUserWrite`` permission.
  ##
  ## See also:
  ## * `getFilePermissions <#getFilePermissions,string>`_
  ## * `FilePermission enum <#FilePermission>`_
  when defined(posix):
    var p = 0'i32
    if fpUserRead in permissions: p = p or S_IRUSR
    if fpUserWrite in permissions: p = p or S_IWUSR
    if fpUserExec in permissions: p = p or S_IXUSR

    if fpGroupRead in permissions: p = p or S_IRGRP
    if fpGroupWrite in permissions: p = p or S_IWGRP
    if fpGroupExec in permissions: p = p or S_IXGRP

    if fpOthersRead in permissions: p = p or S_IROTH
    if fpOthersWrite in permissions: p = p or S_IWOTH
    if fpOthersExec in permissions: p = p or S_IXOTH

    if chmod(filename, p) != 0: raiseOSError(osLastError())
  else:
    when useWinUnicode:
      wrapUnary(res, getFileAttributesW, filename)
    else:
      var res = getFileAttributesA(filename)
    if res == -1'i32: raiseOSError(osLastError())
    if fpUserWrite in permissions:
      res = res and not FILE_ATTRIBUTE_READONLY
    else:
      res = res or FILE_ATTRIBUTE_READONLY
    when useWinUnicode:
      wrapBinary(res2, setFileAttributesW, filename, res)
    else:
      var res2 = setFileAttributesA(filename, res)
    if res2 == - 1'i32: raiseOSError(osLastError())

proc copyFile*(source, dest: string) {.rtl, extern: "nos$1",
  tags: [ReadIOEffect, WriteIOEffect], noNimScript.} =
  ## Copies a file from `source` to `dest`.
  ##
  ## If this fails, `OSError` is raised.
  ##
  ## On the Windows platform this proc will
  ## copy the source file's attributes into dest.
  ##
  ## On other platforms you need
  ## to use `getFilePermissions <#getFilePermissions,string>`_ and
  ## `setFilePermissions <#setFilePermissions,string,set[FilePermission]>`_ procs
  ## to copy them by hand (or use the convenience `copyFileWithPermissions
  ## proc <#copyFileWithPermissions,string,string>`_),
  ## otherwise `dest` will inherit the default permissions of a newly
  ## created file for the user.
  ##
  ## If `dest` already exists, the file attributes
  ## will be preserved and the content overwritten.
  ##
  ## See also:
  ## * `copyDir proc <#copyDir,string,string>`_
  ## * `copyFileWithPermissions proc <#copyFileWithPermissions,string,string>`_
  ## * `tryRemoveFile proc <#tryRemoveFile,string>`_
  ## * `removeFile proc <#removeFile,string>`_
  ## * `moveFile proc <#moveFile,string,string>`_

  when defined(Windows):
    when useWinUnicode:
      let s = newWideCString(source)
      let d = newWideCString(dest)
      if copyFileW(s, d, 0'i32) == 0'i32: raiseOSError(osLastError())
    else:
      if copyFileA(source, dest, 0'i32) == 0'i32: raiseOSError(osLastError())
  else:
    # generic version of copyFile which works for any platform:
    const bufSize = 8000 # better for memory manager
    var d, s: File
    if not open(s, source): raiseOSError(osLastError())
    if not open(d, dest, fmWrite):
      close(s)
      raiseOSError(osLastError())
    var buf = alloc(bufSize)
    while true:
      var bytesread = readBuffer(s, buf, bufSize)
      if bytesread > 0:
        var byteswritten = writeBuffer(d, buf, bytesread)
        if bytesread != byteswritten:
          dealloc(buf)
          close(s)
          close(d)
          raiseOSError(osLastError())
      if bytesread != bufSize: break
    dealloc(buf)
    close(s)
    flushFile(d)
    close(d)

when not declared(ENOENT) and not defined(Windows):
  when NoFakeVars:
    when not defined(haiku):
      const ENOENT = cint(2) # 2 on most systems including Solaris
    else:
      const ENOENT = cint(-2147459069)
  else:
    var ENOENT {.importc, header: "<errno.h>".}: cint

when defined(Windows) and not weirdTarget:
  when useWinUnicode:
    template deleteFile(file: untyped): untyped  = deleteFileW(file)
    template setFileAttributes(file, attrs: untyped): untyped =
      setFileAttributesW(file, attrs)
  else:
    template deleteFile(file: untyped): untyped = deleteFileA(file)
    template setFileAttributes(file, attrs: untyped): untyped =
      setFileAttributesA(file, attrs)

proc tryRemoveFile*(file: string): bool {.rtl, extern: "nos$1", tags: [WriteDirEffect], noNimScript.} =
  ## Removes the `file`.
  ##
  ## If this fails, returns `false`. This does not fail
  ## if the file never existed in the first place.
  ##
  ## On Windows, ignores the read-only attribute.
  ##
  ## See also:
  ## * `copyFile proc <#copyFile,string,string>`_
  ## * `copyFileWithPermissions proc <#copyFileWithPermissions,string,string>`_
  ## * `removeFile proc <#removeFile,string>`_
  ## * `moveFile proc <#moveFile,string,string>`_
  result = true
  when defined(Windows):
    when useWinUnicode:
      let f = newWideCString(file)
    else:
      let f = file
    if deleteFile(f) == 0:
      result = false
      let err = getLastError()
      if err == ERROR_FILE_NOT_FOUND or err == ERROR_PATH_NOT_FOUND:
        result = true
      elif err == ERROR_ACCESS_DENIED and
         setFileAttributes(f, FILE_ATTRIBUTE_NORMAL) != 0 and
         deleteFile(f) != 0:
        result = true
  else:
    if unlink(file) != 0'i32 and errno != ENOENT:
      result = false

proc removeFile*(file: string) {.rtl, extern: "nos$1", tags: [WriteDirEffect], noNimScript.} =
  ## Removes the `file`.
  ##
  ## If this fails, `OSError` is raised. This does not fail
  ## if the file never existed in the first place.
  ##
  ## On Windows, ignores the read-only attribute.
  ##
  ## See also:
  ## * `removeDir proc <#removeDir,string>`_
  ## * `copyFile proc <#copyFile,string,string>`_
  ## * `copyFileWithPermissions proc <#copyFileWithPermissions,string,string>`_
  ## * `tryRemoveFile proc <#tryRemoveFile,string>`_
  ## * `moveFile proc <#moveFile,string,string>`_
  if not tryRemoveFile(file):
    when defined(Windows):
      raiseOSError(osLastError())
    else:
      raiseOSError(osLastError(), $strerror(errno))

proc tryMoveFSObject(source, dest: string): bool {.noNimScript.} =
  ## Moves a file or directory from `source` to `dest`.
  ##
  ## Returns false in case of `EXDEV` error.
  ## In case of other errors `OSError` is raised.
  ## Returns true in case of success.
  when defined(Windows):
    when useWinUnicode:
      let s = newWideCString(source)
      let d = newWideCString(dest)
      if moveFileExW(s, d, MOVEFILE_COPY_ALLOWED) == 0'i32: raiseOSError(osLastError())
    else:
      if moveFileExA(source, dest, MOVEFILE_COPY_ALLOWED) == 0'i32: raiseOSError(osLastError())
  else:
    if c_rename(source, dest) != 0'i32:
      let err = osLastError()
      if err == EXDEV.OSErrorCode:
        return false
      else:
        raiseOSError(err, $strerror(errno))
  return true

proc moveFile*(source, dest: string) {.rtl, extern: "nos$1",
  tags: [ReadIOEffect, WriteIOEffect], noNimScript.} =
  ## Moves a file from `source` to `dest`.
  ##
  ## If this fails, `OSError` is raised.
  ## If `dest` already exists, it will be overwritten.
  ##
  ## Can be used to `rename files`:idx:.
  ##
  ## See also:
  ## * `moveDir proc <#moveDir,string,string>`_
  ## * `copyFile proc <#copyFile,string,string>`_
  ## * `copyFileWithPermissions proc <#copyFileWithPermissions,string,string>`_
  ## * `removeFile proc <#removeFile,string>`_
  ## * `tryRemoveFile proc <#tryRemoveFile,string>`_

  if not tryMoveFSObject(source, dest):
    when not defined(windows):
      # Fallback to copy & del
      copyFile(source, dest)
      try:
        removeFile(source)
      except:
        discard tryRemoveFile(dest)
        raise

proc exitStatusLikeShell*(status: cint): cint =
  ## Converts exit code from `c_system` into a shell exit code.
  when defined(posix) and not weirdTarget:
    if WIFSIGNALED(status):
      # like the shell!
      128 + WTERMSIG(status)
    else:
      WEXITSTATUS(status)
  else:
    status

proc execShellCmd*(command: string): int {.rtl, extern: "nos$1",
  tags: [ExecIOEffect], noNimScript.} =
  ## Executes a `shell command`:idx:.
  ##
  ## Command has the form 'program args' where args are the command
  ## line arguments given to program. The proc returns the error code
  ## of the shell when it has finished (zero if there is no error).
  ## The proc does not return until the process has finished.
  ##
  ## To execute a program without having a shell involved, use `osproc.execProcess proc
  ## <osproc.html#execProcess,string,string,openArray[string],StringTableRef,set[ProcessOption]>`_.
  ##
  ## **Examples:**
  ##
  ## .. code-block::
  ##   discard execShellCmd("ls -la")
  result = exitStatusLikeShell(c_system(command))

# Templates for filtering directories and files
when defined(windows) and not weirdTarget:
  template isDir(f: WIN32_FIND_DATA): bool =
    (f.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) != 0'i32
  template isFile(f: WIN32_FIND_DATA): bool =
    not isDir(f)
else:
  template isDir(f: string): bool {.dirty.} =
    dirExists(f)
  template isFile(f: string): bool {.dirty.} =
    fileExists(f)

template defaultWalkFilter(item): bool =
  ## Walk filter used to return true on both
  ## files and directories
  true

template walkCommon(pattern: string, filter) =
  ## Common code for getting the files and directories with the
  ## specified `pattern`
  when defined(windows):
    var
      f: WIN32_FIND_DATA
      res: int
    res = findFirstFile(pattern, f)
    if res != -1:
      defer: findClose(res)
      let dotPos = searchExtPos(pattern)
      while true:
        if not skipFindData(f) and filter(f):
          # Windows bug/gotcha: 't*.nim' matches 'tfoo.nims' -.- so we check
          # that the file extensions have the same length ...
          let ff = getFilename(f)
          let idx = ff.len - pattern.len + dotPos
          if dotPos < 0 or idx >= ff.len or ff[idx] == '.' or
              pattern[dotPos+1] == '*':
            yield splitFile(pattern).dir / extractFilename(ff)
        if findNextFile(res, f) == 0'i32:
          let errCode = getLastError()
          if errCode == ERROR_NO_MORE_FILES: break
          else: raiseOSError(errCode.OSErrorCode)
  else: # here we use glob
    var
      f: Glob
      res: int
    f.gl_offs = 0
    f.gl_pathc = 0
    f.gl_pathv = nil
    res = glob(pattern, 0, nil, addr(f))
    defer: globfree(addr(f))
    if res == 0:
      for i in 0.. f.gl_pathc - 1:
        assert(f.gl_pathv[i] != nil)
        let path = $f.gl_pathv[i]
        if filter(path):
          yield path

iterator walkPattern*(pattern: string): string {.tags: [ReadDirEffect], noNimScript.} =
  ## Iterate over all the files and directories that match the `pattern`.
  ##
  ## On POSIX this uses the `glob`:idx: call.
  ## `pattern` is OS dependent, but at least the `"\*.ext"`
  ## notation is supported.
  ##
  ## See also:
  ## * `walkFiles iterator <#walkFiles.i,string>`_
  ## * `walkDirs iterator <#walkDirs.i,string>`_
  ## * `walkDir iterator <#walkDir.i,string>`_
  ## * `walkDirRec iterator <#walkDirRec.i,string>`_
  walkCommon(pattern, defaultWalkFilter)

iterator walkFiles*(pattern: string): string {.tags: [ReadDirEffect], noNimScript.} =
  ## Iterate over all the files that match the `pattern`.
  ##
  ## On POSIX this uses the `glob`:idx: call.
  ## `pattern` is OS dependent, but at least the `"\*.ext"`
  ## notation is supported.
  ##
  ## See also:
  ## * `walkPattern iterator <#walkPattern.i,string>`_
  ## * `walkDirs iterator <#walkDirs.i,string>`_
  ## * `walkDir iterator <#walkDir.i,string>`_
  ## * `walkDirRec iterator <#walkDirRec.i,string>`_
  walkCommon(pattern, isFile)

iterator walkDirs*(pattern: string): string {.tags: [ReadDirEffect], noNimScript.} =
  ## Iterate over all the directories that match the `pattern`.
  ##
  ## On POSIX this uses the `glob`:idx: call.
  ## `pattern` is OS dependent, but at least the `"\*.ext"`
  ## notation is supported.
  ##
  ## See also:
  ## * `walkPattern iterator <#walkPattern.i,string>`_
  ## * `walkFiles iterator <#walkFiles.i,string>`_
  ## * `walkDir iterator <#walkDir.i,string>`_
  ## * `walkDirRec iterator <#walkDirRec.i,string>`_
  walkCommon(pattern, isDir)

proc expandFilename*(filename: string): string {.rtl, extern: "nos$1",
  tags: [ReadDirEffect], noNimScript.} =
  ## Returns the full (`absolute`:idx:) path of an existing file `filename`.
  ##
  ## Raises `OSError` in case of an error. Follows symlinks.
  when defined(windows):
    var bufsize = MAX_PATH.int32
    when useWinUnicode:
      var unused: WideCString = nil
      var res = newWideCString("", bufsize)
      while true:
        var L = getFullPathNameW(newWideCString(filename), bufsize, res, unused)
        if L == 0'i32:
          raiseOSError(osLastError())
        elif L > bufsize:
          res = newWideCString("", L)
          bufsize = L
        else:
          result = res$L
          break
    else:
      var unused: cstring = nil
      result = newString(bufsize)
      while true:
        var L = getFullPathNameA(filename, bufsize, result, unused)
        if L == 0'i32:
          raiseOSError(osLastError())
        elif L > bufsize:
          result = newString(L)
          bufsize = L
        else:
          setLen(result, L)
          break
    # getFullPathName doesn't do case corrections, so we have to use this convoluted
    # way of retrieving the true filename
    for x in walkFiles(result.string):
      result = x
    if not existsFile(result) and not existsDir(result):
      raise newException(OSError, "file '" & result & "' does not exist")
  else:
    # according to Posix we don't need to allocate space for result pathname.
    # But we need to free return value with free(3).
    var r = realpath(filename, nil)
    if r.isNil:
      raiseOSError(osLastError())
    else:
      result = $r
      c_free(cast[pointer](r))

type
  PathComponent* = enum   ## Enumeration specifying a path component.
    ##
    ## See also:
    ## * `walkDirRec iterator <#walkDirRec.i,string>`_
    ## * `FileInfo object <#FileInfo>`_
    pcFile,               ## path refers to a file
    pcLinkToFile,         ## path refers to a symbolic link to a file
    pcDir,                ## path refers to a directory
    pcLinkToDir           ## path refers to a symbolic link to a directory

proc getCurrentCompilerExe*(): string {.compileTime.} = discard
  ## This is `getAppFilename() <#getAppFilename>`_ at compile time.
  ##
  ## Can be used to retrive the currently executing
  ## Nim compiler from a Nim or nimscript program, or the nimble binary
  ## inside a nimble program (likewise with other binaries built from
  ## compiler API).

when defined(posix) and not weirdTarget:
  proc getSymlinkFileKind(path: string): PathComponent =
    # Helper function.
    var s: Stat
    assert(path != "")
    if stat(path, s) == 0'i32 and S_ISDIR(s.st_mode):
      result = pcLinkToDir
    else:
      result = pcLinkToFile

proc staticWalkDir(dir: string; relative: bool): seq[
                  tuple[kind: PathComponent, path: string]] =
  discard

iterator walkDir*(dir: string; relative=false): tuple[kind: PathComponent, path: string] {.
  tags: [ReadDirEffect].} =
  ## Walks over the directory `dir` and yields for each directory or file in
  ## `dir`. The component type and full path for each item are returned.
  ##
  ## Walking is not recursive. If ``relative`` is true (default: false)
  ## the resulting path is shortened to be relative to ``dir``.
  ## Example: This directory structure::
  ##   dirA / dirB / fileB1.txt
  ##        / dirC
  ##        / fileA1.txt
  ##        / fileA2.txt
  ##
  ## and this code:
  ##
  ## .. code-block:: Nim
  ##     for kind, path in walkDir("dirA"):
  ##       echo(path)
  ##
  ## produce this output (but not necessarily in this order!)::
  ##   dirA/dirB
  ##   dirA/dirC
  ##   dirA/fileA1.txt
  ##   dirA/fileA2.txt
  ##
  ## See also:
  ## * `walkPattern iterator <#walkPattern.i,string>`_
  ## * `walkFiles iterator <#walkFiles.i,string>`_
  ## * `walkDirs iterator <#walkDirs.i,string>`_
  ## * `walkDirRec iterator <#walkDirRec.i,string>`_

  when nimvm:
    for k, v in items(staticWalkDir(dir, relative)):
      yield (k, v)
  else:
    when weirdTarget:
      for k, v in items(staticWalkDir(dir, relative)):
        yield (k, v)
    elif defined(windows):
      var f: WIN32_FIND_DATA
      var h = findFirstFile(dir / "*", f)
      if h != -1:
        defer: findClose(h)
        while true:
          var k = pcFile
          if not skipFindData(f):
            if (f.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) != 0'i32:
              k = pcDir
            if (f.dwFileAttributes and FILE_ATTRIBUTE_REPARSE_POINT) != 0'i32:
              k = succ(k)
            let xx = if relative: extractFilename(getFilename(f))
                     else: dir / extractFilename(getFilename(f))
            yield (k, xx)
          if findNextFile(h, f) == 0'i32:
            let errCode = getLastError()
            if errCode == ERROR_NO_MORE_FILES: break
            else: raiseOSError(errCode.OSErrorCode)
    else:
      var d = opendir(dir)
      if d != nil:
        defer: discard closedir(d)
        while true:
          var x = readdir(d)
          if x == nil: break
          when defined(nimNoArrayToCstringConversion):
            var y = $cstring(addr x.d_name)
          else:
            var y = $x.d_name.cstring
          if y != "." and y != "..":
            var s: Stat
            let path = dir / y
            if not relative:
              y = path
            var k = pcFile

            when defined(linux) or defined(macosx) or
                 defined(bsd) or defined(genode) or defined(nintendoswitch):
              if x.d_type != DT_UNKNOWN:
                if x.d_type == DT_DIR: k = pcDir
                if x.d_type == DT_LNK:
                  if dirExists(path): k = pcLinkToDir
                  else: k = pcLinkToFile
                yield (k, y)
                continue

            if lstat(path, s) < 0'i32: break
            if S_ISDIR(s.st_mode):
              k = pcDir
            elif S_ISLNK(s.st_mode):
              k = getSymlinkFileKind(path)
            yield (k, y)

iterator walkDirRec*(dir: string,
                     yieldFilter = {pcFile}, followFilter = {pcDir},
                     relative = false): string {.tags: [ReadDirEffect].} =
  ## Recursively walks over the directory `dir` and yields for each file
  ## or directory in `dir`.
  ##
  ## If ``relative`` is true (default: false) the resulting path is
  ## shortened to be relative to ``dir``, otherwise the full path is returned.
  ##
  ## **Warning**:
  ## Modifying the directory structure while the iterator
  ## is traversing may result in undefined behavior!
  ##
  ## Walking is recursive. `followFilter` controls the behaviour of the iterator:
  ##
  ## ---------------------   ---------------------------------------------
  ## yieldFilter             meaning
  ## ---------------------   ---------------------------------------------
  ## ``pcFile``              yield real files (default)
  ## ``pcLinkToFile``        yield symbolic links to files
  ## ``pcDir``               yield real directories
  ## ``pcLinkToDir``         yield symbolic links to directories
  ## ---------------------   ---------------------------------------------
  ##
  ## ---------------------   ---------------------------------------------
  ## followFilter            meaning
  ## ---------------------   ---------------------------------------------
  ## ``pcDir``               follow real directories (default)
  ## ``pcLinkToDir``         follow symbolic links to directories
  ## ---------------------   ---------------------------------------------
  ##
  ##
  ## See also:
  ## * `walkPattern iterator <#walkPattern.i,string>`_
  ## * `walkFiles iterator <#walkFiles.i,string>`_
  ## * `walkDirs iterator <#walkDirs.i,string>`_
  ## * `walkDir iterator <#walkDir.i,string>`_

  var stack = @[""]
  while stack.len > 0:
    let d = stack.pop()
    for k, p in walkDir(dir / d, relative = true):
      let rel = d / p
      if k in {pcDir, pcLinkToDir} and k in followFilter:
        stack.add rel
      if k in yieldFilter:
        yield if relative: rel else: dir / rel

proc rawRemoveDir(dir: string) {.noNimScript.} =
  when defined(windows):
    when useWinUnicode:
      wrapUnary(res, removeDirectoryW, dir)
    else:
      var res = removeDirectoryA(dir)
    let lastError = osLastError()
    if res == 0'i32 and lastError.int32 != 3'i32 and
        lastError.int32 != 18'i32 and lastError.int32 != 2'i32:
      raiseOSError(lastError)
  else:
    if rmdir(dir) != 0'i32 and errno != ENOENT: raiseOSError(osLastError())

proc removeDir*(dir: string) {.rtl, extern: "nos$1", tags: [
  WriteDirEffect, ReadDirEffect], benign, noNimScript.} =
  ## Removes the directory `dir` including all subdirectories and files
  ## in `dir` (recursively).
  ##
  ## If this fails, `OSError` is raised. This does not fail if the directory never
  ## existed in the first place.
  ##
  ## See also:
  ## * `tryRemoveFile proc <#tryRemoveFile,string>`_
  ## * `removeFile proc <#removeFile,string>`_
  ## * `existsOrCreateDir proc <#existsOrCreateDir,string>`_
  ## * `createDir proc <#createDir,string>`_
  ## * `copyDir proc <#copyDir,string,string>`_
  ## * `copyDirWithPermissions proc <#copyDirWithPermissions,string,string>`_
  ## * `moveDir proc <#moveDir,string,string>`_
  for kind, path in walkDir(dir):
    case kind
    of pcFile, pcLinkToFile, pcLinkToDir: removeFile(path)
    of pcDir: removeDir(path)
  rawRemoveDir(dir)

proc rawCreateDir(dir: string): bool {.noNimScript.} =
  # Try to create one directory (not the whole path).
  # returns `true` for success, `false` if the path has previously existed
  #
  # This is a thin wrapper over mkDir (or alternatives on other systems),
  # so in case of a pre-existing path we don't check that it is a directory.
  when defined(solaris):
    let res = mkdir(dir, 0o777)
    if res == 0'i32:
      result = true
    elif errno in {EEXIST, ENOSYS}:
      result = false
    else:
      raiseOSError(osLastError(), dir)
  elif defined(haiku):
    let res = mkdir(dir, 0o777)
    if res == 0'i32:
      result = true
    elif errno == EEXIST or errno == EROFS:
      result = false
    else:
      raiseOSError(osLastError(), dir)
  elif defined(posix):
    let res = mkdir(dir, 0o777)
    if res == 0'i32:
      result = true
    elif errno == EEXIST:
      result = false
    else:
      #echo res
      raiseOSError(osLastError(), dir)
  else:
    when useWinUnicode:
      wrapUnary(res, createDirectoryW, dir)
    else:
      let res = createDirectoryA(dir)

    if res != 0'i32:
      result = true
    elif getLastError() == 183'i32:
      result = false
    else:
      raiseOSError(osLastError(), dir)

proc existsOrCreateDir*(dir: string): bool {.rtl, extern: "nos$1",
  tags: [WriteDirEffect, ReadDirEffect], noNimScript.} =
  ## Check if a `directory`:idx: `dir` exists, and create it otherwise.
  ##
  ## Does not create parent directories (fails if parent does not exist).
  ## Returns `true` if the directory already exists, and `false`
  ## otherwise.
  ##
  ## See also:
  ## * `removeDir proc <#removeDir,string>`_
  ## * `createDir proc <#createDir,string>`_
  ## * `copyDir proc <#copyDir,string,string>`_
  ## * `copyDirWithPermissions proc <#copyDirWithPermissions,string,string>`_
  ## * `moveDir proc <#moveDir,string,string>`_
  result = not rawCreateDir(dir)
  if result:
    # path already exists - need to check that it is indeed a directory
    if not existsDir(dir):
      raise newException(IOError, "Failed to create '" & dir & "'")

proc createDir*(dir: string) {.rtl, extern: "nos$1",
  tags: [WriteDirEffect, ReadDirEffect], noNimScript.} =
  ## Creates the `directory`:idx: `dir`.
  ##
  ## The directory may contain several subdirectories that do not exist yet.
  ## The full path is created. If this fails, `OSError` is raised.
  ##
  ## It does **not** fail if the directory already exists because for
  ## most usages this does not indicate an error.
  ##
  ## See also:
  ## * `removeDir proc <#removeDir,string>`_
  ## * `existsOrCreateDir proc <#existsOrCreateDir,string>`_
  ## * `copyDir proc <#copyDir,string,string>`_
  ## * `copyDirWithPermissions proc <#copyDirWithPermissions,string,string>`_
  ## * `moveDir proc <#moveDir,string,string>`_
  var omitNext = false
  when doslikeFileSystem:
    omitNext = isAbsolute(dir)
  for i in 1.. dir.len-1:
    if dir[i] in {DirSep, AltSep}:
      if omitNext:
        omitNext = false
      else:
        discard existsOrCreateDir(substr(dir, 0, i-1))

  # The loop does not create the dir itself if it doesn't end in separator
  if dir.len > 0 and not omitNext and
     dir[^1] notin {DirSep, AltSep}:
    discard existsOrCreateDir(dir)

proc copyDir*(source, dest: string) {.rtl, extern: "nos$1",
  tags: [WriteIOEffect, ReadIOEffect], benign, noNimScript.} =
  ## Copies a directory from `source` to `dest`.
  ##
  ## If this fails, `OSError` is raised.
  ##
  ## On the Windows platform this proc will copy the attributes from
  ## `source` into `dest`.
  ##
  ## On other platforms created files and directories will inherit the
  ## default permissions of a newly created file/directory for the user.
  ## Use `copyDirWithPermissions proc <#copyDirWithPermissions,string,string>`_
  ## to preserve attributes recursively on these platforms.
  ##
  ## See also:
  ## * `copyDirWithPermissions proc <#copyDirWithPermissions,string,string>`_
  ## * `copyFile proc <#copyFile,string,string>`_
  ## * `copyFileWithPermissions proc <#copyFileWithPermissions,string,string>`_
  ## * `removeDir proc <#removeDir,string>`_
  ## * `existsOrCreateDir proc <#existsOrCreateDir,string>`_
  ## * `createDir proc <#createDir,string>`_
  ## * `moveDir proc <#moveDir,string,string>`_
  createDir(dest)
  for kind, path in walkDir(source):
    var noSource = splitPath(path).tail
    case kind
    of pcFile:
      copyFile(path, dest / noSource)
    of pcDir:
      copyDir(path, dest / noSource)
    else: discard

proc moveDir*(source, dest: string) {.tags: [ReadIOEffect, WriteIOEffect], noNimScript.} =
  ## Moves a directory from `source` to `dest`.
  ##
  ## If this fails, `OSError` is raised.
  ##
  ## See also:
  ## * `moveFile proc <#moveFile,string,string>`_
  ## * `copyDir proc <#copyDir,string,string>`_
  ## * `copyDirWithPermissions proc <#copyDirWithPermissions,string,string>`_
  ## * `removeDir proc <#removeDir,string>`_
  ## * `existsOrCreateDir proc <#existsOrCreateDir,string>`_
  ## * `createDir proc <#createDir,string>`_
  if not tryMoveFSObject(source, dest):
    when not defined(windows):
      # Fallback to copy & del
      copyDir(source, dest)
      removeDir(source)

proc createSymlink*(src, dest: string) {.noNimScript.} =
  ## Create a symbolic link at `dest` which points to the item specified
  ## by `src`. On most operating systems, will fail if a link already exists.
  ##
  ## **Warning**:
  ## Some OS's (such as Microsoft Windows) restrict the creation
  ## of symlinks to root users (administrators).
  ##
  ## See also:
  ## * `createHardlink proc <#createHardlink,string,string>`_
  ## * `expandSymlink proc <#expandSymlink,string>`_

  when defined(Windows):
    # 2 is the SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE. This allows
    # anyone with developer mode on to create a link
    let flag = dirExists(src).int32 or 2
    when useWinUnicode:
      var wSrc = newWideCString(src)
      var wDst = newWideCString(dest)
      if createSymbolicLinkW(wDst, wSrc, flag) == 0 or getLastError() != 0:
        raiseOSError(osLastError())
    else:
      if createSymbolicLinkA(dest, src, flag) == 0 or getLastError() != 0:
        raiseOSError(osLastError())
  else:
    if symlink(src, dest) != 0:
      raiseOSError(osLastError())

proc createHardlink*(src, dest: string) {.noNimScript.} =
  ## Create a hard link at `dest` which points to the item specified
  ## by `src`.
  ##
  ## **Warning**: Some OS's restrict the creation of hard links to
  ## root users (administrators).
  ##
  ## See also:
  ## * `createSymlink proc <#createSymlink,string,string>`_
  when defined(Windows):
    when useWinUnicode:
      var wSrc = newWideCString(src)
      var wDst = newWideCString(dest)
      if createHardLinkW(wDst, wSrc, nil) == 0:
        raiseOSError(osLastError())
    else:
      if createHardLinkA(dest, src, nil) == 0:
        raiseOSError(osLastError())
  else:
    if link(src, dest) != 0:
      raiseOSError(osLastError())

proc copyFileWithPermissions*(source, dest: string,
                              ignorePermissionErrors = true) {.noNimScript.} =
  ## Copies a file from `source` to `dest` preserving file permissions.
  ##
  ## This is a wrapper proc around `copyFile <#copyFile,string,string>`_,
  ## `getFilePermissions <#getFilePermissions,string>`_ and
  ## `setFilePermissions<#setFilePermissions,string,set[FilePermission]>`_
  ## procs on non-Windows platforms.
  ##
  ## On Windows this proc is just a wrapper for `copyFile proc
  ## <#copyFile,string,string>`_ since that proc already copies attributes.
  ##
  ## On non-Windows systems permissions are copied after the file itself has
  ## been copied, which won't happen atomically and could lead to a race
  ## condition. If `ignorePermissionErrors` is true (default), errors while
  ## reading/setting file attributes will be ignored, otherwise will raise
  ## `OSError`.
  ##
  ## See also:
  ## * `copyFile proc <#copyFile,string,string>`_
  ## * `copyDir proc <#copyDir,string,string>`_
  ## * `tryRemoveFile proc <#tryRemoveFile,string>`_
  ## * `removeFile proc <#removeFile,string>`_
  ## * `moveFile proc <#moveFile,string,string>`_
  ## * `copyDirWithPermissions proc <#copyDirWithPermissions,string,string>`_
  copyFile(source, dest)
  when not defined(Windows):
    try:
      setFilePermissions(dest, getFilePermissions(source))
    except:
      if not ignorePermissionErrors:
        raise

proc copyDirWithPermissions*(source, dest: string,
    ignorePermissionErrors = true) {.rtl, extern: "nos$1",
    tags: [WriteIOEffect, ReadIOEffect], benign, noNimScript.} =
  ## Copies a directory from `source` to `dest` preserving file permissions.
  ##
  ## If this fails, `OSError` is raised. This is a wrapper proc around `copyDir
  ## <#copyDir,string,string>`_ and `copyFileWithPermissions
  ## <#copyFileWithPermissions,string,string>`_ procs
  ## on non-Windows platforms.
  ##
  ## On Windows this proc is just a wrapper for `copyDir proc
  ## <#copyDir,string,string>`_ since that proc already copies attributes.
  ##
  ## On non-Windows systems permissions are copied after the file or directory
  ## itself has been copied, which won't happen atomically and could lead to a
  ## race condition. If `ignorePermissionErrors` is true (default), errors while
  ## reading/setting file attributes will be ignored, otherwise will raise
  ## `OSError`.
  ##
  ## See also:
  ## * `copyDir proc <#copyDir,string,string>`_
  ## * `copyFile proc <#copyFile,string,string>`_
  ## * `copyFileWithPermissions proc <#copyFileWithPermissions,string,string>`_
  ## * `removeDir proc <#removeDir,string>`_
  ## * `moveDir proc <#moveDir,string,string>`_
  ## * `existsOrCreateDir proc <#existsOrCreateDir,string>`_
  ## * `createDir proc <#createDir,string>`_
  createDir(dest)
  when not defined(Windows):
    try:
      setFilePermissions(dest, getFilePermissions(source))
    except:
      if not ignorePermissionErrors:
        raise
  for kind, path in walkDir(source):
    var noSource = splitPath(path).tail
    case kind
    of pcFile:
      copyFileWithPermissions(path, dest / noSource, ignorePermissionErrors)
    of pcDir:
      copyDirWithPermissions(path, dest / noSource, ignorePermissionErrors)
    else: discard

proc inclFilePermissions*(filename: string,
                          permissions: set[FilePermission]) {.
  rtl, extern: "nos$1", tags: [ReadDirEffect, WriteDirEffect], noNimScript.} =
  ## A convenience proc for:
  ##
  ## .. code-block:: nim
  ##   setFilePermissions(filename, getFilePermissions(filename)+permissions)
  setFilePermissions(filename, getFilePermissions(filename)+permissions)

proc exclFilePermissions*(filename: string,
                          permissions: set[FilePermission]) {.
  rtl, extern: "nos$1", tags: [ReadDirEffect, WriteDirEffect], noNimScript.} =
  ## A convenience proc for:
  ##
  ## .. code-block:: nim
  ##   setFilePermissions(filename, getFilePermissions(filename)-permissions)
  setFilePermissions(filename, getFilePermissions(filename)-permissions)

proc expandSymlink*(symlinkPath: string): string {.noNimScript.} =
  ## Returns a string representing the path to which the symbolic link points.
  ##
  ## On Windows this is a noop, ``symlinkPath`` is simply returned.
  ##
  ## See also:
  ## * `createSymlink proc <#createSymlink,string,string>`_
  when defined(windows):
    result = symlinkPath
  else:
    result = newString(256)
    var len = readlink(symlinkPath, result, 256)
    if len < 0:
      raiseOSError(osLastError())
    if len > 256:
      result = newString(len+1)
      len = readlink(symlinkPath, result, len)
    setLen(result, len)

proc parseCmdLine*(c: string): seq[string] {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Splits a `command line`:idx: into several components.
  ##
  ## **Note**: This proc is only occasionally useful, better use the
  ## `parseopt module <parseopt.html>`_.
  ##
  ## On Windows, it uses the `following parsing rules
  ## <http://msdn.microsoft.com/en-us/library/17w5ykft.aspx>`_:
  ##
  ## * Arguments are delimited by white space, which is either a space or a tab.
  ## * The caret character (^) is not recognized as an escape character or
  ##   delimiter. The character is handled completely by the command-line parser
  ##   in the operating system before being passed to the argv array in the
  ##   program.
  ## * A string surrounded by double quotation marks ("string") is interpreted
  ##   as a single argument, regardless of white space contained within. A
  ##   quoted string can be embedded in an argument.
  ## * A double quotation mark preceded by a backslash (\") is interpreted as a
  ##   literal double quotation mark character (").
  ## * Backslashes are interpreted literally, unless they immediately precede
  ##   a double quotation mark.
  ## * If an even number of backslashes is followed by a double quotation mark,
  ##   one backslash is placed in the argv array for every pair of backslashes,
  ##   and the double quotation mark is interpreted as a string delimiter.
  ## * If an odd number of backslashes is followed by a double quotation mark,
  ##   one backslash is placed in the argv array for every pair of backslashes,
  ##   and the double quotation mark is "escaped" by the remaining backslash,
  ##   causing a literal double quotation mark (") to be placed in argv.
  ##
  ## On Posix systems, it uses the following parsing rules:
  ## Components are separated by whitespace unless the whitespace
  ## occurs within ``"`` or ``'`` quotes.
  ##
  ## See also:
  ## * `parseopt module <parseopt.html>`_
  ## * `paramCount proc <#paramCount>`_
  ## * `paramStr proc <#paramStr,int>`_
  ## * `commandLineParams proc <#commandLineParams>`_

  result = @[]
  var i = 0
  var a = ""
  while true:
    setLen(a, 0)
    # eat all delimiting whitespace
    while i < c.len and c[i] in {' ', '\t', '\l', '\r'}: inc(i)
    if i >= c.len: break
    when defined(windows):
      # parse a single argument according to the above rules:
      var inQuote = false
      while i < c.len:
        case c[i]
        of '\\':
          var j = i
          while j < c.len and c[j] == '\\': inc(j)
          if j < c.len and c[j] == '"':
            for k in 1..(j-i) div 2: a.add('\\')
            if (j-i) mod 2 == 0:
              i = j
            else:
              a.add('"')
              i = j+1
          else:
            a.add(c[i])
            inc(i)
        of '"':
          inc(i)
          if not inQuote: inQuote = true
          elif i < c.len and c[i] == '"':
            a.add(c[i])
            inc(i)
          else:
            inQuote = false
            break
        of ' ', '\t':
          if not inQuote: break
          a.add(c[i])
          inc(i)
        else:
          a.add(c[i])
          inc(i)
    else:
      case c[i]
      of '\'', '\"':
        var delim = c[i]
        inc(i) # skip ' or "
        while i < c.len and c[i] != delim:
          add a, c[i]
          inc(i)
        if i < c.len: inc(i)
      else:
        while i < c.len and c[i] > ' ':
          add(a, c[i])
          inc(i)
    add(result, a)

when defined(nimdoc):
  # Common forward declaration docstring block for parameter retrieval procs.
  proc paramCount*(): int {.tags: [ReadIOEffect].} =
    ## Returns the number of `command line arguments`:idx: given to the
    ## application.
    ##
    ## Unlike `argc`:idx: in C, if your binary was called without parameters this
    ## will return zero.
    ## You can query each individual paramater with `paramStr proc <#paramStr,int>`_
    ## or retrieve all of them in one go with `commandLineParams proc
    ## <#commandLineParams>`_.
    ##
    ## **Availability**: When generating a dynamic library (see `--app:lib`) on
    ## Posix this proc is not defined.
    ## Test for availability using `declared() <system.html#declared,untyped>`_.
    ##
    ## See also:
    ## * `parseopt module <parseopt.html>`_
    ## * `parseCmdLine proc <#parseCmdLine,string>`_
    ## * `paramStr proc <#paramStr,int>`_
    ## * `commandLineParams proc <#commandLineParams>`_
    ##
    ## **Examples:**
    ##
    ## .. code-block:: nim
    ##   when declared(paramCount):
    ##     # Use paramCount() here
    ##   else:
    ##     # Do something else!

  proc paramStr*(i: int): TaintedString {.tags: [ReadIOEffect].} =
    ## Returns the `i`-th `command line argument`:idx: given to the application.
    ##
    ## `i` should be in the range `1..paramCount()`, the `IndexError`
    ## exception will be raised for invalid values.  Instead of iterating over
    ## `paramCount() <#paramCount>`_ with this proc you can call the
    ## convenience `commandLineParams() <#commandLineParams>`_.
    ##
    ## Similarly to `argv`:idx: in C,
    ## it is possible to call ``paramStr(0)`` but this will return OS specific
    ## contents (usually the name of the invoked executable). You should avoid
    ## this and call `getAppFilename() <#getAppFilename>`_ instead.
    ##
    ## **Availability**: When generating a dynamic library (see `--app:lib`) on
    ## Posix this proc is not defined.
    ## Test for availability using `declared() <system.html#declared,untyped>`_.
    ##
    ## See also:
    ## * `parseopt module <parseopt.html>`_
    ## * `parseCmdLine proc <#parseCmdLine,string>`_
    ## * `paramCount proc <#paramCount>`_
    ## * `commandLineParams proc <#commandLineParams>`_
    ## * `getAppFilename proc <#getAppFilename>`_
    ##
    ## **Examples:**
    ##
    ## .. code-block:: nim
    ##   when declared(paramStr):
    ##     # Use paramStr() here
    ##   else:
    ##     # Do something else!

elif defined(nintendoswitch) or weirdTarget:
  proc paramStr*(i: int): TaintedString {.tags: [ReadIOEffect].} =
    raise newException(OSError, "paramStr is not implemented on Nintendo Switch")

  proc paramCount*(): int {.tags: [ReadIOEffect].} =
    raise newException(OSError, "paramCount is not implemented on Nintendo Switch")

elif defined(windows):
  # Since we support GUI applications with Nim, we sometimes generate
  # a WinMain entry proc. But a WinMain proc has no access to the parsed
  # command line arguments. The way to get them differs. Thus we parse them
  # ourselves. This has the additional benefit that the program's behaviour
  # is always the same -- independent of the used C compiler.
  var
    ownArgv {.threadvar.}: seq[string]
    ownParsedArgv {.threadvar.}: bool

  proc paramCount*(): int {.rtl, extern: "nos$1", tags: [ReadIOEffect].} =
    # Docstring in nimdoc block.
    if not ownParsedArgv:
      ownArgv = parseCmdLine($getCommandLine())
      ownParsedArgv = true
    result = ownArgv.len-1

  proc paramStr*(i: int): TaintedString {.rtl, extern: "nos$1",
    tags: [ReadIOEffect].} =
    # Docstring in nimdoc block.
    if not ownParsedArgv:
      ownArgv = parseCmdLine($getCommandLine())
      ownParsedArgv = true
    if i < ownArgv.len and i >= 0: return TaintedString(ownArgv[i])
    raise newException(IndexError, formatErrorIndexBound(i, ownArgv.len-1))

elif defined(genode):
  proc paramStr*(i: int): TaintedString =
    raise newException(OSError, "paramStr is not implemented on Genode")

  proc paramCount*(): int =
    raise newException(OSError, "paramCount is not implemented on Genode")

elif not defined(createNimRtl) and
  not(defined(posix) and appType == "lib"):
  # On Posix, there is no portable way to get the command line from a DLL.
  var
    cmdCount {.importc: "cmdCount".}: cint
    cmdLine {.importc: "cmdLine".}: cstringArray

  proc paramStr*(i: int): TaintedString {.tags: [ReadIOEffect].} =
    # Docstring in nimdoc block.
    if i < cmdCount and i >= 0: return TaintedString($cmdLine[i])
    raise newException(IndexError, formatErrorIndexBound(i, cmdCount-1))

  proc paramCount*(): int {.tags: [ReadIOEffect].} =
    # Docstring in nimdoc block.
    result = cmdCount-1

when declared(paramCount) or defined(nimdoc):
  proc commandLineParams*(): seq[TaintedString] =
    ## Convenience proc which returns the command line parameters.
    ##
    ## This returns **only** the parameters. If you want to get the application
    ## executable filename, call `getAppFilename() <#getAppFilename>`_.
    ##
    ## **Availability**: On Posix there is no portable way to get the command
    ## line from a DLL and thus the proc isn't defined in this environment. You
    ## can test for its availability with `declared()
    ## <system.html#declared,untyped>`_.
    ##
    ## See also:
    ## * `parseopt module <parseopt.html>`_
    ## * `parseCmdLine proc <#parseCmdLine,string>`_
    ## * `paramCount proc <#paramCount>`_
    ## * `paramStr proc <#paramStr,int>`_
    ## * `getAppFilename proc <#getAppFilename>`_
    ##
    ## **Examples:**
    ##
    ## .. code-block:: nim
    ##   when declared(commandLineParams):
    ##     # Use commandLineParams() here
    ##   else:
    ##     # Do something else!
    result = @[]
    for i in 1..paramCount():
      result.add(paramStr(i))

when not weirdTarget and (defined(freebsd) or defined(dragonfly)):
  proc sysctl(name: ptr cint, namelen: cuint, oldp: pointer, oldplen: ptr csize,
              newp: pointer, newplen: csize): cint
       {.importc: "sysctl",header: """#include <sys/types.h>
                                      #include <sys/sysctl.h>"""}
  const
    CTL_KERN = 1
    KERN_PROC = 14
    MAX_PATH = 1024

  when defined(freebsd):
    const KERN_PROC_PATHNAME = 12
  else:
    const KERN_PROC_PATHNAME = 9

  proc getApplFreebsd(): string =
    var pathLength = csize(MAX_PATH)
    result = newString(pathLength)
    var req = [CTL_KERN.cint, KERN_PROC.cint, KERN_PROC_PATHNAME.cint, -1.cint]
    while true:
      let res = sysctl(addr req[0], 4, cast[pointer](addr result[0]),
                       addr pathLength, nil, 0)
      if res < 0:
        let err = osLastError()
        if err.int32 == ENOMEM:
          result = newString(pathLength)
        else:
          result.setLen(0) # error!
          break
      else:
        result.setLen(pathLength)
        break

when not weirdTarget and (defined(linux) or defined(solaris) or defined(bsd) or defined(aix)):
  proc getApplAux(procPath: string): string =
    result = newString(256)
    var len = readlink(procPath, result, 256)
    if len > 256:
      result = newString(len+1)
      len = readlink(procPath, result, len)
    setLen(result, len)

when not (defined(windows) or defined(macosx) or weirdTarget):
  proc getApplHeuristic(): string =
    when declared(paramStr):
      result = string(paramStr(0))
      # POSIX guaranties that this contains the executable
      # as it has been executed by the calling process
      if len(result) > 0 and result[0] != DirSep: # not an absolute path?
        # iterate over any path in the $PATH environment variable
        for p in split(string(getEnv("PATH")), {PathSep}):
          var x = joinPath(p, result)
          if existsFile(x): return x
    else:
      result = ""

when defined(macosx):
  type
    cuint32* {.importc: "unsigned int", nodecl.} = int
    ## This is the same as the type ``uint32_t`` in *C*.

  # a really hacky solution: since we like to include 2 headers we have to
  # define two procs which in reality are the same
  proc getExecPath1(c: cstring, size: var cuint32) {.
    importc: "_NSGetExecutablePath", header: "<sys/param.h>".}
  proc getExecPath2(c: cstring, size: var cuint32): bool {.
    importc: "_NSGetExecutablePath", header: "<mach-o/dyld.h>".}

when defined(haiku):
  const
    PATH_MAX = 1024
    B_FIND_PATH_IMAGE_PATH = 1000

  proc find_path(codePointer: pointer, baseDirectory: cint, subPath: cstring,
                 pathBuffer: cstring, bufferSize: csize): int32
                {.importc, header: "<FindDirectory.h>".}

  proc getApplHaiku(): string =
    result = newString(PATH_MAX)

    if find_path(nil, B_FIND_PATH_IMAGE_PATH, nil, result, PATH_MAX) == 0:
      let realLen = len(cstring(result))
      setLen(result, realLen)
    else:
      result = ""

proc getAppFilename*(): string {.rtl, extern: "nos$1", tags: [ReadIOEffect], noNimScript.} =
  ## Returns the filename of the application's executable.
  ## This proc will resolve symlinks.
  ##
  ## See also:
  ## * `getAppDir proc <#getAppDir>`_
  ## * `getCurrentCompilerExe proc <#getCurrentCompilerExe>`_

  # Linux: /proc/<pid>/exe
  # Solaris:
  # /proc/<pid>/object/a.out (filename only)
  # /proc/<pid>/path/a.out (complete pathname)
  when defined(windows):
    var bufsize = int32(MAX_PATH)
    when useWinUnicode:
      var buf = newWideCString("", bufsize)
      while true:
        var L = getModuleFileNameW(0, buf, bufsize)
        if L == 0'i32:
          result = "" # error!
          break
        elif L > bufsize:
          buf = newWideCString("", L)
          bufsize = L
        else:
          result = buf$L
          break
    else:
      result = newString(bufsize)
      while true:
        var L = getModuleFileNameA(0, result, bufsize)
        if L == 0'i32:
          result = "" # error!
          break
        elif L > bufsize:
          result = newString(L)
          bufsize = L
        else:
          setLen(result, L)
          break
  elif defined(macosx):
    var size: cuint32
    getExecPath1(nil, size)
    result = newString(int(size))
    if getExecPath2(result, size):
      result = "" # error!
    if result.len > 0:
      result = result.expandFilename
  else:
    when defined(linux) or defined(aix) or defined(netbsd):
      result = getApplAux("/proc/self/exe")
    elif defined(solaris):
      result = getApplAux("/proc/" & $getpid() & "/path/a.out")
    elif defined(genode) or defined(nintendoswitch):
      raiseOSError(OSErrorCode(-1), "POSIX command line not supported")
    elif defined(freebsd) or defined(dragonfly):
      result = getApplFreebsd()
    elif defined(haiku):
      result = getApplHaiku()
    # little heuristic that may work on other POSIX-like systems:
    if result.len == 0:
      result = getApplHeuristic()

proc getAppDir*(): string {.rtl, extern: "nos$1", tags: [ReadIOEffect], noNimScript.} =
  ## Returns the directory of the application's executable.
  ##
  ## See also:
  ## * `getAppFilename proc <#getAppFilename>`_
  result = splitFile(getAppFilename()).dir

proc sleep*(milsecs: int) {.rtl, extern: "nos$1", tags: [TimeEffect], noNimScript.} =
  ## Sleeps `milsecs` milliseconds.
  when defined(windows):
    winlean.sleep(int32(milsecs))
  else:
    var a, b: Timespec
    a.tv_sec = posix.Time(milsecs div 1000)
    a.tv_nsec = (milsecs mod 1000) * 1000 * 1000
    discard posix.nanosleep(a, b)

proc getFileSize*(file: string): BiggestInt {.rtl, extern: "nos$1",
  tags: [ReadIOEffect], noNimScript.} =
  ## Returns the file size of `file` (in bytes). ``OSError`` is
  ## raised in case of an error.
  when defined(windows):
    var a: WIN32_FIND_DATA
    var resA = findFirstFile(file, a)
    if resA == -1: raiseOSError(osLastError())
    result = rdFileSize(a)
    findClose(resA)
  else:
    var f: File
    if open(f, file):
      result = getFileSize(f)
      close(f)
    else: raiseOSError(osLastError())

when defined(Windows) or weirdTarget:
  type
    DeviceId* = int32
    FileId* = int64
else:
  type
    DeviceId* = Dev
    FileId* = Ino

type
  FileInfo* = object
    ## Contains information associated with a file object.
    ##
    ## See also:
    ## * `getFileInfo(handle) proc <#getFileInfo,FileHandle>`_
    ## * `getFileInfo(file) proc <#getFileInfo,File>`_
    ## * `getFileInfo(path) proc <#getFileInfo,string>`_
    id*: tuple[device: DeviceId, file: FileId] ## Device and file id.
    kind*: PathComponent              ## Kind of file object - directory, symlink, etc.
    size*: BiggestInt                 ## Size of file.
    permissions*: set[FilePermission] ## File permissions
    linkCount*: BiggestInt            ## Number of hard links the file object has.
    lastAccessTime*: times.Time       ## Time file was last accessed.
    lastWriteTime*: times.Time        ## Time file was last modified/written to.
    creationTime*: times.Time         ## Time file was created. Not supported on all systems!

template rawToFormalFileInfo(rawInfo, path, formalInfo): untyped =
  ## Transforms the native file info structure into the one nim uses.
  ## 'rawInfo' is either a 'BY_HANDLE_FILE_INFORMATION' structure on Windows,
  ## or a 'Stat' structure on posix
  when defined(Windows):
    template merge(a, b): untyped = a or (b shl 32)
    formalInfo.id.device = rawInfo.dwVolumeSerialNumber
    formalInfo.id.file = merge(rawInfo.nFileIndexLow, rawInfo.nFileIndexHigh)
    formalInfo.size = merge(rawInfo.nFileSizeLow, rawInfo.nFileSizeHigh)
    formalInfo.linkCount = rawInfo.nNumberOfLinks
    formalInfo.lastAccessTime = fromWinTime(rdFileTime(rawInfo.ftLastAccessTime))
    formalInfo.lastWriteTime = fromWinTime(rdFileTime(rawInfo.ftLastWriteTime))
    formalInfo.creationTime = fromWinTime(rdFileTime(rawInfo.ftCreationTime))

    # Retrieve basic permissions
    if (rawInfo.dwFileAttributes and FILE_ATTRIBUTE_READONLY) != 0'i32:
      formalInfo.permissions = {fpUserExec, fpUserRead, fpGroupExec,
                                fpGroupRead, fpOthersExec, fpOthersRead}
    else:
      result.permissions = {fpUserExec..fpOthersRead}

    # Retrieve basic file kind
    result.kind = pcFile
    if (rawInfo.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) != 0'i32:
      formalInfo.kind = pcDir
    if (rawInfo.dwFileAttributes and FILE_ATTRIBUTE_REPARSE_POINT) != 0'i32:
      formalInfo.kind = succ(result.kind)

  else:
    template checkAndIncludeMode(rawMode, formalMode: untyped) =
      if (rawInfo.st_mode and rawMode) != 0'i32:
        formalInfo.permissions.incl(formalMode)
    formalInfo.id = (rawInfo.st_dev, rawInfo.st_ino)
    formalInfo.size = rawInfo.st_size
    formalInfo.linkCount = rawInfo.st_Nlink.BiggestInt
    formalInfo.lastAccessTime = rawInfo.st_atim.toTime
    formalInfo.lastWriteTime = rawInfo.st_mtim.toTime
    formalInfo.creationTime = rawInfo.st_ctim.toTime

    result.permissions = {}
    checkAndIncludeMode(S_IRUSR, fpUserRead)
    checkAndIncludeMode(S_IWUSR, fpUserWrite)
    checkAndIncludeMode(S_IXUSR, fpUserExec)

    checkAndIncludeMode(S_IRGRP, fpGroupRead)
    checkAndIncludeMode(S_IWGRP, fpGroupWrite)
    checkAndIncludeMode(S_IXGRP, fpGroupExec)

    checkAndIncludeMode(S_IROTH, fpOthersRead)
    checkAndIncludeMode(S_IWOTH, fpOthersWrite)
    checkAndIncludeMode(S_IXOTH, fpOthersExec)

    formalInfo.kind = pcFile
    if S_ISDIR(rawInfo.st_mode):
      formalInfo.kind = pcDir
    elif S_ISLNK(rawInfo.st_mode):
      assert(path != "") # symlinks can't occur for file handles
      formalInfo.kind = getSymlinkFileKind(path)

when defined(js):
  when not declared(FileHandle):
    type FileHandle = distinct int32
  when not declared(File):
    type File = object

proc getFileInfo*(handle: FileHandle): FileInfo {.noNimScript.} =
  ## Retrieves file information for the file object represented by the given
  ## handle.
  ##
  ## If the information cannot be retrieved, such as when the file handle
  ## is invalid, `OSError` is raised.
  ##
  ## See also:
  ## * `getFileInfo(file) proc <#getFileInfo,File>`_
  ## * `getFileInfo(path) proc <#getFileInfo,string>`_

  # Done: ID, Kind, Size, Permissions, Link Count
  when defined(Windows):
    var rawInfo: BY_HANDLE_FILE_INFORMATION
    # We have to use the super special '_get_osfhandle' call (wrapped above)
    # To transform the C file descripter to a native file handle.
    var realHandle = get_osfhandle(handle)
    if getFileInformationByHandle(realHandle, addr rawInfo) == 0:
      raiseOSError(osLastError())
    rawToFormalFileInfo(rawInfo, "", result)
  else:
    var rawInfo: Stat
    if fstat(handle, rawInfo) < 0'i32:
      raiseOSError(osLastError())
    rawToFormalFileInfo(rawInfo, "", result)

proc getFileInfo*(file: File): FileInfo {.noNimScript.} =
  ## Retrieves file information for the file object.
  ##
  ## See also:
  ## * `getFileInfo(handle) proc <#getFileInfo,FileHandle>`_
  ## * `getFileInfo(path) proc <#getFileInfo,string>`_
  if file.isNil:
    raise newException(IOError, "File is nil")
  result = getFileInfo(file.getFileHandle())

proc getFileInfo*(path: string, followSymlink = true): FileInfo {.noNimScript.} =
  ## Retrieves file information for the file object pointed to by `path`.
  ##
  ## Due to intrinsic differences between operating systems, the information
  ## contained by the returned `FileInfo object <#FileInfo>`_ will be slightly
  ## different across platforms, and in some cases, incomplete or inaccurate.
  ##
  ## When `followSymlink` is true (default), symlinks are followed and the
  ## information retrieved is information related to the symlink's target.
  ## Otherwise, information on the symlink itself is retrieved.
  ##
  ## If the information cannot be retrieved, such as when the path doesn't
  ## exist, or when permission restrictions prevent the program from retrieving
  ## file information, `OSError` is raised.
  ##
  ## See also:
  ## * `getFileInfo(handle) proc <#getFileInfo,FileHandle>`_
  ## * `getFileInfo(file) proc <#getFileInfo,File>`_
  when defined(Windows):
    var
      handle = openHandle(path, followSymlink)
      rawInfo: BY_HANDLE_FILE_INFORMATION
    if handle == INVALID_HANDLE_VALUE:
      raiseOSError(osLastError())
    if getFileInformationByHandle(handle, addr rawInfo) == 0:
      raiseOSError(osLastError())
    rawToFormalFileInfo(rawInfo, path, result)
    discard closeHandle(handle)
  else:
    var rawInfo: Stat
    if followSymlink:
      if stat(path, rawInfo) < 0'i32:
        raiseOSError(osLastError())
    else:
      if lstat(path, rawInfo) < 0'i32:
        raiseOSError(osLastError())
    rawToFormalFileInfo(rawInfo, path, result)

proc isHidden*(path: string): bool {.noNimScript.} =
  ## Determines whether ``path`` is hidden or not, using `this
  ## reference <https://en.wikipedia.org/wiki/Hidden_file_and_hidden_directory>`_.
  ##
  ## On Windows: returns true if it exists and its "hidden" attribute is set.
  ##
  ## On posix: returns true if ``lastPathPart(path)`` starts with ``.`` and is
  ## not ``.`` or ``..``.
  ##
  ## **Note**: paths are not normalized to determine `isHidden`.
  runnableExamples:
    when defined(posix):
      assert ".foo".isHidden
      assert not ".foo/bar".isHidden
      assert not ".".isHidden
      assert not "..".isHidden
      assert not "".isHidden
      assert ".foo/".isHidden

  when defined(Windows):
    when useWinUnicode:
      wrapUnary(attributes, getFileAttributesW, path)
    else:
      var attributes = getFileAttributesA(path)
    if attributes != -1'i32:
      result = (attributes and FILE_ATTRIBUTE_HIDDEN) != 0'i32
  else:
    let fileName = lastPathPart(path)
    result = len(fileName) >= 2 and fileName[0] == '.' and fileName != ".."

proc getCurrentProcessId*(): int {.noNimScript.} =
  ## Return current process ID.
  ##
  ## See also:
  ## * `osproc.processID(p: Process) <osproc.html#processID,Process>`_
  when defined(windows):
    proc GetCurrentProcessId(): DWORD {.stdcall, dynlib: "kernel32",
                                        importc: "GetCurrentProcessId".}
    result = GetCurrentProcessId().int
  else:
    result = getpid()

{.pop.}

proc setLastModificationTime*(file: string, t: times.Time) {.noNimScript.} =
  ## Sets the `file`'s last modification time. `OSError` is raised in case of
  ## an error.
  when defined(posix):
    let unixt = posix.Time(t.toUnix)
    let micro = convert(Nanoseconds, Microseconds, t.nanosecond)
    var timevals = [Timeval(tv_sec: unixt, tv_usec: micro),
      Timeval(tv_sec: unixt, tv_usec: micro)] # [last access, last modification]
    if utimes(file, timevals.addr) != 0: raiseOSError(osLastError())
  else:
    let h = openHandle(path = file, writeAccess = true)
    if h == INVALID_HANDLE_VALUE: raiseOSError(osLastError())
    var ft = t.toWinTime.toFILETIME
    let res = setFileTime(h, nil, nil, ft.addr)
    discard h.closeHandle
    if res == 0'i32: raiseOSError(osLastError())


when isMainModule:
  assert quoteShellWindows("aaa") == "aaa"
  assert quoteShellWindows("aaa\"") == "aaa\\\""
  assert quoteShellWindows("") == "\"\""

  assert quoteShellPosix("aaa") == "aaa"
  assert quoteShellPosix("aaa a") == "'aaa a'"
  assert quoteShellPosix("") == "''"
  assert quoteShellPosix("a'a") == "'a'\"'\"'a'"

  when defined(posix):
    assert quoteShell("") == "''"

  block normalizePathEndTest:
    # handle edge cases correctly: shouldn't affect whether path is
    # absolute/relative
    doAssert "".normalizePathEnd(true) == ""
    doAssert "".normalizePathEnd(false) == ""
    doAssert "/".normalizePathEnd(true) == $DirSep
    doAssert "/".normalizePathEnd(false) == $DirSep

    when defined(posix):
      doAssert "//".normalizePathEnd(false) == "/"
      doAssert "foo.bar//".normalizePathEnd == "foo.bar"
      doAssert "bar//".normalizePathEnd(trailingSep = true) == "bar/"
    when defined(Windows):
      doAssert r"C:\foo\\".normalizePathEnd == r"C:\foo"
      doAssert r"C:\foo".normalizePathEnd(trailingSep = true) == r"C:\foo\"
      # this one is controversial: we could argue for returning `D:\` instead,
      # but this is simplest.
      doAssert r"D:\".normalizePathEnd == r"D:"
      doAssert r"E:/".normalizePathEnd(trailingSep = true) == r"E:\"
      doAssert "/".normalizePathEnd == r"\"
