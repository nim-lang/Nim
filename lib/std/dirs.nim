import paths

from std/private/osdirs import dirExists, createDir, existsOrCreateDir, removeDir, moveDir


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
