from paths import Path, ReadDirEffect, WriteDirEffect

from std/private/osdirs import dirExists, createDir, existsOrCreateDir, removeDir,
                               moveDir, walkPattern, walkFiles, walkDirs, walkDir,
                               walkDirRec, PathComponent

export PathComponent

proc dirExists*(dir: Path): bool {.tags: [ReadDirEffect].} =
  result = dirExists(dir.string)

proc createDir*(dir: Path) {.tags: [WriteDirEffect, ReadDirEffect].} =
  createDir(dir.string)

proc existsOrCreateDir*(dir: Path): bool {.tags: [WriteDirEffect, ReadDirEffect].} =
  result = existsOrCreateDir(dir.string)

proc removeDir*(dir: Path, checkDir = false
                ) {.tags: [WriteDirEffect, ReadDirEffect].} =
  removeDir(dir.string, checkDir)

proc moveDir*(source, dest: Path) {.tags: [ReadIOEffect, WriteIOEffect].} =
  moveDir(source.string, dest.string)

iterator walkPattern*(pattern: Path): Path {.tags: [ReadDirEffect].} =
  for p in walkPattern(pattern.string):
    yield Path(p)

iterator walkFiles*(pattern: Path): Path {.tags: [ReadDirEffect].} =
  for p in walkFiles(pattern.string):
    yield Path(p)

iterator walkDirs*(pattern: Path): Path {.tags: [ReadDirEffect].} =
  for p in walkDirs(pattern.string):
    yield Path(p)

iterator walkDir*(dir: Path; relative = false, checkDir = false):
  tuple[kind: PathComponent, path: Path] {.tags: [ReadDirEffect].} =
    for (k, p) in walkDir(dir.string, relative, checkDir):
      yield (k, Path(p))

iterator walkDirRec*(dir: Path,
                     yieldFilter = {pcFile}, followFilter = {pcDir},
                     relative = false, checkDir = false): Path {.tags: [ReadDirEffect].} =
  for p in walkDirRec(dir.string, yieldFilter, followFilter, relative, checkDir):
    yield Path(p)
