#
#
#           The Nim Compiler
#        (c) Copyright 2026 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Filesystem path snapshots for one compiler invocation. Config scripts and
## long-lived IDE sessions use uncached paths instead.

import std/[os, tables]

type
  PathCache* = object
    currentDir: string
    canonicalPaths: Table[string, string]

proc reset*(cache: var PathCache) =
  ## Discard paths after code that can change the working directory or symlinks.
  cache = default(PathCache)

proc getCurrentDir*(cache: var PathCache): string =
  ## Capture the compiler's working directory on first use.
  if cache.currentDir.len == 0:
    cache.currentDir = os.getCurrentDir()
  result = cache.currentDir

proc expandFilename*(cache: var PathCache; path: string): string =
  ## Preserve filesystem canonicalization, including symlinks, on cache misses.
  ## Failed resolutions are not cached: generated files may appear later.
  let key =
    if path.isAbsolute: path
    else: cache.getCurrentDir() & '\0' & path
  if cache.canonicalPaths.hasKey(key):
    return cache.canonicalPaths[key]
  result = os.expandFilename(path)
  cache.canonicalPaths[key] = result

proc relativePath*(cache: var PathCache; path, base: string; sep = DirSep): string =
  ## Supply the known working directory when stdlib would otherwise query it.
  ## Keep the stdlib's lexical handling when both paths have the same kind.
  if path.len == 0:
    return ""
  var path = path
  var base = base
  if path.isAbsolute and not base.isAbsolute:
    base = absolutePath(base, cache.getCurrentDir())
  elif base.isAbsolute and not path.isAbsolute:
    path = absolutePath(path, cache.getCurrentDir())
  result = os.relativePath(path, base, sep)
