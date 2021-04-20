##[
unstable API, internal use only for now.
this can eventually be moved to std/os and `walkDirRec` can be implemented in terms of this
to avoid duplication
]##

import std/[os]
when defined(windows):
  from strutils import replace

type
  PathEntry* = object
    kind*: PathComponent
    path*: string

iterator walkDirRecFilter*(dir: string, follow: proc(entry: PathEntry): bool = nil,
    relative = false, checkDir = true): PathEntry {.tags: [ReadDirEffect].} =
  ## Improved `os.walkDirRec`.
  #[
  note: a yieldFilter isn't needed because caller can filter at call site, without
  loss of generality, unlike `follow`.

  Future work:
  * need to document
  * add a `sort` option, which can be implemented efficiently only here, not at call site.
  * provide a way to do error reporting, which is tricky because iteration cannot be resumed
  ]#
  var stack = @["."]
  var checkDir = checkDir
  var entry: PathEntry
  while stack.len > 0:
    let d = stack.pop()
    for k, p in walkDir(dir / d, relative = true, checkDir = checkDir):
      let rel = d / p
      entry.kind = k
      if relative: entry.path = rel
      else: entry.path = dir / rel
      if k in {pcDir, pcLinkToDir}:
        if follow == nil or follow(entry): stack.add rel
      yield entry
    checkDir = false
      # We only check top-level dir, otherwise if a subdir is invalid (eg. wrong
      # permissions), it'll abort iteration and there would be no way to
      # continue iteration.

proc nativeToUnixPath*(path: string): string =
  # pending https://github.com/nim-lang/Nim/pull/13265
  doAssert not path.isAbsolute # not implemented here; absolute files need more care for the drive
  when DirSep == '\\':
    result = replace(path, '\\', '/')
  else: result = path

when isMainModule:
  import sugar
  for a in walkDirRecFilter(".", follow = a=>a.path.lastPathPart notin ["nimcache", ".git", ".csources", "bin"]):
    echo a
