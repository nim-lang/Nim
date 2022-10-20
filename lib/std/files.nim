import paths

from std/private/osfiles import fileExists, tryRemoveFile, removeFile,
                                removeFile, moveFile


proc fileExists*(filename: Path): bool {.inline, tags: [ReadDirEffect].} =
  result = fileExists(filename.string)

proc tryRemoveFile*(file: Path): bool {.inline, tags: [WriteDirEffect].} =
  result = tryRemoveFile(file.string)

proc removeFile*(file: Path) {.inline, tags: [WriteDirEffect].} =
  removeFile(file.string)

proc moveFile*(source, dest: Path) {.inline,
    tags: [ReadDirEffect, ReadIOEffect, WriteIOEffect].} =
  moveFile(source.string, dest.string)
