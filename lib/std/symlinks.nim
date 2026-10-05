## This module implements symlink (symbolic link) handling.

## .. importdoc:: os.nim

from std/paths import Path, ReadDirEffect

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
  ## Returns the stored target of the symbolic link `symlinkPath`.
  ##
  ## This expands exactly one level of indirection, like POSIX `readlink`.
  ## If the target is itself a symbolic link, it is returned as-is rather than
  ## being expanded further.
  ##
  ## On POSIX, raises `OSError` if `symlinkPath` is not a symbolic link or if
  ## the target cannot be read.
  ##
  ## On Windows, this supports symbolic links and junctions by reading the
  ## reparse point payload directly. Unsupported reparse tags raise `OSError`.
  ##
  ## On Nintendo Switch this is currently a noop: `symlinkPath` is simply
  ## returned, without checking whether it is actually a symbolic link.
  ##
  ## See also:
  ## * `createSymlink proc`_
  result = Path(expandSymlink(symlinkPath.string))
