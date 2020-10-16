import std/os
import std/algorithm
import std/deques

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
    epilogue*: bool
  GlobMode* = enum
    gDfs, gBfs
  FollowCallback* = proc(entry: PathEntry): bool
  SortCmpCallback* = proc (x, y: PathEntrySub): int

iterator glob*(dir: string, relative = false, checkDir = true, globMode = gDfs, includeRoot = false, includeEpilogue = false, followSymlinks = false,
    follow: FollowCallback = nil,
    sortCmp: SortCmpCallback = nil,
    topFirst = true):
    PathEntry {.tags: [ReadDirEffect].} =
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

  Future work:
  * provide a way to do error reporting, which is tricky because iteration cannot be resumed
  * `walkDirRec` can be implemented in terms of this to avoid duplication,
    modulo some refactoring.
  ]#
  var entry = PathEntry(depth: 0, path: ".")
  entry.kind = if symlinkExists(dir): pcLinkToDir else: pcDir
  # var stack: seq[PathEntry]
  var stack = initDeque[PathEntry]()

  var checkDir = checkDir
  if dirExists(dir):
    stack.addLast entry
  elif checkDir:
    raise newException(OSError, "invalid root dir: " & dir)

  var dirsLevel: seq[PathEntrySub]
  while stack.len > 0:
    let current = if globMode == gDfs: stack.popLast() else: stack.popFirst()
    entry.epilogue = current.epilogue
    entry.depth = current.depth
    entry.kind = current.kind
    entry.path = if relative: current.path else: dir / current.path
    normalizePath(entry.path) # pending https://github.com/timotheecour/Nim/issues/343

    if includeRoot or current.depth > 0:
      yield entry

    if (current.kind == pcDir or current.kind == pcLinkToDir and followSymlinks) and not current.epilogue:
      if follow == nil or follow(current):
        if sortCmp != nil:
          dirsLevel.setLen 0
        if includeEpilogue:
          stack.addLast PathEntry(depth: current.depth, path: current.path, kind: current.kind, epilogue: true)
        # checkDir is still needed here in first iteration because things could
        # fail for reasons other than `not dirExists`.
        for k, p in walkDir(dir / current.path, relative = true, checkDir = checkDir):
          if sortCmp != nil:
            dirsLevel.add PathEntrySub(kind: k, path: p)
          else:
            stack.addLast PathEntry(depth: current.depth + 1, path: current.path / p, kind: k)
        checkDir = false
          # We only check top-level dir, otherwise if a subdir is invalid (eg. wrong
          # permissions), it'll abort iteration and there would be no way to resume iteration.
        if sortCmp != nil:
          sort(dirsLevel, sortCmp)
          for i in 0..<dirsLevel.len:
            let j = if globMode == gDfs: dirsLevel.len-1-i else: i
            let ai = dirsLevel[j]
            stack.addLast PathEntry(depth: current.depth + 1, path: current.path / ai.path, kind: ai.kind)
