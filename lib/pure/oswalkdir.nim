#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Compile-time only version for walkDir if you need it at compile-time
## for JavaScript.

type
  PathComponent* = enum ## Enumeration specifying a path component.
    pcFile,             ## path refers to a file
    pcLinkToFile,       ## path refers to a symbolic link to a file
    pcDir,              ## path refers to a directory
    pcLinkToDir         ## path refers to a symbolic link to a directory

proc staticWalkDir(dir: string; relative: bool): seq[
                  tuple[kind: PathComponent; path: string]] =
  discard

iterator walkDir*(dir: string; relative = false): tuple[kind: PathComponent;
    path: string] =
  for k, v in items(staticWalkDir(dir, relative)):
    yield (k, v)

iterator walkDirRec*(dir: string; filter = {pcFile, pcDir}): string =
  var stack = @[dir]
  while stack.len > 0:
    for k, p in walkDir(stack.pop()):
      if k in filter:
        case k
        of pcFile, pcLinkToFile: yield p
        of pcDir, pcLinkToDir: stack.add(p)
