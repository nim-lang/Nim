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

runnableExamples:
  let myFile = "/path/to/my/file.nim"
  assert splitPath(myFile) == (head: "/path/to/my", tail: "file.nim")
  when defined(posix):
    assert parentDir(myFile) == "/path/to/my"
  assert splitFile(myFile) == (dir: "/path/to/my", name: "file", ext: ".nim")
  assert myFile.changeFileExt("c") == "/path/to/my/file.c"

## **See also:**
## * `osproc module <osproc.html>`_ for process communication beyond
##   `execShellCmd proc <#execShellCmd,string>`_
## * `parseopt module <parseopt.html>`_ for command-line parser beyond
##   `parseCmdLine proc <#parseCmdLine,string>`_
## * `uri module <uri.html>`_
## * `distros module <distros.html>`_
## * `dynlib module <dynlib.html>`_
## * `streams module <streams.html>`_

include system/inclrtl
import std/private/since

import strutils, pathnorm

const weirdTarget = defined(nimscript) or defined(js)

since (1, 1):
  const
    invalidFilenameChars* = {'/', '\\', ':', '*', '?', '"', '<', '>', '|', '^', '\0'} ## \
    ## Characters that may produce invalid filenames across Linux, Windows, Mac, etc.
    ## You can check if your filename contains these char and strip them for safety.
    ## Mac bans ``':'``, Linux bans ``'/'``, Windows bans all others.
    invalidFilenames* = [
      "CON", "PRN", "AUX", "NUL",
      "COM0", "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9",
      "LPT0", "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9"] ## \
    ## Filenames that may be invalid across Linux, Windows, Mac, etc.
    ## You can check if your filename match these and rename it for safety
    ## (Currently all invalid filenames are from Windows only).

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

when weirdTarget:
  {.pragma: noWeirdTarget, error: "this proc is not available on the NimScript/js target".}
else:
  {.pragma: noWeirdTarget.}

when defined(nimscript):
  # for procs already defined in scriptconfig.nim
  template noNimJs(body): untyped = discard
elif defined(js):
  {.pragma: noNimJs, error: "this proc is not available on the js target".}
else:
  {.pragma: noNimJs.}

proc normalizePathAux(path: var string){.inline, raises: [], noSideEffect.}

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

proc absolutePathInternal(path: string): string {.gcsafe.}

proc normalizePathEnd(path: var string, trailingSep = false) =
  ## Ensures ``path`` has exactly 0 or 1 trailing `DirSep`, depending on
  ## ``trailingSep``, and taking care of edge cases: it preservers whether
  ## a path is absolute or relative, and makes sure trailing sep is `DirSep`,
  ## not `AltSep`. Trailing `/.` are compressed, see examples.
  if path.len == 0: return
  var i = path.len
  while i >= 1:
    if path[i-1] in {DirSep, AltSep}: dec(i)
    elif path[i-1] == '.' and i >= 2 and path[i-2] in {DirSep, AltSep}: dec(i)
    else: break
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
  ## outplace overload
  runnableExamples:
    when defined(posix):
      assert normalizePathEnd("/lib//.//", trailingSep = true) == "/lib/"
      assert normalizePathEnd("lib/./.", trailingSep = false) == "lib"
      assert normalizePathEnd(".//./.", trailingSep = false) == "."
      assert normalizePathEnd("", trailingSep = true) == "" # not / !
      assert normalizePathEnd("/", trailingSep = false) == "/" # not "" !
  result = path
  result.normalizePathEnd(trailingSep)

since((1, 1)):
  export normalizePathEnd

template endsWith(a: string, b: set[char]): bool =
  a.len > 0 and a[^1] in b

proc joinPathImpl(result: var string, state: var int, tail: string) =
  let trailingSep = tail.endsWith({DirSep, AltSep}) or tail.len == 0 and result.endsWith({DirSep, AltSep})
  normalizePathEnd(result, trailingSep=false)
  addNormalizePath(tail, result, state, DirSep)
  normalizePathEnd(result, trailingSep=trailingSep)

proc joinPath*(head, tail: string): string {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Joins two directory names to one.
  ##
  ## returns normalized path concatenation of `head` and `tail`, preserving
  ## whether or not `tail` has a trailing slash (or, if tail if empty, whether
  ## head has one).
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
      assert joinPath("usr", "lib/") == "usr/lib/"
      assert joinPath("usr", "") == "usr"
      assert joinPath("usr/", "") == "usr/"
      assert joinPath("", "") == ""
      assert joinPath("", "lib") == "lib"
      assert joinPath("", "/lib") == "/lib"
      assert joinPath("usr/", "/lib") == "usr/lib"
      assert joinPath("usr/lib", "../bin") == "usr/bin"

  result = newStringOfCap(head.len + tail.len)
  var state = 0
  joinPathImpl(result, state, head)
  joinPathImpl(result, state, tail)
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
    joinPathImpl(result, state, parts[i])

proc `/`*(head, tail: string): string {.noSideEffect, inline.} =
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
      assert "usr" / "" == "usr"
      assert "" / "lib" == "lib"
      assert "" / "/lib" == "/lib"
      assert "usr/" / "/lib/" == "usr/lib/"
      assert "usr" / "lib" / "../bin" == "usr/bin"

  result = joinPath(head, tail)

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
    assert splitPath("/bin/") == ("/bin", "")
    when (NimMajor, NimMinor) <= (1, 0):
      assert splitPath("/bin") == ("", "bin")
    else:
      assert splitPath("/bin") == ("/", "bin")
    assert splitPath("bin") == ("", "bin")
    assert splitPath("") == ("", "")

  var sepPos = -1
  for i in countdown(len(path)-1, 0):
    if path[i] in {DirSep, AltSep}:
      sepPos = i
      break
  if sepPos >= 0:
    result.head = substr(path, 0,
      when (NimMajor, NimMinor) <= (1, 0):
        sepPos-1
      else:
        if likely(sepPos >= 1): sepPos-1 else: 0
    )
    result.tail = substr(path, sepPos+1)
  else:
    result.head = ""
    result.tail = path

proc isAbsolute*(path: string): bool {.rtl, noSideEffect, extern: "nos$1", raises: [].} =
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
  elif defined(posix) or defined(js):
    # `or defined(js)` wouldn't be needed pending https://github.com/nim-lang/Nim/issues/13469
    # This works around the problem for posix, but windows is still broken with nim js -d:nodejs
    result = path[0] == '/'
  else:
    doAssert false # if ever hits here, adapt as needed

when FileSystemCaseSensitive:
  template `!=?`(a, b: char): bool = a != b
else:
  template `!=?`(a, b: char): bool = toLowerAscii(a) != toLowerAscii(b)

when doslikeFileSystem:
  proc isAbsFromCurrentDrive(path: string): bool {.noSideEffect, raises: [].} =
    ## An absolute path from the root of the current drive (e.g. "\foo")
    path.len > 0 and
    (path[0] == AltSep or
     (path[0] == DirSep and
      (path.len == 1 or path[1] notin {DirSep, AltSep, ':'})))

  proc isUNCPrefix(path: string): bool {.noSideEffect, raises: [].} =
    path[0] == DirSep and path[1] == DirSep

  proc sameRoot(path1, path2: string): bool {.noSideEffect, raises: [].} =
    ## Return true if path1 and path2 have a same root.
    ##
    ## Detail of windows path formats:
    ## https://docs.microsoft.com/en-us/dotnet/standard/io/file-path-formats

    assert(isAbsolute(path1))
    assert(isAbsolute(path2))

    let
      len1 = path1.len
      len2 = path2.len
    assert(len1 != 0 and len2 != 0)

    if isAbsFromCurrentDrive(path1) and isAbsFromCurrentDrive(path2):
      return true
    elif len1 == 1 or len2 == 1:
      return false
    else:
      if path1[1] == ':' and path2[1] == ':':
        return path1[0].toLowerAscii() == path2[0].toLowerAscii()
      else:
        var
          p1, p2: PathIter
          pp1 = next(p1, path1)
          pp2 = next(p2, path2)
        if pp1[1] - pp1[0] == 1 and pp2[1] - pp2[0] == 1 and
           isUNCPrefix(path1) and isUNCPrefix(path2):
          #UNC
          var h = 0
          while p1.hasNext(path1) and p2.hasNext(path2) and h < 2:
            pp1 = next(p1, path1)
            pp2 = next(p2, path2)
            let diff = pp1[1] - pp1[0]
            if diff != pp2[1] - pp2[0]:
              return false
            for i in 0..diff:
              if path1[i + pp1[0]] !=? path2[i + pp2[0]]:
                return false
            inc h
          return h == 2
        else:
          return false

proc relativePath*(path, base: string, sep = DirSep): string {.
  rtl, extern: "nos$1".} =
  ## Converts `path` to a path relative to `base`.
  ##
  ## The `sep` (default: `DirSep <#DirSep>`_) is used for the path normalizations,
  ## this can be useful to ensure the relative path only contains `'/'`
  ## so that it can be used for URL constructions.
  ##
  ## On windows, if a root of `path` and a root of `base` are different,
  ## returns `path` as is because it is impossible to make a relative path.
  ## That means an absolute path can be returned.
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
    assert relativePath("foo", ".", '/') == "foo"
    assert relativePath("foo", "foo", '/') == "."

  if path.len == 0: return ""
  var base = if base == ".": "" else: base
  var path = path
  path.normalizePathAux
  base.normalizePathAux
  let a1 = isAbsolute(path)
  let a2 = isAbsolute(base)
  if a1 and not a2:
    base = absolutePathInternal(base)
  elif a2 and not a1:
    path = absolutePathInternal(path)

  when doslikeFileSystem:
    if isAbsolute(path) and isAbsolute(base):
      if not sameRoot(path, base):
        return path

  var f = default PathIter
  var b = default PathIter
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

  when not defined(nimOldRelativePathBehavior):
    if result.len == 0: result.add "."

proc isRelativeTo*(path: string, base: string): bool {.since: (1, 1).} =
  ## Returns true if `path` is relative to `base`.
  runnableExamples:
    doAssert isRelativeTo("./foo//bar", "foo")
    doAssert isRelativeTo("foo/bar", ".")
    doAssert isRelativeTo("/foo/bar.nim", "/foo/bar.nim")
    doAssert not isRelativeTo("foo/bar.nims", "foo/bar.nim")
  let path = path.normalizePath
  let base = base.normalizePath
  let ret = relativePath(path, base)
  result = path.len > 0 and not ret.startsWith ".."

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
  ## This is similar to ``splitPath(path).head`` when ``path`` doesn't end
  ## in a dir separator, but also takes care of path normalizations.
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
      assert parentDir("foo/bar//") == "foo"
      assert parentDir("//foo//bar//.") == "/foo"
      assert parentDir("./foo") == "."
      assert parentDir("/./foo//./") == "/"
      assert parentDir("a//./") == "."
      assert parentDir("a/b/c/..") == "a"
  result = pathnorm.normalizePath(path)
  var sepPos = parentDirPos(result)
  if sepPos >= 0:
    result = substr(result, 0, sepPos)
    normalizePathEnd(result)
  elif result == ".." or result == "." or result.len == 0 or result[^1] in {DirSep, AltSep}:
    # `.` => `..` and .. => `../..`(etc) would be a sensible alternative
    # `/` => `/` (as done with splitFile) would be a sensible alternative
    result = ""
  else:
    result = "."

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
    assert tailDir("bin/") == ""
    assert tailDir("/usr/local/bin") == "usr/local/bin"
    assert tailDir("//usr//local//bin//") == "usr//local//bin//"
    assert tailDir("./usr/local/bin") == "usr/local/bin"
    assert tailDir("usr/local/bin") == "local/bin"

  var i = 0
  while i < len(path):
    if path[i] in {DirSep, AltSep}:
      while i < len(path) and path[i] in {DirSep, AltSep}: inc i
      return substr(path, i)
    inc i
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
  ## the file system root directory.
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
  ## `dir` does not end in `DirSep <#DirSep>`_ unless it's `/`.
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
    (dir, name, ext) = splitFile("/tmp.txt")
    assert dir == "/"
    assert name == "tmp"
    assert ext == ".txt"

  var namePos = 0
  var dotPos = 0
  for i in countdown(len(path) - 1, 0):
    if path[i] in {DirSep, AltSep} or i == 0:
      if path[i] in {DirSep, AltSep}:
        result.dir = substr(path, 0, if likely(i >= 1): i - 1 else: 0)
        namePos = i + 1
      if dotPos > i:
        result.name = substr(path, namePos, dotPos - 1)
        result.ext = substr(path, dotPos)
      else:
        result.name = substr(path, namePos)
      break
    elif path[i] == ExtSep and i > 0 and i < len(path) - 1 and
         path[i - 1] notin {DirSep, AltSep} and
         path[i + 1] != ExtSep and dotPos == 0:
      dotPos = i

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
  ## | 0 if pathA == pathB
  ## | < 0 if pathA < pathB
  ## | > 0 if pathA > pathB
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

  when defined(windows): return getEnv("USERPROFILE") & "\\"
  else: return getEnv("HOME") & "/"

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
    result = getEnv("APPDATA")
  else:
    result = getEnv("XDG_CONFIG_HOME", getEnv("HOME") / ".config")
  result.normalizePathEnd(trailingSep = true)


proc getCacheDir*(): string =
  ## Returns the cache directory of the current user for applications.
  ##
  ## This makes use of the following environment variables:
  ##
  ## * On Windows: `getEnv("LOCALAPPDATA")`
  ##
  ## * On macOS: `getEnv("XDG_CACHE_HOME", getEnv("HOME") / "Library/Caches")`
  ##
  ## * On other platforms: `getEnv("XDG_CACHE_HOME", getEnv("HOME") / ".cache")`
  ##
  ## **See also:**
  ## * `getHomeDir proc <#getHomeDir>`_
  ## * `getTempDir proc <#getTempDir>`_
  ## * `getConfigDir proc <#getConfigDir>`_
  # follows https://crates.io/crates/platform-dirs
  when defined(windows):
    result = getEnv("LOCALAPPDATA")
  elif defined(osx):
    result = getEnv("XDG_CACHE_HOME", getEnv("HOME") / "Library/Caches")
  else:
    result = getEnv("XDG_CACHE_HOME", getEnv("HOME") / ".cache")
  result.normalizePathEnd(false)

proc getCacheDir*(app: string): string =
  ## Returns the cache directory for an application `app`.
  ##
  ## * On windows, this uses: `getCacheDir() / app / "cache"`
  ##
  ## * On other platforms, this uses: `getCacheDir() / app`
  when defined(windows):
    getCacheDir() / app / "cache"
  else:
    getCacheDir() / app


when defined(windows):
  type DWORD = uint32

  proc getTempPath(
    nBufferLength: DWORD, lpBuffer: WideCString
  ): DWORD {.stdcall, dynlib: "kernel32.dll", importc: "GetTempPathW".} =
    ## Retrieves the path of the directory designated for temporary files.

template getEnvImpl(result: var string, tempDirList: openArray[string]) =
  for dir in tempDirList:
    if existsEnv(dir):
      result = getEnv(dir)
      break

template getTempDirImpl(result: var string) =
  when defined(windows):
    getEnvImpl(result, ["TMP", "TEMP", "USERPROFILE"])
  else:
    getEnvImpl(result, ["TMPDIR", "TEMP", "TMP", "TEMPDIR"])

proc getTempDir*(): string {.rtl, extern: "nos$1",
  tags: [ReadEnvEffect, ReadIOEffect].} =
  ## Returns the temporary directory of the current user for applications to
  ## save temporary files in.
  ##
  ## On Windows, it calls [GetTempPath](https://docs.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-gettemppathw).
  ## On Posix based platforms, it will check `TMPDIR`, `TEMP`, `TMP` and `TEMPDIR` environment variables in order.
  ## On all platforms, `/tmp` will be returned if the procs fails.
  ##
  ## You can override this implementation
  ## by adding `-d:tempDir=mytempname` to your compiler invocation.
  ##
  ## **Note:** This proc does not check whether the returned path exists.
  ##
  ## See also:
  ## * `getHomeDir proc <#getHomeDir>`_
  ## * `getConfigDir proc <#getConfigDir>`_
  ## * `expandTilde proc <#expandTilde,string>`_
  ## * `getCurrentDir proc <#getCurrentDir>`_
  ## * `setCurrentDir proc <#setCurrentDir,string>`_
  const tempDirDefault = "/tmp"
  when defined(tempDir):
    const tempDir {.strdefine.}: string = tempDirDefault
    result = tempDir
  else:
    when nimvm:
      getTempDirImpl(result)
    else:
      when defined(windows):
        let size = getTempPath(0, nil)
        # If the function fails, the return value is zero.
        if size > 0:
          let buffer = newWideCString(size.int)
          if getTempPath(size, buffer) > 0:
            result = $buffer
      elif defined(android): result = "/data/local/tmp"
      else:
        getTempDirImpl(result)
    if result.len == 0:
      result = tempDirDefault
  normalizePathEnd(result, trailingSep=true)

proc expandTilde*(path: string): string {.
  tags: [ReadEnvEffect, ReadIOEffect].} =
  ## Expands ``~`` or a path starting with ``~/`` to a full path, replacing
  ## ``~`` with `getHomeDir() <#getHomeDir>`_ (otherwise returns ``path`` unmodified).
  ##
  ## Windows: this is still supported despite the Windows platform not having this
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
      for i in 0..<backslashBuff.len*2:
        result.add('\\')
      backslashBuff.setLen(0)
      result.add("\\\"")
    else:
      if backslashBuff.len != 0:
        result.add(backslashBuff)
        backslashBuff.setLen(0)
      result.add(c)

  if backslashBuff.len > 0:
    result.add(backslashBuff)
  if needQuote:
    result.add(backslashBuff)
    result.add("\"")


proc quoteShellPosix*(s: string): string {.noSideEffect, rtl, extern: "nosp$1".} =
  ## Quote ``s``, so it can be safely passed to POSIX shell.
  const safeUnixChars = {'%', '+', '-', '.', '/', '_', ':', '=', '@',
                         '0'..'9', 'A'..'Z', 'a'..'z'}
  if s.len == 0:
    result = "''"
  elif s.allCharsInSet(safeUnixChars):
    result = s
  else:
    result = "'" & s.replace("'", "'\"'\"'") & "'"

when defined(windows) or defined(posix) or defined(nintendoswitch):
  proc quoteShell*(s: string): string {.noSideEffect, rtl, extern: "nosp$1".} =
    ## Quote ``s``, so it can be safely passed to shell.
    ##
    ## When on Windows, it calls `quoteShellWindows proc
    ## <#quoteShellWindows,string>`_. Otherwise, calls `quoteShellPosix proc
    ## <#quoteShellPosix,string>`_.
    when defined(windows):
      result = quoteShellWindows(s)
    else:
      result = quoteShellPosix(s)

  proc quoteShellCommand*(args: openArray[string]): string =
    ## Concatenates and quotes shell arguments `args`.
    runnableExamples:
      when defined(posix):
        assert quoteShellCommand(["aaa", "", "c d"]) == "aaa '' 'c d'"
      when defined(windows):
        assert quoteShellCommand(["aaa", "", "c d"]) == "aaa \"\" \"c d\""

    # can't use `map` pending https://github.com/nim-lang/Nim/issues/8303
    result = ""
    for i in 0..<args.len:
      if i > 0: result.add " "
      result.add quoteShell(args[i])

when not weirdTarget:
  proc c_system(cmd: cstring): cint {.
    importc: "system", header: "<stdlib.h>".}

  when not defined(windows):
    proc c_rename(oldname, newname: cstring): cint {.
      importc: "rename", header: "<stdio.h>".}
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
      $cast[WideCString](addr(f.cFileName[0]))
  else:
    template findFirstFile(a, b: untyped): untyped = findFirstFileA(a, b)
    template findNextFile(a, b: untyped): untyped = findNextFileA(a, b)
    template getCommandLine(): untyped = getCommandLineA()

    template getFilename(f: untyped): untyped = $cast[cstring](addr f.cFileName)

  proc skipFindData(f: WIN32_FIND_DATA): bool {.inline.} =
    # Note - takes advantage of null delimiter in the cstring
    const dot = ord('.')
    result = f.cFileName[0].int == dot and (f.cFileName[1].int == 0 or
             f.cFileName[1].int == dot and f.cFileName[2].int == 0)

proc fileExists*(filename: string): bool {.rtl, extern: "nos$1",
                                          tags: [ReadDirEffect], noNimJs.} =
  ## Returns true if `filename` exists and is a regular file or symlink.
  ##
  ## Directories, device files, named pipes and sockets return false.
  ##
  ## See also:
  ## * `dirExists proc <#dirExists,string>`_
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

proc dirExists*(dir: string): bool {.rtl, extern: "nos$1", tags: [ReadDirEffect],
                                     noNimJs.} =
  ## Returns true if the directory `dir` exists. If `dir` is a file, false
  ## is returned. Follows symlinks.
  ##
  ## See also:
  ## * `fileExists proc <#fileExists,string>`_
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
    result = stat(dir, res) >= 0'i32 and S_ISDIR(res.st_mode)

proc symlinkExists*(link: string): bool {.rtl, extern: "nos$1",
                                          tags: [ReadDirEffect],
                                          noWeirdTarget.} =
  ## Returns true if the symlink `link` exists. Will return true
  ## regardless of whether the link points to a directory or file.
  ##
  ## See also:
  ## * `fileExists proc <#fileExists,string>`_
  ## * `dirExists proc <#dirExists,string>`_
  when defined(windows):
    when useWinUnicode:
      wrapUnary(a, getFileAttributesW, link)
    else:
      var a = getFileAttributesA(link)
    if a != -1'i32:
      # xxx see: bug #16784 (bug9); checking `IO_REPARSE_TAG_SYMLINK`
      # may also be needed.
      result = (a and FILE_ATTRIBUTE_REPARSE_POINT) != 0'i32
  else:
    var res: Stat
    result = lstat(link, res) >= 0'i32 and S_ISLNK(res.st_mode)


when not defined(windows):
  const maxSymlinkLen = 1024

const
  ExeExts* = ## Platform specific file extension for executables.
    ## On Windows ``["exe", "cmd", "bat"]``, on Posix ``[""]``.
    when defined(windows): ["exe", "cmd", "bat"] else: [""]

proc findExe*(exe: string, followSymlinks: bool = true;
              extensions: openArray[string]=ExeExts): string {.
  tags: [ReadDirEffect, ReadEnvEffect, ReadIOEffect], noNimJs.} =
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
      if fileExists(result): return
  when defined(posix):
    if '/' in exe: checkCurrentDir()
  else:
    checkCurrentDir()
  let path = getEnv("PATH")
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
      if fileExists(x):
        when not defined(windows):
          while followSymlinks: # doubles as if here
            if x.symlinkExists:
              var r = newString(maxSymlinkLen)
              var len = readlink(x, r, maxSymlinkLen)
              if len < 0:
                raiseOSError(osLastError(), exe)
              if len > maxSymlinkLen:
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

proc getLastModificationTime*(file: string): times.Time {.rtl, extern: "nos$1", noWeirdTarget.} =
  ## Returns the `file`'s last modification time.
  ##
  ## See also:
  ## * `getLastAccessTime proc <#getLastAccessTime,string>`_
  ## * `getCreationTime proc <#getCreationTime,string>`_
  ## * `fileNewer proc <#fileNewer,string,string>`_
  when defined(posix):
    var res: Stat
    if stat(file, res) < 0'i32: raiseOSError(osLastError(), file)
    result = res.st_mtim.toTime
  else:
    var f: WIN32_FIND_DATA
    var h = findFirstFile(file, f)
    if h == -1'i32: raiseOSError(osLastError(), file)
    result = fromWinTime(rdFileTime(f.ftLastWriteTime))
    findClose(h)

proc getLastAccessTime*(file: string): times.Time {.rtl, extern: "nos$1", noWeirdTarget.} =
  ## Returns the `file`'s last read or write access time.
  ##
  ## See also:
  ## * `getLastModificationTime proc <#getLastModificationTime,string>`_
  ## * `getCreationTime proc <#getCreationTime,string>`_
  ## * `fileNewer proc <#fileNewer,string,string>`_
  when defined(posix):
    var res: Stat
    if stat(file, res) < 0'i32: raiseOSError(osLastError(), file)
    result = res.st_atim.toTime
  else:
    var f: WIN32_FIND_DATA
    var h = findFirstFile(file, f)
    if h == -1'i32: raiseOSError(osLastError(), file)
    result = fromWinTime(rdFileTime(f.ftLastAccessTime))
    findClose(h)

proc getCreationTime*(file: string): times.Time {.rtl, extern: "nos$1", noWeirdTarget.} =
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
    if stat(file, res) < 0'i32: raiseOSError(osLastError(), file)
    result = res.st_ctim.toTime
  else:
    var f: WIN32_FIND_DATA
    var h = findFirstFile(file, f)
    if h == -1'i32: raiseOSError(osLastError(), file)
    result = fromWinTime(rdFileTime(f.ftCreationTime))
    findClose(h)

proc fileNewer*(a, b: string): bool {.rtl, extern: "nos$1", noWeirdTarget.} =
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

when not defined(nimscript):
  proc getCurrentDir*(): string {.rtl, extern: "nos$1", tags: [].} =
    ## Returns the `current working directory`:idx: i.e. where the built
    ## binary is run.
    ##
    ## So the path returned by this proc is determined at run time.
    ##
    ## See also:
    ## * `getHomeDir proc <#getHomeDir>`_
    ## * `getConfigDir proc <#getConfigDir>`_
    ## * `getTempDir proc <#getTempDir>`_
    ## * `setCurrentDir proc <#setCurrentDir,string>`_
    ## * `currentSourcePath template <system.html#currentSourcePath.t>`_
    ## * `getProjectPath proc <macros.html#getProjectPath>`_
    when defined(nodejs):
      var ret: cstring
      {.emit: "`ret` = process.cwd();".}
      return $ret
    elif defined(js):
      doAssert false, "use -d:nodejs to have `getCurrentDir` defined"
    elif defined(windows):
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

proc setCurrentDir*(newDir: string) {.inline, tags: [], noWeirdTarget.} =
  ## Sets the `current working directory`:idx:; `OSError`
  ## is raised if `newDir` cannot been set.
  ##
  ## See also:
  ## * `getHomeDir proc <#getHomeDir>`_
  ## * `getConfigDir proc <#getConfigDir>`_
  ## * `getTempDir proc <#getTempDir>`_
  ## * `getCurrentDir proc <#getCurrentDir>`_
  when defined(windows):
    when useWinUnicode:
      if setCurrentDirectoryW(newWideCString(newDir)) == 0'i32:
        raiseOSError(osLastError(), newDir)
    else:
      if setCurrentDirectoryA(newDir) == 0'i32: raiseOSError(osLastError(), newDir)
  else:
    if chdir(newDir) != 0'i32: raiseOSError(osLastError(), newDir)


proc absolutePath*(path: string, root = getCurrentDir()): string =
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

proc absolutePathInternal(path: string): string =
  absolutePath(path, getCurrentDir())

proc normalizeExe*(file: var string) {.since: (1, 3, 5).} =
  ## on posix, prepends `./` if `file` doesn't contain `/` and is not `"", ".", ".."`.
  runnableExamples:
    import std/sugar
    when defined(posix):
      doAssert "foo".dup(normalizeExe) == "./foo"
      doAssert "foo/../bar".dup(normalizeExe) == "foo/../bar"
    doAssert "".dup(normalizeExe) == ""
  when defined(posix):
    if file.len > 0 and DirSep notin file and file != "." and file != "..":
      file = "./" & file

proc normalizePath*(path: var string) {.rtl, extern: "nos$1", tags: [].} =
  ## Normalize a path.
  ##
  ## Consecutive directory separators are collapsed, including an initial double slash.
  ##
  ## On relative paths, double dot (`..`) sequences are collapsed if possible.
  ## On absolute paths they are always collapsed.
  ##
  ## .. warning:: URL-encoded and Unicode attempts at directory traversal are not detected.
  ##   Triple dot is not handled.
  ##
  ## See also:
  ## * `absolutePath proc <#absolutePath,string>`_
  ## * `normalizedPath proc <#normalizedPath,string>`_ for outplace version
  ## * `normalizeExe proc <#normalizeExe,string>`_
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

proc normalizePathAux(path: var string) = normalizePath(path)

proc normalizedPath*(path: string): string {.rtl, extern: "nos$1", tags: [].} =
  ## Returns a normalized path for the current OS.
  ##
  ## See also:
  ## * `absolutePath proc <#absolutePath,string>`_
  ## * `normalizePath proc <#normalizePath,string>`_ for the in-place version
  runnableExamples:
    when defined(posix):
      assert normalizedPath("a///b//..//c///d") == "a/c/d"
  result = pathnorm.normalizePath(path)

when defined(windows) and not weirdTarget:
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
  tags: [ReadDirEffect], noWeirdTarget.} =
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
  when defined(windows):
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

    if not success: raiseOSError(lastErr, $(path1, path2))
  else:
    var a, b: Stat
    if stat(path1, a) < 0'i32 or stat(path2, b) < 0'i32:
      raiseOSError(osLastError(), $(path1, path2))
    else:
      result = a.st_dev == b.st_dev and a.st_ino == b.st_ino

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
  rtl, extern: "nos$1", tags: [ReadDirEffect], noWeirdTarget.} =
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
    if stat(filename, a) < 0'i32: raiseOSError(osLastError(), filename)
    result = {}
    if (a.st_mode and S_IRUSR.Mode) != 0.Mode: result.incl(fpUserRead)
    if (a.st_mode and S_IWUSR.Mode) != 0.Mode: result.incl(fpUserWrite)
    if (a.st_mode and S_IXUSR.Mode) != 0.Mode: result.incl(fpUserExec)

    if (a.st_mode and S_IRGRP.Mode) != 0.Mode: result.incl(fpGroupRead)
    if (a.st_mode and S_IWGRP.Mode) != 0.Mode: result.incl(fpGroupWrite)
    if (a.st_mode and S_IXGRP.Mode) != 0.Mode: result.incl(fpGroupExec)

    if (a.st_mode and S_IROTH.Mode) != 0.Mode: result.incl(fpOthersRead)
    if (a.st_mode and S_IWOTH.Mode) != 0.Mode: result.incl(fpOthersWrite)
    if (a.st_mode and S_IXOTH.Mode) != 0.Mode: result.incl(fpOthersExec)
  else:
    when useWinUnicode:
      wrapUnary(res, getFileAttributesW, filename)
    else:
      var res = getFileAttributesA(filename)
    if res == -1'i32: raiseOSError(osLastError(), filename)
    if (res and FILE_ATTRIBUTE_READONLY) != 0'i32:
      result = {fpUserExec, fpUserRead, fpGroupExec, fpGroupRead,
                fpOthersExec, fpOthersRead}
    else:
      result = {fpUserExec..fpOthersRead}

proc setFilePermissions*(filename: string, permissions: set[FilePermission],
                         followSymlinks = true)
  {.rtl, extern: "nos$1", tags: [ReadDirEffect, WriteDirEffect],
   noWeirdTarget.} =
  ## Sets the file permissions for `filename`.
  ##
  ## If `followSymlinks` set to true (default) and ``filename`` points to a
  ## symlink, permissions are set to the file symlink points to.
  ## `followSymlinks` set to false is a noop on Windows and some POSIX
  ## systems (including Linux) on which `lchmod` is either unavailable or always
  ## fails, given that symlinks permissions there are not observed.
  ##
  ## `OSError` is raised in case of an error.
  ## On Windows, only the ``readonly`` flag is changed, depending on
  ## ``fpUserWrite`` permission.
  ##
  ## See also:
  ## * `getFilePermissions <#getFilePermissions,string>`_
  ## * `FilePermission enum <#FilePermission>`_
  when defined(posix):
    var p = 0.Mode
    if fpUserRead in permissions: p = p or S_IRUSR.Mode
    if fpUserWrite in permissions: p = p or S_IWUSR.Mode
    if fpUserExec in permissions: p = p or S_IXUSR.Mode

    if fpGroupRead in permissions: p = p or S_IRGRP.Mode
    if fpGroupWrite in permissions: p = p or S_IWGRP.Mode
    if fpGroupExec in permissions: p = p or S_IXGRP.Mode

    if fpOthersRead in permissions: p = p or S_IROTH.Mode
    if fpOthersWrite in permissions: p = p or S_IWOTH.Mode
    if fpOthersExec in permissions: p = p or S_IXOTH.Mode

    if not followSymlinks and filename.symlinkExists:
      when declared(lchmod):
        if lchmod(filename, cast[Mode](p)) != 0:
          raiseOSError(osLastError(), $(filename, permissions))
    else:
      if chmod(filename, cast[Mode](p)) != 0:
        raiseOSError(osLastError(), $(filename, permissions))
  else:
    when useWinUnicode:
      wrapUnary(res, getFileAttributesW, filename)
    else:
      var res = getFileAttributesA(filename)
    if res == -1'i32: raiseOSError(osLastError(), filename)
    if fpUserWrite in permissions:
      res = res and not FILE_ATTRIBUTE_READONLY
    else:
      res = res or FILE_ATTRIBUTE_READONLY
    when useWinUnicode:
      wrapBinary(res2, setFileAttributesW, filename, res)
    else:
      var res2 = setFileAttributesA(filename, res)
    if res2 == - 1'i32: raiseOSError(osLastError(), $(filename, permissions))

proc isAdmin*: bool {.noWeirdTarget.} =
  ## Returns whether the caller's process is a member of the Administrators local
  ## group (on Windows) or a root (on POSIX), via `geteuid() == 0`.
  when defined(windows):
    # Rewrite of the example from Microsoft Docs:
    # https://docs.microsoft.com/en-us/windows/win32/api/securitybaseapi/nf-securitybaseapi-checktokenmembership#examples
    # and corresponding PostgreSQL function:
    # https://doxygen.postgresql.org/win32security_8c.html#ae6b61e106fa5d6c5d077a9d14ee80569
    var ntAuthority = SID_IDENTIFIER_AUTHORITY(value: SECURITY_NT_AUTHORITY)
    var administratorsGroup: PSID
    if not isSuccess(allocateAndInitializeSid(addr ntAuthority,
                                              BYTE(2),
                                              SECURITY_BUILTIN_DOMAIN_RID,
                                              DOMAIN_ALIAS_RID_ADMINS,
                                              0, 0, 0, 0, 0, 0,
                                              addr administratorsGroup)):
      raiseOSError(osLastError(), "could not get SID for Administrators group")

    try:
      var b: WINBOOL
      if not isSuccess(checkTokenMembership(0, administratorsGroup, addr b)):
        raiseOSError(osLastError(), "could not check access token membership")

      result = isSuccess(b)
    finally:
      if freeSid(administratorsGroup) != nil:
        raiseOSError(osLastError(), "failed to free SID for Administrators group")

  else:
    result = geteuid() == 0

proc createSymlink*(src, dest: string) {.noWeirdTarget.} =
  ## Create a symbolic link at `dest` which points to the item specified
  ## by `src`. On most operating systems, will fail if a link already exists.
  ##
  ## .. warning:: Some OS's (such as Microsoft Windows) restrict the creation
  ##   of symlinks to root users (administrators) or users with developper mode enabled.
  ##
  ## See also:
  ## * `createHardlink proc <#createHardlink,string,string>`_
  ## * `expandSymlink proc <#expandSymlink,string>`_

  when defined(windows):
    const SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE = 2
    # allows anyone with developer mode on to create a link
    let flag = dirExists(src).int32 or SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE
    when useWinUnicode:
      var wSrc = newWideCString(src)
      var wDst = newWideCString(dest)
      if createSymbolicLinkW(wDst, wSrc, flag) == 0 or getLastError() != 0:
        raiseOSError(osLastError(), $(src, dest))
    else:
      if createSymbolicLinkA(dest, src, flag) == 0 or getLastError() != 0:
        raiseOSError(osLastError(), $(src, dest))
  else:
    if symlink(src, dest) != 0:
      raiseOSError(osLastError(), $(src, dest))

proc expandSymlink*(symlinkPath: string): string {.noWeirdTarget.} =
  ## Returns a string representing the path to which the symbolic link points.
  ##
  ## On Windows this is a noop, `symlinkPath` is simply returned.
  ##
  ## See also:
  ## * `createSymlink proc <#createSymlink,string,string>`_
  when defined(windows):
    result = symlinkPath
  else:
    result = newString(maxSymlinkLen)
    var len = readlink(symlinkPath, result, maxSymlinkLen)
    if len < 0:
      raiseOSError(osLastError(), symlinkPath)
    if len > maxSymlinkLen:
      result = newString(len+1)
      len = readlink(symlinkPath, result, len)
    setLen(result, len)

const hasCCopyfile = defined(osx) and not defined(nimLegacyCopyFile)
  # xxx instead of `nimLegacyCopyFile`, support something like: `when osxVersion >= (10, 5)`

when hasCCopyfile:
  # `copyfile` API available since osx 10.5.
  {.push nodecl, header: "<copyfile.h>".}
  type
    copyfile_state_t {.nodecl.} = pointer
    copyfile_flags_t = cint
  proc copyfile_state_alloc(): copyfile_state_t
  proc copyfile_state_free(state: copyfile_state_t): cint
  proc c_copyfile(src, dst: cstring,  state: copyfile_state_t, flags: copyfile_flags_t): cint {.importc: "copyfile".}
  # replace with `let` pending bootstrap >= 1.4.0
  var
    COPYFILE_DATA {.nodecl.}: copyfile_flags_t
    COPYFILE_XATTR {.nodecl.}: copyfile_flags_t
  {.pop.}

type
  CopyFlag* = enum    ## Copy options.
    cfSymlinkAsIs,    ## Copy symlinks as symlinks
    cfSymlinkFollow,  ## Copy the files symlinks point to
    cfSymlinkIgnore   ## Ignore symlinks

const copyFlagSymlink = {cfSymlinkAsIs, cfSymlinkFollow, cfSymlinkIgnore}

proc copyFile*(source, dest: string, options = {cfSymlinkFollow}) {.rtl,
  extern: "nos$1", tags: [ReadDirEffect, ReadIOEffect, WriteIOEffect],
  noWeirdTarget.} =
  ## Copies a file from `source` to `dest`, where `dest.parentDir` must exist.
  ##
  ## On non-Windows OSes, `options` specify the way file is copied; by default,
  ## if `source` is a symlink, copies the file symlink points to. `options` is
  ## ignored on Windows: symlinks are skipped.
  ##
  ## If this fails, `OSError` is raised.
  ##
  ## On the Windows platform this proc will
  ## copy the source file's attributes into dest.
  ##
  ## On other platforms you need
  ## to use `getFilePermissions <#getFilePermissions,string>`_ and
  ## `setFilePermissions <#setFilePermissions,string,set[FilePermission]>`_
  ## procs
  ## to copy them by hand (or use the convenience `copyFileWithPermissions
  ## proc <#copyFileWithPermissions,string,string>`_),
  ## otherwise `dest` will inherit the default permissions of a newly
  ## created file for the user.
  ##
  ## If `dest` already exists, the file attributes
  ## will be preserved and the content overwritten.
  ##
  ## On OSX, `copyfile` C api will be used (available since OSX 10.5) unless
  ## `-d:nimLegacyCopyFile` is used.
  ##
  ## See also:
  ## * `CopyFlag enum <#CopyFlag>`_
  ## * `copyDir proc <#copyDir,string,string>`_
  ## * `copyFileWithPermissions proc <#copyFileWithPermissions,string,string>`_
  ## * `tryRemoveFile proc <#tryRemoveFile,string>`_
  ## * `removeFile proc <#removeFile,string>`_
  ## * `moveFile proc <#moveFile,string,string>`_

  doAssert card(copyFlagSymlink * options) == 1, "There should be exactly " &
                                                 "one cfSymlink* in options"
  let isSymlink = source.symlinkExists
  if isSymlink and (cfSymlinkIgnore in options or defined(windows)):
    return
  when defined(windows):
    when useWinUnicode:
      let s = newWideCString(source)
      let d = newWideCString(dest)
      if copyFileW(s, d, 0'i32) == 0'i32:
        raiseOSError(osLastError(), $(source, dest))
    else:
      if copyFileA(source, dest, 0'i32) == 0'i32:
        raiseOSError(osLastError(), $(source, dest))
  else:
    if isSymlink and cfSymlinkAsIs in options:
      createSymlink(expandSymlink(source), dest)
    else:
      when hasCCopyfile:
        let state = copyfile_state_alloc()
        # xxx `COPYFILE_STAT` could be used for one-shot
        # `copyFileWithPermissions`.
        let status = c_copyfile(source.cstring, dest.cstring, state,
                                COPYFILE_DATA)
        if status != 0:
          let err = osLastError()
          discard copyfile_state_free(state)
          raiseOSError(err, $(source, dest))
        let status2 = copyfile_state_free(state)
        if status2 != 0: raiseOSError(osLastError(), $(source, dest))
      else:
        # generic version of copyFile which works for any platform:
        const bufSize = 8000 # better for memory manager
        var d, s: File
        if not open(s, source):raiseOSError(osLastError(), source)
        if not open(d, dest, fmWrite):
          close(s)
          raiseOSError(osLastError(), dest)
        var buf = alloc(bufSize)
        while true:
          var bytesread = readBuffer(s, buf, bufSize)
          if bytesread > 0:
            var byteswritten = writeBuffer(d, buf, bytesread)
            if bytesread != byteswritten:
              dealloc(buf)
              close(s)
              close(d)
              raiseOSError(osLastError(), dest)
          if bytesread != bufSize: break
        dealloc(buf)
        close(s)
        flushFile(d)
        close(d)

proc copyFileToDir*(source, dir: string, options = {cfSymlinkFollow})
  {.noWeirdTarget, since: (1,3,7).} =
  ## Copies a file `source` into directory `dir`, which must exist.
  ##
  ## On non-Windows OSes, `options` specify the way file is copied; by default,
  ## if `source` is a symlink, copies the file symlink points to. `options` is
  ## ignored on Windows: symlinks are skipped.
  ##
  ## See also:
  ## * `CopyFlag enum <#CopyFlag>`_
  ## * `copyFile proc <#copyDir,string,string>`_
  if dir.len == 0: # treating "" as "." is error prone
    raise newException(ValueError, "dest is empty")
  copyFile(source, dir / source.lastPathPart, options)

when not declared(ENOENT) and not defined(windows):
  when defined(nimscript):
    when not defined(haiku):
      const ENOENT = cint(2) # 2 on most systems including Solaris
    else:
      const ENOENT = cint(-2147459069)
  else:
    var ENOENT {.importc, header: "<errno.h>".}: cint

when defined(windows) and not weirdTarget:
  when useWinUnicode:
    template deleteFile(file: untyped): untyped  = deleteFileW(file)
    template setFileAttributes(file, attrs: untyped): untyped =
      setFileAttributesW(file, attrs)
  else:
    template deleteFile(file: untyped): untyped = deleteFileA(file)
    template setFileAttributes(file, attrs: untyped): untyped =
      setFileAttributesA(file, attrs)

proc tryRemoveFile*(file: string): bool {.rtl, extern: "nos$1", tags: [WriteDirEffect], noWeirdTarget.} =
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
  when defined(windows):
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

proc removeFile*(file: string) {.rtl, extern: "nos$1", tags: [WriteDirEffect], noWeirdTarget.} =
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
    raiseOSError(osLastError(), file)

proc tryMoveFSObject(source, dest: string, isDir: bool): bool {.noWeirdTarget.} =
  ## Moves a file (or directory if `isDir` is true) from `source` to `dest`.
  ##
  ## Returns false in case of `EXDEV` error or `AccessDeniedError` on windows (if `isDir` is true).
  ## In case of other errors `OSError` is raised.
  ## Returns true in case of success.
  when defined(windows):
    when useWinUnicode:
      let s = newWideCString(source)
      let d = newWideCString(dest)
      result = moveFileExW(s, d, MOVEFILE_COPY_ALLOWED or MOVEFILE_REPLACE_EXISTING) != 0'i32
    else:
      result = moveFileExA(source, dest, MOVEFILE_COPY_ALLOWED or MOVEFILE_REPLACE_EXISTING) != 0'i32
  else:
    result = c_rename(source, dest) == 0'i32

  if not result:
    let err = osLastError()
    let isAccessDeniedError =
      when defined(windows):
        const AccessDeniedError = OSErrorCode(5)
        isDir and err == AccessDeniedError
      else:
        err == EXDEV.OSErrorCode
    if not isAccessDeniedError:
      raiseOSError(err, $(source, dest))

proc moveFile*(source, dest: string) {.rtl, extern: "nos$1",
  tags: [ReadDirEffect, ReadIOEffect, WriteIOEffect], noWeirdTarget.} =
  ## Moves a file from `source` to `dest`.
  ##
  ## Symlinks are not followed: if `source` is a symlink, it is itself moved,
  ## not its target.
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

  if not tryMoveFSObject(source, dest, isDir = false):
    when defined(windows):
      doAssert false
    else:
      # Fallback to copy & del
      copyFile(source, dest, {cfSymlinkAsIs})
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
  tags: [ExecIOEffect], noWeirdTarget.} =
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
          if dotPos < 0 or idx >= ff.len or (idx >= 0 and ff[idx] == '.') or
              (dotPos >= 0 and dotPos+1 < pattern.len and pattern[dotPos+1] == '*'):
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

iterator walkPattern*(pattern: string): string {.tags: [ReadDirEffect], noWeirdTarget.} =
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
  runnableExamples:
    import std/sequtils
    let paths = toSeq(walkPattern("lib/pure/*")) # works on windows too
    assert "lib/pure/concurrency".unixToNativePath in paths
    assert "lib/pure/os.nim".unixToNativePath in paths
  walkCommon(pattern, defaultWalkFilter)

iterator walkFiles*(pattern: string): string {.tags: [ReadDirEffect], noWeirdTarget.} =
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
  runnableExamples:
    import std/sequtils
    assert "lib/pure/os.nim".unixToNativePath in toSeq(walkFiles("lib/pure/*.nim")) # works on windows too
  walkCommon(pattern, isFile)

iterator walkDirs*(pattern: string): string {.tags: [ReadDirEffect], noWeirdTarget.} =
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
  runnableExamples:
    import std/sequtils
    let paths = toSeq(walkDirs("lib/pure/*")) # works on windows too
    assert "lib/pure/concurrency".unixToNativePath in paths
  walkCommon(pattern, isDir)

proc expandFilename*(filename: string): string {.rtl, extern: "nos$1",
  tags: [ReadDirEffect], noWeirdTarget.} =
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
          raiseOSError(osLastError(), filename)
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
          raiseOSError(osLastError(), filename)
        elif L > bufsize:
          result = newString(L)
          bufsize = L
        else:
          setLen(result, L)
          break
    # getFullPathName doesn't do case corrections, so we have to use this convoluted
    # way of retrieving the true filename
    for x in walkFiles(result):
      result = x
    if not fileExists(result) and not dirExists(result):
      # consider using: `raiseOSError(osLastError(), result)`
      raise newException(OSError, "file '" & result & "' does not exist")
  else:
    # according to Posix we don't need to allocate space for result pathname.
    # But we need to free return value with free(3).
    var r = realpath(filename, nil)
    if r.isNil:
      raiseOSError(osLastError(), filename)
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
  ## Can be used to retrieve the currently executing
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

iterator walkDir*(dir: string; relative = false, checkDir = false):
  tuple[kind: PathComponent, path: string] {.tags: [ReadDirEffect].} =
  ## Walks over the directory `dir` and yields for each directory or file in
  ## `dir`. The component type and full path for each item are returned.
  ##
  ## Walking is not recursive. If ``relative`` is true (default: false)
  ## the resulting path is shortened to be relative to ``dir``.
  ##
  ## If `checkDir` is true, `OSError` is raised when `dir`
  ## doesn't exist.
  ##
  ## Example: This directory structure::
  ##   dirA / dirB / fileB1.txt
  ##        / dirC
  ##        / fileA1.txt
  ##        / fileA2.txt
  ##
  ## and this code:
  runnableExamples("-r:off"):
    import std/[strutils, sugar]
    # note: order is not guaranteed
    # this also works at compile time
    assert collect(for k in walkDir("dirA"): k.path).join(" ") ==
                          "dirA/dirB dirA/dirC dirA/fileA2.txt dirA/fileA1.txt"
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
      if h == -1:
        if checkDir:
          raiseOSError(osLastError(), dir)
      else:
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
      if d == nil:
        if checkDir:
          raiseOSError(osLastError(), dir)
      else:
        defer: discard closedir(d)
        while true:
          var x = readdir(d)
          if x == nil: break
          var y = $cast[cstring](addr x.d_name)
          if y != "." and y != "..":
            var s: Stat
            let path = dir / y
            if not relative:
              y = path
            var k = pcFile

            template kSetGeneric() =  # pure Posix component `k` resolution
              if lstat(path, s) < 0'i32: continue  # don't yield
              elif S_ISDIR(s.st_mode):
                k = pcDir
              elif S_ISLNK(s.st_mode):
                k = getSymlinkFileKind(path)

            when defined(linux) or defined(macosx) or
                 defined(bsd) or defined(genode) or defined(nintendoswitch):
              case x.d_type
              of DT_DIR: k = pcDir
              of DT_LNK:
                if dirExists(path): k = pcLinkToDir
                else: k = pcLinkToFile
              of DT_UNKNOWN:
                kSetGeneric()
              else: # e.g. DT_REG etc
                discard # leave it as pcFile
            else:  # assuming that field `d_type` is not present
              kSetGeneric()

            yield (k, y)

iterator walkDirRec*(dir: string,
                     yieldFilter = {pcFile}, followFilter = {pcDir},
                     relative = false, checkDir = false): string {.tags: [ReadDirEffect].} =
  ## Recursively walks over the directory `dir` and yields for each file
  ## or directory in `dir`.
  ##
  ## If ``relative`` is true (default: false) the resulting path is
  ## shortened to be relative to ``dir``, otherwise the full path is returned.
  ##
  ## If `checkDir` is true, `OSError` is raised when `dir`
  ## doesn't exist.
  ##
  ## .. warning:: Modifying the directory structure while the iterator
  ##   is traversing may result in undefined behavior!
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
  var checkDir = checkDir
  while stack.len > 0:
    let d = stack.pop()
    for k, p in walkDir(dir / d, relative = true, checkDir = checkDir):
      let rel = d / p
      if k in {pcDir, pcLinkToDir} and k in followFilter:
        stack.add rel
      if k in yieldFilter:
        yield if relative: rel else: dir / rel
    checkDir = false
      # We only check top-level dir, otherwise if a subdir is invalid (eg. wrong
      # permissions), it'll abort iteration and there would be no way to
      # continue iteration.
      # Future work can provide a way to customize this and do error reporting.

proc rawRemoveDir(dir: string) {.noWeirdTarget.} =
  when defined(windows):
    when useWinUnicode:
      wrapUnary(res, removeDirectoryW, dir)
    else:
      var res = removeDirectoryA(dir)
    let lastError = osLastError()
    if res == 0'i32 and lastError.int32 != 3'i32 and
        lastError.int32 != 18'i32 and lastError.int32 != 2'i32:
      raiseOSError(lastError, dir)
  else:
    if rmdir(dir) != 0'i32 and errno != ENOENT: raiseOSError(osLastError(), dir)

proc removeDir*(dir: string, checkDir = false) {.rtl, extern: "nos$1", tags: [
  WriteDirEffect, ReadDirEffect], benign, noWeirdTarget.} =
  ## Removes the directory `dir` including all subdirectories and files
  ## in `dir` (recursively).
  ##
  ## If this fails, `OSError` is raised. This does not fail if the directory never
  ## existed in the first place, unless `checkDir` = true.
  ##
  ## See also:
  ## * `tryRemoveFile proc <#tryRemoveFile,string>`_
  ## * `removeFile proc <#removeFile,string>`_
  ## * `existsOrCreateDir proc <#existsOrCreateDir,string>`_
  ## * `createDir proc <#createDir,string>`_
  ## * `copyDir proc <#copyDir,string,string>`_
  ## * `copyDirWithPermissions proc <#copyDirWithPermissions,string,string>`_
  ## * `moveDir proc <#moveDir,string,string>`_
  for kind, path in walkDir(dir, checkDir = checkDir):
    case kind
    of pcFile, pcLinkToFile, pcLinkToDir: removeFile(path)
    of pcDir: removeDir(path, true)
      # for subdirectories there is no benefit in `checkDir = false`
      # (unless perhaps for edge case of concurrent processes also deleting
      # the same files)
  rawRemoveDir(dir)

proc rawCreateDir(dir: string): bool {.noWeirdTarget.} =
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
  tags: [WriteDirEffect, ReadDirEffect], noWeirdTarget.} =
  ## Checks if a `directory`:idx: `dir` exists, and creates it otherwise.
  ##
  ## Does not create parent directories (raises `OSError` if parent directories do not exist).
  ## Returns `true` if the directory already exists, and `false` otherwise.
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
    if not dirExists(dir):
      raise newException(IOError, "Failed to create '" & dir & "'")

proc createDir*(dir: string) {.rtl, extern: "nos$1",
  tags: [WriteDirEffect, ReadDirEffect], noWeirdTarget.} =
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
  tags: [ReadDirEffect, WriteIOEffect, ReadIOEffect], benign, noWeirdTarget.} =
  ## Copies a directory from `source` to `dest`.
  ##
  ## On non-Windows OSes, symlinks are copied as symlinks. On Windows, symlinks
  ## are skipped.
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
    if kind == pcDir:
      copyDir(path, dest / noSource)
    else:
      copyFile(path, dest / noSource, {cfSymlinkAsIs})

proc moveDir*(source, dest: string) {.tags: [ReadIOEffect, WriteIOEffect], noWeirdTarget.} =
  ## Moves a directory from `source` to `dest`.
  ##
  ## Symlinks are not followed: if `source` contains symlinks, they themself are
  ## moved, not their target.
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
  if not tryMoveFSObject(source, dest, isDir = true):
    # Fallback to copy & del
    copyDir(source, dest)
    removeDir(source)

proc createHardlink*(src, dest: string) {.noWeirdTarget.} =
  ## Create a hard link at `dest` which points to the item specified
  ## by `src`.
  ##
  ## .. warning:: Some OS's restrict the creation of hard links to
  ##   root users (administrators).
  ##
  ## See also:
  ## * `createSymlink proc <#createSymlink,string,string>`_
  when defined(windows):
    when useWinUnicode:
      var wSrc = newWideCString(src)
      var wDst = newWideCString(dest)
      if createHardLinkW(wDst, wSrc, nil) == 0:
        raiseOSError(osLastError(), $(src, dest))
    else:
      if createHardLinkA(dest, src, nil) == 0:
        raiseOSError(osLastError(), $(src, dest))
  else:
    if link(src, dest) != 0:
      raiseOSError(osLastError(), $(src, dest))

proc copyFileWithPermissions*(source, dest: string,
                              ignorePermissionErrors = true,
                              options = {cfSymlinkFollow}) {.noWeirdTarget.} =
  ## Copies a file from `source` to `dest` preserving file permissions.
  ##
  ## On non-Windows OSes, `options` specify the way file is copied; by default,
  ## if `source` is a symlink, copies the file symlink points to. `options` is
  ## ignored on Windows: symlinks are skipped.
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
  ## * `CopyFlag enum <#CopyFlag>`_
  ## * `copyFile proc <#copyFile,string,string>`_
  ## * `copyDir proc <#copyDir,string,string>`_
  ## * `tryRemoveFile proc <#tryRemoveFile,string>`_
  ## * `removeFile proc <#removeFile,string>`_
  ## * `moveFile proc <#moveFile,string,string>`_
  ## * `copyDirWithPermissions proc <#copyDirWithPermissions,string,string>`_
  copyFile(source, dest, options)
  when not defined(windows):
    try:
      setFilePermissions(dest, getFilePermissions(source), followSymlinks =
                         (cfSymlinkFollow in options))
    except:
      if not ignorePermissionErrors:
        raise

proc copyDirWithPermissions*(source, dest: string,
                             ignorePermissionErrors = true)
  {.rtl, extern: "nos$1", tags: [ReadDirEffect, WriteIOEffect, ReadIOEffect],
   benign, noWeirdTarget.} =
  ## Copies a directory from `source` to `dest` preserving file permissions.
  ##
  ## On non-Windows OSes, symlinks are copied as symlinks. On Windows, symlinks
  ## are skipped.
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
  when not defined(windows):
    try:
      setFilePermissions(dest, getFilePermissions(source), followSymlinks =
                         false)
    except:
      if not ignorePermissionErrors:
        raise
  for kind, path in walkDir(source):
    var noSource = splitPath(path).tail
    if kind == pcDir:
      copyDirWithPermissions(path, dest / noSource, ignorePermissionErrors)
    else:
      copyFileWithPermissions(path, dest / noSource, ignorePermissionErrors, {cfSymlinkAsIs})

proc inclFilePermissions*(filename: string,
                          permissions: set[FilePermission]) {.
  rtl, extern: "nos$1", tags: [ReadDirEffect, WriteDirEffect], noWeirdTarget.} =
  ## A convenience proc for:
  ##
  ## .. code-block:: nim
  ##   setFilePermissions(filename, getFilePermissions(filename)+permissions)
  setFilePermissions(filename, getFilePermissions(filename)+permissions)

proc exclFilePermissions*(filename: string,
                          permissions: set[FilePermission]) {.
  rtl, extern: "nos$1", tags: [ReadDirEffect, WriteDirEffect], noWeirdTarget.} =
  ## A convenience proc for:
  ##
  ## .. code-block:: nim
  ##   setFilePermissions(filename, getFilePermissions(filename)-permissions)
  setFilePermissions(filename, getFilePermissions(filename)-permissions)

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
    ## You can query each individual parameter with `paramStr proc <#paramStr,int>`_
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

  proc paramStr*(i: int): string {.tags: [ReadIOEffect].} =
    ## Returns the `i`-th `command line argument`:idx: given to the application.
    ##
    ## `i` should be in the range `1..paramCount()`, the `IndexDefect`
    ## exception will be raised for invalid values. Instead of iterating
    ## over `paramCount() <#paramCount>`_ with this proc you can
    ## call the convenience `commandLineParams() <#commandLineParams>`_.
    ##
    ## Similarly to `argv`:idx: in C,
    ## it is possible to call `paramStr(0)` but this will return OS specific
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

elif defined(nimscript): discard
elif defined(nodejs):
  type Argv = object of JsRoot
  let argv {.importjs: "process.argv".} : Argv
  proc len(argv: Argv): int {.importjs: "#.length".}
  proc `[]`(argv: Argv, i: int): cstring {.importjs: "#[#]".}

  proc paramCount*(): int {.tags: [ReadDirEffect].} =
    result = argv.len - 2

  proc paramStr*(i: int): string {.tags: [ReadIOEffect].} =
    let i = i + 1
    if i < argv.len and i >= 0:
      result = $argv[i]
    else:
      raise newException(IndexDefect, formatErrorIndexBound(i - 1, argv.len - 2))
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

  proc paramStr*(i: int): string {.rtl, extern: "nos$1",
    tags: [ReadIOEffect].} =
    # Docstring in nimdoc block.
    if not ownParsedArgv:
      ownArgv = parseCmdLine($getCommandLine())
      ownParsedArgv = true
    if i < ownArgv.len and i >= 0:
      result = ownArgv[i]
    else:
      raise newException(IndexDefect, formatErrorIndexBound(i, ownArgv.len-1))

elif defined(genode):
  proc paramStr*(i: int): string =
    raise newException(OSError, "paramStr is not implemented on Genode")

  proc paramCount*(): int =
    raise newException(OSError, "paramCount is not implemented on Genode")
elif weirdTarget or (defined(posix) and appType == "lib"):
  proc paramStr*(i: int): string {.tags: [ReadIOEffect].} =
    raise newException(OSError, "paramStr is not implemented on current platform")

  proc paramCount*(): int {.tags: [ReadIOEffect].} =
    raise newException(OSError, "paramCount is not implemented on current platform")
elif not defined(createNimRtl) and
  not(defined(posix) and appType == "lib"):
  # On Posix, there is no portable way to get the command line from a DLL.
  var
    cmdCount {.importc: "cmdCount".}: cint
    cmdLine {.importc: "cmdLine".}: cstringArray

  proc paramStr*(i: int): string {.tags: [ReadIOEffect].} =
    # Docstring in nimdoc block.
    if i < cmdCount and i >= 0:
      result = $cmdLine[i]
    else:
      raise newException(IndexDefect, formatErrorIndexBound(i, cmdCount-1))

  proc paramCount*(): int {.tags: [ReadIOEffect].} =
    # Docstring in nimdoc block.
    result = cmdCount-1

when declared(paramCount) or defined(nimdoc):
  proc commandLineParams*(): seq[string] =
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
else:
  proc commandLineParams*(): seq[string] {.error:
  "commandLineParams() unsupported by dynamic libraries".} =
    discard

when not weirdTarget and (defined(freebsd) or defined(dragonfly) or defined(netbsd)):
  proc sysctl(name: ptr cint, namelen: cuint, oldp: pointer, oldplen: ptr csize_t,
              newp: pointer, newplen: csize_t): cint
       {.importc: "sysctl",header: """#include <sys/types.h>
                                      #include <sys/sysctl.h>""".}
  const
    CTL_KERN = 1
    KERN_PROC = 14
    MAX_PATH = 1024

  when defined(freebsd):
    const KERN_PROC_PATHNAME = 12
  elif defined(netbsd):
    const KERN_PROC_ARGS = 48
    const KERN_PROC_PATHNAME = 5
  else:
    const KERN_PROC_PATHNAME = 9

  proc getApplFreebsd(): string =
    var pathLength = csize_t(0)

    when defined(netbsd):
      var req = [CTL_KERN.cint, KERN_PROC_ARGS.cint, -1.cint, KERN_PROC_PATHNAME.cint]
    else:
      var req = [CTL_KERN.cint, KERN_PROC.cint, KERN_PROC_PATHNAME.cint, -1.cint]

    # first call to get the required length
    var res = sysctl(addr req[0], 4, nil, addr pathLength, nil, 0)

    if res < 0:
      return ""

    result.setLen(pathLength)
    res = sysctl(addr req[0], 4, addr result[0], addr pathLength, nil, 0)

    if res < 0:
      return ""

    let realLen = len(cstring(result))
    setLen(result, realLen)

when not weirdTarget and (defined(linux) or defined(solaris) or defined(bsd) or defined(aix)):
  proc getApplAux(procPath: string): string =
    result = newString(maxSymlinkLen)
    var len = readlink(procPath, result, maxSymlinkLen)
    if len > maxSymlinkLen:
      result = newString(len+1)
      len = readlink(procPath, result, len)
    setLen(result, len)

when not weirdTarget and defined(openbsd):
  proc getApplOpenBsd(): string =
    # similar to getApplHeuristic, but checks current working directory
    when declared(paramStr):
      result = ""

      # POSIX guaranties that this contains the executable
      # as it has been executed by the calling process
      let exePath = paramStr(0)

      if len(exePath) == 0:
        return ""

      if exePath[0] == DirSep:
        # path is absolute
        result = exePath
      else:
        # not an absolute path, check if it's relative to the current working directory
        for i in 1..<len(exePath):
          if exePath[i] == DirSep:
            result = joinPath(getCurrentDir(), exePath)
            break

      if len(result) > 0:
        return expandFilename(result)

      # search in path
      for p in split(getEnv("PATH"), {PathSep}):
        var x = joinPath(p, exePath)
        if fileExists(x):
          return expandFilename(x)
    else:
      result = ""

when not (defined(windows) or defined(macosx) or weirdTarget):
  proc getApplHeuristic(): string =
    when declared(paramStr):
      result = paramStr(0)
      # POSIX guaranties that this contains the executable
      # as it has been executed by the calling process
      if len(result) > 0 and result[0] != DirSep: # not an absolute path?
        # iterate over any path in the $PATH environment variable
        for p in split(getEnv("PATH"), {PathSep}):
          var x = joinPath(p, result)
          if fileExists(x): return x
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

proc getAppFilename*(): string {.rtl, extern: "nos$1", tags: [ReadIOEffect], noWeirdTarget.} =
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
    var size = cuint32(0)
    getExecPath1(nil, size)
    result = newString(int(size))
    if getExecPath2(result, size):
      result = "" # error!
    if result.len > 0:
      result = result.expandFilename
  else:
    when defined(linux) or defined(aix):
      result = getApplAux("/proc/self/exe")
    elif defined(solaris):
      result = getApplAux("/proc/" & $getpid() & "/path/a.out")
    elif defined(genode):
      raiseOSError(OSErrorCode(-1), "POSIX command line not supported")
    elif defined(freebsd) or defined(dragonfly) or defined(netbsd):
      result = getApplFreebsd()
    elif defined(haiku):
      result = getApplHaiku()
    elif defined(openbsd):
      result = getApplOpenBsd()

    # little heuristic that may work on other POSIX-like systems:
    if result.len == 0:
      result = getApplHeuristic()

proc getAppDir*(): string {.rtl, extern: "nos$1", tags: [ReadIOEffect], noWeirdTarget.} =
  ## Returns the directory of the application's executable.
  ##
  ## See also:
  ## * `getAppFilename proc <#getAppFilename>`_
  result = splitFile(getAppFilename()).dir

proc sleep*(milsecs: int) {.rtl, extern: "nos$1", tags: [TimeEffect], noWeirdTarget.} =
  ## Sleeps `milsecs` milliseconds.
  when defined(windows):
    winlean.sleep(int32(milsecs))
  else:
    var a, b: Timespec
    a.tv_sec = posix.Time(milsecs div 1000)
    a.tv_nsec = (milsecs mod 1000) * 1000 * 1000
    discard posix.nanosleep(a, b)

proc getFileSize*(file: string): BiggestInt {.rtl, extern: "nos$1",
  tags: [ReadIOEffect], noWeirdTarget.} =
  ## Returns the file size of `file` (in bytes). ``OSError`` is
  ## raised in case of an error.
  when defined(windows):
    var a: WIN32_FIND_DATA
    var resA = findFirstFile(file, a)
    if resA == -1: raiseOSError(osLastError(), file)
    result = rdFileSize(a)
    findClose(resA)
  else:
    var f: File
    if open(f, file):
      result = getFileSize(f)
      close(f)
    else: raiseOSError(osLastError(), file)

when defined(windows) or weirdTarget:
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
    blockSize*: int                   ## Preferred I/O block size for this object.
                                      ## In some filesystems, this may vary from file to file.

template rawToFormalFileInfo(rawInfo, path, formalInfo): untyped =
  ## Transforms the native file info structure into the one nim uses.
  ## 'rawInfo' is either a 'BY_HANDLE_FILE_INFORMATION' structure on Windows,
  ## or a 'Stat' structure on posix
  when defined(windows):
    template merge(a, b): untyped =
      int64(
        (uint64(cast[uint32](a))) or
        (uint64(cast[uint32](b)) shl 32)
       )
    formalInfo.id.device = rawInfo.dwVolumeSerialNumber
    formalInfo.id.file = merge(rawInfo.nFileIndexLow, rawInfo.nFileIndexHigh)
    formalInfo.size = merge(rawInfo.nFileSizeLow, rawInfo.nFileSizeHigh)
    formalInfo.linkCount = rawInfo.nNumberOfLinks
    formalInfo.lastAccessTime = fromWinTime(rdFileTime(rawInfo.ftLastAccessTime))
    formalInfo.lastWriteTime = fromWinTime(rdFileTime(rawInfo.ftLastWriteTime))
    formalInfo.creationTime = fromWinTime(rdFileTime(rawInfo.ftCreationTime))
    formalInfo.blockSize = 8192 # xxx use windows API instead of hardcoding

    # Retrieve basic permissions
    if (rawInfo.dwFileAttributes and FILE_ATTRIBUTE_READONLY) != 0'i32:
      formalInfo.permissions = {fpUserExec, fpUserRead, fpGroupExec,
                                fpGroupRead, fpOthersExec, fpOthersRead}
    else:
      formalInfo.permissions = {fpUserExec..fpOthersRead}

    # Retrieve basic file kind
    if (rawInfo.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) != 0'i32:
      formalInfo.kind = pcDir
    else:
      formalInfo.kind = pcFile
    if (rawInfo.dwFileAttributes and FILE_ATTRIBUTE_REPARSE_POINT) != 0'i32:
      formalInfo.kind = succ(formalInfo.kind)

  else:
    template checkAndIncludeMode(rawMode, formalMode: untyped) =
      if (rawInfo.st_mode and rawMode.Mode) != 0.Mode:
        formalInfo.permissions.incl(formalMode)
    formalInfo.id = (rawInfo.st_dev, rawInfo.st_ino)
    formalInfo.size = rawInfo.st_size
    formalInfo.linkCount = rawInfo.st_nlink.BiggestInt
    formalInfo.lastAccessTime = rawInfo.st_atim.toTime
    formalInfo.lastWriteTime = rawInfo.st_mtim.toTime
    formalInfo.creationTime = rawInfo.st_ctim.toTime
    formalInfo.blockSize = rawInfo.st_blksize

    formalInfo.permissions = {}
    checkAndIncludeMode(S_IRUSR, fpUserRead)
    checkAndIncludeMode(S_IWUSR, fpUserWrite)
    checkAndIncludeMode(S_IXUSR, fpUserExec)

    checkAndIncludeMode(S_IRGRP, fpGroupRead)
    checkAndIncludeMode(S_IWGRP, fpGroupWrite)
    checkAndIncludeMode(S_IXGRP, fpGroupExec)

    checkAndIncludeMode(S_IROTH, fpOthersRead)
    checkAndIncludeMode(S_IWOTH, fpOthersWrite)
    checkAndIncludeMode(S_IXOTH, fpOthersExec)

    formalInfo.kind =
      if S_ISDIR(rawInfo.st_mode):
        pcDir
      elif S_ISLNK(rawInfo.st_mode):
        assert(path != "") # symlinks can't occur for file handles
        getSymlinkFileKind(path)
      else:
        pcFile

when defined(js):
  when not declared(FileHandle):
    type FileHandle = distinct int32
  when not declared(File):
    type File = object

proc getFileInfo*(handle: FileHandle): FileInfo {.noWeirdTarget.} =
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
  when defined(windows):
    var rawInfo: BY_HANDLE_FILE_INFORMATION
    # We have to use the super special '_get_osfhandle' call (wrapped above)
    # To transform the C file descriptor to a native file handle.
    var realHandle = get_osfhandle(handle)
    if getFileInformationByHandle(realHandle, addr rawInfo) == 0:
      raiseOSError(osLastError(), $handle)
    rawToFormalFileInfo(rawInfo, "", result)
  else:
    var rawInfo: Stat
    if fstat(handle, rawInfo) < 0'i32:
      raiseOSError(osLastError(), $handle)
    rawToFormalFileInfo(rawInfo, "", result)

proc getFileInfo*(file: File): FileInfo {.noWeirdTarget.} =
  ## Retrieves file information for the file object.
  ##
  ## See also:
  ## * `getFileInfo(handle) proc <#getFileInfo,FileHandle>`_
  ## * `getFileInfo(path) proc <#getFileInfo,string>`_
  if file.isNil:
    raise newException(IOError, "File is nil")
  result = getFileInfo(file.getFileHandle())

proc getFileInfo*(path: string, followSymlink = true): FileInfo {.noWeirdTarget.} =
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
  when defined(windows):
    var
      handle = openHandle(path, followSymlink)
      rawInfo: BY_HANDLE_FILE_INFORMATION
    if handle == INVALID_HANDLE_VALUE:
      raiseOSError(osLastError(), path)
    if getFileInformationByHandle(handle, addr rawInfo) == 0:
      raiseOSError(osLastError(), path)
    rawToFormalFileInfo(rawInfo, path, result)
    discard closeHandle(handle)
  else:
    var rawInfo: Stat
    if followSymlink:
      if stat(path, rawInfo) < 0'i32:
        raiseOSError(osLastError(), path)
    else:
      if lstat(path, rawInfo) < 0'i32:
        raiseOSError(osLastError(), path)
    rawToFormalFileInfo(rawInfo, path, result)

proc sameFileContent*(path1, path2: string): bool {.rtl, extern: "nos$1",
  tags: [ReadIOEffect], noWeirdTarget.} =
  ## Returns true if both pathname arguments refer to files with identical
  ## binary content.
  ##
  ## See also:
  ## * `sameFile proc <#sameFile,string,string>`_
  var
    a, b: File
  if not open(a, path1): return false
  if not open(b, path2):
    close(a)
    return false
  let bufSize = getFileInfo(a).blockSize
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

proc isHidden*(path: string): bool {.noWeirdTarget.} =
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

  when defined(windows):
    when useWinUnicode:
      wrapUnary(attributes, getFileAttributesW, path)
    else:
      var attributes = getFileAttributesA(path)
    if attributes != -1'i32:
      result = (attributes and FILE_ATTRIBUTE_HIDDEN) != 0'i32
  else:
    let fileName = lastPathPart(path)
    result = len(fileName) >= 2 and fileName[0] == '.' and fileName != ".."

proc getCurrentProcessId*(): int {.noWeirdTarget.} =
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

proc setLastModificationTime*(file: string, t: times.Time) {.noWeirdTarget.} =
  ## Sets the `file`'s last modification time. `OSError` is raised in case of
  ## an error.
  when defined(posix):
    let unixt = posix.Time(t.toUnix)
    let micro = convert(Nanoseconds, Microseconds, t.nanosecond)
    var timevals = [Timeval(tv_sec: unixt, tv_usec: micro),
      Timeval(tv_sec: unixt, tv_usec: micro)] # [last access, last modification]
    if utimes(file, timevals.addr) != 0: raiseOSError(osLastError(), file)
  else:
    let h = openHandle(path = file, writeAccess = true)
    if h == INVALID_HANDLE_VALUE: raiseOSError(osLastError(), file)
    var ft = t.toWinTime.toFILETIME
    let res = setFileTime(h, nil, nil, ft.addr)
    discard h.closeHandle
    if res == 0'i32: raiseOSError(osLastError(), file)

func isValidFilename*(filename: string, maxLen = 259.Positive): bool {.since: (1, 1).} =
  ## Returns true if ``filename`` is valid for crossplatform use.
  ##
  ## This is useful if you want to copy or save files across Windows, Linux, Mac, etc.
  ## You can pass full paths as argument too, but func only checks filenames.
  ## It uses ``invalidFilenameChars``, ``invalidFilenames`` and ``maxLen`` to verify the specified ``filename``.
  ##
  ## .. code-block:: nim
  ##   assert not isValidFilename(" foo")    ## Leading white space
  ##   assert not isValidFilename("foo ")    ## Trailing white space
  ##   assert not isValidFilename("foo.")    ## Ends with Dot
  ##   assert not isValidFilename("con.txt") ## "CON" is invalid (Windows)
  ##   assert not isValidFilename("OwO:UwU") ## ":" is invalid (Mac)
  ##   assert not isValidFilename("aux.bat") ## "AUX" is invalid (Windows)
  ##
  # https://docs.microsoft.com/en-us/dotnet/api/system.io.pathtoolongexception
  # https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file
  # https://msdn.microsoft.com/en-us/library/windows/desktop/aa365247%28v=vs.85%29.aspx
  result = true
  let f = filename.splitFile()
  if unlikely(f.name.len + f.ext.len > maxLen or
    f.name[0] == ' ' or f.name[^1] == ' ' or f.name[^1] == '.' or
    find(f.name, invalidFilenameChars) != -1): return false
  for invalid in invalidFilenames:
    if cmpIgnoreCase(f.name, invalid) == 0: return false

# deprecated declarations
when not defined(nimscript):
  when not defined(js): # `noNimJs` doesn't work with templates, this should improve.
    template existsFile*(args: varargs[untyped]): untyped {.deprecated: "use fileExists".} =
      fileExists(args)
    template existsDir*(args: varargs[untyped]): untyped {.deprecated: "use dirExists".} =
      dirExists(args)
  # {.deprecated: [existsFile: fileExists].} # pending bug #14819; this would avoid above mentioned issue
