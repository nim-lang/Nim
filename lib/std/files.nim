from paths import Path, ReadDirEffect, WriteDirEffect

from std/private/osfiles import fileExists, tryRemoveFile, removeFile,
                                removeFile, moveFile


proc fileExists*(filename: Path): bool {.inline, tags: [ReadDirEffect].} =
  ## Returns true if `filename` exists and is a regular file or symlink.
  ##
  ## Directories, device files, named pipes and sockets return false.
  result = fileExists(filename.string)

proc tryRemoveFile*(file: Path): bool {.inline, tags: [WriteDirEffect].} =
  ## Removes the `file`.
  ##
  ## If this fails, returns `false`. This does not fail
  ## if the file never existed in the first place.
  ##
  ## On Windows, ignores the read-only attribute.
  ##
  ## See also:
  ## * `copyFile proc`_
  ## * `copyFileWithPermissions proc`_
  ## * `removeFile proc`_
  ## * `moveFile proc`_
  result = tryRemoveFile(file.string)

proc removeFile*(file: Path) {.inline, tags: [WriteDirEffect].} =
  ## Removes the `file`.
  ##
  ## If this fails, `OSError` is raised. This does not fail
  ## if the file never existed in the first place.
  ##
  ## On Windows, ignores the read-only attribute.
  ##
  ## See also:
  ## * `removeDir proc`_
  ## * `copyFile proc`_
  ## * `copyFileWithPermissions proc`_
  ## * `tryRemoveFile proc`_
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
  ## * `moveDir proc`_
  ## * `copyFile proc`_
  ## * `copyFileWithPermissions proc`_
  ## * `removeFile proc`_
  ## * `tryRemoveFile proc`_
  moveFile(source.string, dest.string)
