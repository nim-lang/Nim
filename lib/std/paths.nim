import includes/osseps

include system/inclrtl
import std/private/since

import strutils, pathnorm

when defined(nimPreviewSlimSystem):
  import std/[syncio, assertions]

type
  ReadDirEffect* = object of ReadIOEffect   ## Effect that denotes a read
                                            ## operation from the directory
                                            ## structure.
  WriteDirEffect* = object of WriteIOEffect ## Effect that denotes a write
                                            ## operation to
                                            ## the directory structure.

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


template endsWith(a: string, b: set[char]): bool =
  a.len > 0 and a[^1] in b

proc joinPathImpl(result: var string, state: var int, tail: string) =
  let trailingSep = tail.endsWith({DirSep, AltSep}) or tail.len == 0 and result.endsWith({DirSep, AltSep})
  normalizePathEnd(result, trailingSep=false)
  addNormalizePath(tail, result, state, DirSep)
  normalizePathEnd(result, trailingSep=trailingSep)


func joinPath(head, tail: string): string =
  ## Joins two directory names to one.
  ##
  ## returns normalized path concatenation of `head` and `tail`, preserving
  ## whether or not `tail` has a trailing slash (or, if tail if empty, whether
  ## head has one).
  ##
  ## See also:
  ## * `joinPath(parts: varargs[string]) proc`_
  ## * `/ proc`_
  ## * `splitPath proc`_
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

func isAbsoluteImpl(path: string): bool {.raises: [].} =
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
    # This works around the problem for posix, but Windows is still broken with nim js -d:nodejs
    result = path[0] == '/'
  else:
    doAssert false # if ever hits here, adapt as needed

when doslikeFileSystem:
  import std/private/ntpath

type
  Path* = distinct string

func len*(x: Path): int =
  len(string(x))


func isAbsolute*(path: Path): bool {.inline, raises: [].} =
  result = isAbsoluteImpl(path.string)

func joinPath*(head, tail: Path): Path {.inline.} =
  result = Path(joinPath(head.string, tail.string))

func joinPath*(parts: varargs[Path]): Path =
  var estimatedLen = 0
  for p in parts: estimatedLen += p.string.len
  var res = newStringOfCap(estimatedLen)
  var state = 0
  for i in 0..high(parts):
    joinPathImpl(res, state, parts[i].string)
  result = Path(res)

func `/`*(head, tail: Path): Path {.inline.} =
  result = joinPath(head, tail)

func splitPathImpl(path: string): tuple[head, tail: Path] =
  ## Splits a directory into `(head, tail)` tuple, so that
  ## ``head / tail == path`` (except for edge cases like "/usr").
  ##
  ## See also:
  ## * `joinPath(head, tail) proc`_
  ## * `joinPath(parts: varargs[string]) proc`_
  ## * `/ proc`_
  ## * `/../ proc`_
  ## * `relativePath proc`_
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

  when doslikeFileSystem:
    let (drive, splitpath) = splitDrive(path)
    let stop = drive.len
  else:
    const stop = 0

  var sepPos = -1
  for i in countdown(len(path)-1, stop):
    if path[i] in {DirSep, AltSep}:
      sepPos = i
      break
  if sepPos >= 0:
    result.head = Path(substr(path, 0,
        if likely(sepPos >= 1): sepPos-1 else: 0
    ))
    result.tail = Path(substr(path, sepPos+1))
  else:
    when doslikeFileSystem:
      result.head = Path(drive)
      result.tail = Path(splitpath)
    else:
      result.head = Path("")
      result.tail = Path(path)

func splitPath*(path: Path): tuple[head, tail: Path] {.inline.} =
  splitPathImpl(path.string)

func extractFilename*(path: Path): Path =
  ## Extracts the filename of a given `path`.
  ##
  ## This is the same as ``name & ext`` from `splitFile(path) proc`_.
  ##
  ## See also:
  ## * `searchExtPos proc`_
  ## * `splitFile proc`_
  ## * `lastPathPart proc`_
  ## * `changeFileExt proc`_
  ## * `addFileExt proc`_
  runnableExamples:
    assert extractFilename("foo/bar/") == ""
    assert extractFilename("foo/bar") == "bar"
    assert extractFilename("foo/bar.baz") == "bar.baz"

  if path.len == 0 or path.string[path.len-1] in {DirSep, AltSep}:
    result = Path("")
  else:
    result = splitPath(path).tail
