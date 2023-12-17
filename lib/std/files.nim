## This module implements file handling.
##
## **See also:**
## * `paths module <paths.html>`_ for path manipulation

from std/paths import Path, ReadDirEffect, WriteDirEffect

from std/private/osfiles import fileExists, removeFile,
                                moveFile


proc fileExists*(filename: Path): bool {.inline, tags: [ReadDirEffect], sideEffect.} =
  ## Returns true if `filename` exists and is a regular file or symlink.
  ##
  ## Directories, device files, named pipes and sockets return false.
  result = fileExists(filename.string)

proc removeFile*(file: Path) {.inline, tags: [WriteDirEffect].} =
  ## Removes the `file`.
  ##
  ## If this fails, `OSError` is raised. This does not fail
  ## if the file never existed in the first place.
  ##
  ## On Windows, ignores the read-only attribute.
  ##
  ## See also:
  ## * `removeDir proc <dirs.html#removeDir>`_
  ## * `moveFile proc`_
  removeFile(file.string)

proc moveFile*(source, dest: Path) {.inline,
    tags: [ReadDirEffect, ReadIOEffect, WriteIOEffect].} =
  ## Moves a file from `source` to `dest`.
  ##
  ## Symlinks are not followed: if `source` is a symlink, it is itself moved,
  ## not its target.
  ##
  ## If this fails, `OSError` is raised.
  ## If `dest` already exists, it will be overwritten.
  ##
  ## Can be used to `rename files`:idx:.
  ##
  ## See also:
  ## * `moveDir proc <dirs.html#moveDir>`_
  ## * `removeFile proc`_
  moveFile(source.string, dest.string)
