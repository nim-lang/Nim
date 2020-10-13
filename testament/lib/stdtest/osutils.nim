import std/[os]

proc genTestPaths*(dir: string, paths: seq[string]) =
  ## generates a filesystem rooted under `dir` from given relative `paths`.
  ## `paths` ending in `/` are treated as directories.
  # xxx use this in tos.nim
  for a in paths:
    doAssert a.isRelativePath
    if a.endsWith("/"):
      createDir(a)
    else:
      createDir(a.parentDir)
      
