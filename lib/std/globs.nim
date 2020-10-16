import std/os
import std/algorithm

type
  PathEntrySub* = object
    kind*: PathComponent
    path*: string
  PathEntry* = object
    kind*: PathComponent
    path*: string
      ## absolute or relative path wrt globbed dir
    depth*: int
      ## depth wrt globbed dir

iterator glob*(dir: string, relative = false, checkDir = true, includeRoot = false,
    follow: proc(entry: PathEntry): bool = nil,
    sortCmp: proc (x, y: PathEntrySub): int = nil,
    topFirst = true):
    PathEntry {.closure, tags: [ReadDirEffect].} =
  ## Recursively walks `dir` which must exist when checkDir=true (else raises `OSError`).
  ## Paths in `result.path` are relative to `dir` unless `relative=false`,
  ## `result.depth >= 1` is the tree depth relative to the root `dir` (at depth 0).
  ## if `follow != nil`, `glob` visits `entry` if `filter(entry) == true`.
  ## This is more flexible than `os.walkDirRec`.
  runnableExamples:
    import os,sugar
    if false:
      # list hidden files of depth <= 2 + 1 in your home.
      for e in glob(getHomeDir(), follow = a=>a.path.isHidden and a.depth <= 2):
        if e.kind in {pcFile, pcLinkToFile}: echo e.path
  #[
  note:
  * a yieldFilter, regex match etc isn't needed because caller can filter at
  call site, without loss of generality, unlike `follow`; this simplifies the API.
  * a closure iterator is used since we need multiple yield statements and it simplifies code.
    In practice optimized performance drops by less than 2%, likely 0 when filesystem is not "hot".

  Future work:
  * need to document
  * add a `sort` option, which can be implemented efficiently only here, not at call site.
  * provide a way to do error reporting, which is tricky because iteration cannot be resumed
  * `walkDirRec` can be implemented in terms of this to avoid duplication,
    modulo some refactoring.
  ]#
  echo()
  var stack = @[(0, ".")]
  var checkDir = checkDir
  var entry: PathEntry
  var dirsLevel: seq[PathEntrySub]
  if not dirExists(dir):
    if checkDir:
      raise newException(OSError, "invalid root dir: " & dir)
    else:
      return

  if includeRoot:
    if symlinkExists(dir):
      entry.kind = pcLinkToDir
    else:
      entry.kind = pcDir
    entry.path = if relative: "." else: dir
    normalizePath(entry.path)
    entry.depth = 0
    yield entry

  template processEntry(): untyped =
    let rel = d / p
    entry.depth = depth + 1
    entry.kind = k
    if relative: entry.path = rel
    else: entry.path = dir / rel
    normalizePath(entry.path) # pending https://github.com/timotheecour/Nim/issues/343
    if k in {pcDir, pcLinkToDir}:
      if follow == nil or follow(entry): stack.add (depth + 1, rel)
    entry

  while stack.len > 0:
    let (depth, d) = stack.pop()
    # checkDir is still needed here in first iteration because things could
    # fail for reasons other than `not dirExists`.

    if sortCmp != nil:
      dirsLevel.setLen 0
    # echo "...: ", d
    for k, p in walkDir(dir / d, relative = true, checkDir = checkDir):
      if sortCmp != nil:
        dirsLevel.add PathEntrySub(kind: k, path: p)
      else:
        yield processEntry()
    if sortCmp != nil:
      sort(dirsLevel, sortCmp)
      for ai in dirsLevel:
        let k = ai.kind
        let p = ai.path
        yield processEntry()

    checkDir = false
      # We only check top-level dir, otherwise if a subdir is invalid (eg. wrong
      # permissions), it'll abort iteration and there would be no way to
      # continue iteration.
