import std/[os,strutils]

proc genTestPaths*(dir: string, paths: seq[string]) =
  ## generates a filesystem rooted under `dir` from given relative `paths`.
  ## `paths` ending in `/` are treated as directories.
  # xxx use this in tos.nim
  for a in paths:
    doAssert not a.isAbsolute
    doAssert a.len > 0
    let a = dir / a
    if a.endsWith("/"):
      createDir(a)
    else:
      createDir(a.parentDir)
      writeFile(a, "")
