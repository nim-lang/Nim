## This module implements symlink (symbolic link) handling.

## .. importdoc:: os.nim

from paths import Path, ReadDirEffect

from std/private/ossymlinks import symlinkExists, createSymlink, expandSymlink

proc symlinkExists*(link: Path): bool {.inline, tags: [ReadDirEffect], sideEffect.} =
  ## Returns true if the symlink `link` exists. Will return true
  ## regardless of whether the link points to a directory or file.
  result = symlinkExists(link.string)

proc createSymlink*(src, dest: Path) {.inline.} =
  ## Create a symbolic link at `dest` which points to the item specified
  ## by `src`. On most operating systems, will fail if a link already exists.
  ##
  ## .. warning:: Some OS's (such as Microsoft Windows) restrict the creation
  ##   of symlinks to root users (administrators) or users with developer mode enabled.
  ##
  ## See also:
  ## * `createHardlink proc`_
  ## * `expandSymlink proc`_
  createSymlink(src.string, dest.string)

proc expandSymlink*(symlinkPath: Path): Path {.inline.} =
  ## Returns a string representing the path to which the symbolic link points.
  ##
  ## On Windows this is a noop, `symlinkPath` is simply returned.
  ##
  ## See also:
  ## * `createSymlink proc`_
  result = Path(expandSymlink(symlinkPath.string))
