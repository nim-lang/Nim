#
#
#            Nim's Runtime Library
#        (c) Copyright 2018 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## OS-Path normalization. Used by `os.nim` but also
## generally useful for dealing with paths.
##
## Unstable API.

# Yes, this uses import here, not include so that
# we don't end up exporting these symbols from pathnorm and os:
import includes/osseps

type
  PathIter* = object
    i, prev: int
    notFirst: bool

proc hasNext*(it: PathIter; x: string): bool =
  it.i < x.len

proc next*(it: var PathIter; x: string): (int, int) =
  it.prev = it.i
  if not it.notFirst and x[it.i] in {DirSep, AltSep}:
    # absolute path:
    inc it.i
    when doslikeFileSystem: # UNC paths have leading `\\`
      if hasNext(it, x) and x[it.i] == DirSep and
          it.i+1 < x.len and x[it.i+1] != DirSep:
        inc it.i
  else:
    while it.i < x.len and x[it.i] notin {DirSep, AltSep}: inc it.i
  if it.i > it.prev:
    result = (it.prev, it.i-1)
  elif hasNext(it, x):
    result = next(it, x)
  # skip all separators:
  while it.i < x.len and x[it.i] in {DirSep, AltSep}: inc it.i
  it.notFirst = true

iterator dirs(x: string): (int, int) =
  var it = default PathIter
  while hasNext(it, x): yield next(it, x)

proc isDot(x: string; bounds: (int, int)): bool =
  bounds[1] == bounds[0] and x[bounds[0]] == '.'

proc isDotDot(x: string; bounds: (int, int)): bool =
  bounds[1] == bounds[0] + 1 and x[bounds[0]] == '.' and x[bounds[0]+1] == '.'

proc isSlash(x: string; bounds: (int, int)): bool =
  bounds[1] == bounds[0] and x[bounds[0]] in {DirSep, AltSep}

when defined(windows):
  proc isWindowsDrive*(path: openArray[char]): bool =
    ## Returns true if `path` is a windows drive (length 3, ending in / or \).
    runnableExamples:
      assert isWindowsDrive(r"C:\")
      assert isWindowsDrive(r"b:/")
      for a in [r"c:\abc", r"c:abc", r"c:", "abc", r"\", "/", ""]: assert not isWindowsDrive(a)
    path.len == 3 and path[0] in {'a'..'z', 'A'..'Z'} and path[1] == ':' and path[2] in {DirSep, AltSep}

proc addNormalizePath*(x: string; result: var string; state: var int;
    dirSep = DirSep) =
  ## Low level proc. Undocumented.

  # state: 0th bit set if isAbsolute path. Other bits count
  # the number of path components.
  when defined(windows):
    if state == 0:
      # C:\ => C:\, C: => C:
      # this will be handled later: C:\foo\ => C:\foo, C:foo => C:foo
      if x.isWindowsDrive:
        result.add x[0]
        result.add x[1]
        result.add dirSep
        state = state or 1
        inc state, 2
        return
  var it: PathIter
  it.notFirst = (state shr 1) > 0
  if it.notFirst:
    while it.i < x.len and x[it.i] in {DirSep, AltSep}: inc it.i
  while hasNext(it, x):
    let b = next(it, x)
    if (state shr 1 == 0) and isSlash(x, b):
      if result.len == 0 or result[result.len - 1] notin {DirSep, AltSep}:
        result.add dirSep
      state = state or 1
    elif isDotDot(x, b):
      if (state shr 1) >= 1:
        var d = result.len
        # f/..
        # We could handle stripping trailing sep here: foo// => foo like this:
        # while (d-1) > (state and 1) and result[d-1] in {DirSep, AltSep}: dec d
        # but right now we instead handle it inside os.joinPath

        # strip path component: foo/bar => foo
        while (d-1) > (state and 1) and result[d-1] notin {DirSep, AltSep}:
          dec d
        if d > 0:
          setLen(result, d-1)
          dec state, 2
      else:
        if result.len > 0 and result[result.len - 1] notin {DirSep, AltSep}:
          result.add dirSep
        result.add substr(x, b[0], b[1])
    elif isDot(x, b):
      discard "discard the dot"
    elif b[1] >= b[0]:
      if result.len > 0 and result[result.len - 1] notin {DirSep, AltSep}:
        result.add dirSep
      result.add substr(x, b[0], b[1])
      inc state, 2
  if result == "" and x != "": result = "."

proc normalizePath*(path: string; dirSep = DirSep): string =
  runnableExamples:
    when defined(posix):
      doAssert normalizePath("./foo//bar/../baz") == "foo/baz"

  ## - Turns multiple slashes into single slashes.
  ## - Resolves `'/foo/../bar'` to `'/bar'`.
  ## - Removes `'./'` from the path, but `"foo/.."` becomes `"."`.
  result = newStringOfCap(path.len)
  var state = 0
  addNormalizePath(path, result, state, dirSep)
