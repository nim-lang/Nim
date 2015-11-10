
type
  PathComponent* = enum   ## Enumeration specifying a path component.
    pcFile,               ## path refers to a file
    pcLinkToFile,         ## path refers to a symbolic link to a file
    pcDir,                ## path refers to a directory
    pcLinkToDir           ## path refers to a symbolic link to a directory

proc staticWalkDir(dir: string; relative: bool): seq[
                  tuple[kind: PathComponent, path: string]] =
  discard

iterator walkDir*(dir: string; relative=false): tuple[kind: PathComponent, path: string] {.
  tags: [ReadDirEffect], compiletime.} =
  for k, v in staticWalkDir(dir, relative)):
    yield (k, v)
