import paths

from std/private/ossymlinks import symlinkExists, createSymlink, expandSymlink


proc symlinkExists*(link: Path): bool {.tags: [ReadDirEffect].} =
  result = symlinkExists(link.string)

proc createSymlink*(src, dest: Path) =
  createSymlink(src.string, dest.string)

proc expandSymlink*(symlinkPath: Path): Path =
  result = expandSymlink(symlinkPath)
