## This module implements directory handling.

from paths import Path, ReadDirEffect, WriteDirEffect

from std/private/osdirs import dirExists, createDir, existsOrCreateDir, removeDir,
                               moveDir, walkDir, setCurrentDir,
                               walkDirRec, PathComponent

export PathComponent

proc dirExists*(dir: Path): bool {.inline, tags: [ReadDirEffect], sideEffect.} =
  ## Returns true if the directory `dir` exists. If `dir` is a file, false
  ## is returned. Follows symlinks.
  result = dirExists(dir.string)

proc createDir*(dir: Path) {.inline, tags: [WriteDirEffect, ReadDirEffect].} =
  ## Creates the `directory`:idx: `dir`.
  ##
  ## The directory may contain several subdirectories that do not exist yet.
  ## The full path is created. If this fails, `OSError` is raised.
  ##
  ## It does **not** fail if the directory already exists because for
  ## most usages this does not indicate an error.
  ##
  ## See also:
  ## * `removeDir proc`_
  ## * `existsOrCreateDir proc`_
  ## * `moveDir proc`_
  createDir(dir.string)

proc existsOrCreateDir*(dir: Path): bool {.inline, tags: [WriteDirEffect, ReadDirEffect].} =
  ## Checks if a `directory`:idx: `dir` exists, and creates it otherwise.
  ##
  ## Does not create parent directories (raises `OSError` if parent directories do not exist).
  ## Returns `true` if the directory already exists, and `false` otherwise.
  ##
  ## See also:
  ## * `removeDir proc`_
  ## * `createDir proc`_
  ## * `moveDir proc`_
  result = existsOrCreateDir(dir.string)

proc removeDir*(dir: Path, checkDir = false
                ) {.inline, tags: [WriteDirEffect, ReadDirEffect].} =
  ## Removes the directory `dir` including all subdirectories and files
  ## in `dir` (recursively).
  ##
  ## If this fails, `OSError` is raised. This does not fail if the directory never
  ## existed in the first place, unless `checkDir` = true.
  ##
  ## See also:
  ## * `removeFile proc <files.html#removeFile>`_
  ## * `existsOrCreateDir proc`_
  ## * `createDir proc`_
  ## * `moveDir proc`_
  removeDir(dir.string, checkDir)

proc moveDir*(source, dest: Path) {.inline, tags: [ReadIOEffect, WriteIOEffect].} =
  ## Moves a directory from `source` to `dest`.
  ##
  ## Symlinks are not followed: if `source` contains symlinks, they themself are
  ## moved, not their target.
  ##
  ## If this fails, `OSError` is raised.
  ##
  ## See also:
  ## * `moveFile proc <files.html#moveFile>`_
  ## * `removeDir proc`_
  ## * `existsOrCreateDir proc`_
  ## * `createDir proc`_
  moveDir(source.string, dest.string)

iterator walkDir*(dir: Path; relative = false, checkDir = false,
                 skipSpecial = false):
    tuple[kind: PathComponent, path: Path] {.tags: [ReadDirEffect].} =
  ## Walks over the directory `dir` and yields for each directory or file in
  ## `dir`. The component type and full path for each item are returned.
  ##
  ## Walking is not recursive.
  ## * If `relative` is true (default: false)
  ##   the resulting path is shortened to be relative to ``dir``,
  ##   otherwise the full path is returned.
  ## * If `checkDir` is true, `OSError` is raised when `dir`
  ##   doesn't exist.
  ## * If `skipSpecial` is true, then (besides all directories) only *regular*
  ##   files (**without** special "file" objects like FIFOs, device files,
  ##   etc) will be yielded on Unix.
  for (k, p) in walkDir(dir.string, relative, checkDir, skipSpecial):
    yield (k, Path(p))

iterator walkDirRec*(dir: Path,
                     yieldFilter = {pcFile}, followFilter = {pcDir},
                     relative = false, checkDir = false, skipSpecial = false):
                    Path {.tags: [ReadDirEffect].} =
  ## Recursively walks over the directory `dir` and yields for each file
  ## or directory in `dir`.
  ##
  ## Options `relative`, `checkdir`, `skipSpecial` are explained in
  ## [walkDir iterator] description.
  ##
  ## .. warning:: Modifying the directory structure while the iterator
  ##   is traversing may result in undefined behavior!
  ##
  ## Walking is recursive. `followFilter` controls the behaviour of the iterator:
  ##
  ## =====================   =============================================
  ## yieldFilter             meaning
  ## =====================   =============================================
  ## ``pcFile``              yield real files (default)
  ## ``pcLinkToFile``        yield symbolic links to files
  ## ``pcDir``               yield real directories
  ## ``pcLinkToDir``         yield symbolic links to directories
  ## =====================   =============================================
  ##
  ## =====================   =============================================
  ## followFilter            meaning
  ## =====================   =============================================
  ## ``pcDir``               follow real directories (default)
  ## ``pcLinkToDir``         follow symbolic links to directories
  ## =====================   =============================================
  ##
  ##
  ## See also:
  ## * `walkDir iterator`_
  for p in walkDirRec(dir.string, yieldFilter, followFilter, relative,
                      checkDir, skipSpecial):
    yield Path(p)

proc setCurrentDir*(newDir: Path) {.inline, tags: [].} =
  ## Sets the `current working directory`:idx:; `OSError`
  ## is raised if `newDir` cannot been set.
  ##
  ## See also:
  ## * `getCurrentDir proc <paths.html#getCurrentDir>`_
  osdirs.setCurrentDir(newDir.string)
