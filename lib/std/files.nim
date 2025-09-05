## This module implements file handling.
##
## **See also:**
## * `paths module <paths.html>`_ for path manipulation

from std/paths import Path, ReadDirEffect, WriteDirEffect

from std/private/osfiles import fileExists, removeFile,
                                moveFile, copyFile, copyFileWithPermissions,
                                copyFileToDir, tryRemoveFile,
                                getFilePermissions, setFilePermissions,
                                CopyFlag, FilePermission

export CopyFlag, FilePermission


proc getFilePermissions*(filename: Path): set[FilePermission] {.inline, tags: [ReadDirEffect].} =
  ## Retrieves file permissions for `filename`.
  ##
  ## `OSError` is raised in case of an error.
  ## On Windows, only the ``readonly`` flag is checked, every other
  ## permission is available in any case.
  ##
  ## See also:
  ## * `setFilePermissions proc`_
  result = getFilePermissions(filename.string)

proc setFilePermissions*(filename: Path, permissions: set[FilePermission],
                         followSymlinks = true)
  {.inline, tags: [ReadDirEffect, WriteDirEffect].} =
  ## Sets the file permissions for `filename`.
  ##
  ## If `followSymlinks` set to true (default) and ``filename`` points to a
  ## symlink, permissions are set to the file symlink points to.
  ## `followSymlinks` set to false is a noop on Windows and some POSIX
  ## systems (including Linux) on which `lchmod` is either unavailable or always
  ## fails, given that symlinks permissions there are not observed.
  ##
  ## `OSError` is raised in case of an error.
  ## On Windows, only the ``readonly`` flag is changed, depending on
  ## ``fpUserWrite`` permission.
  ##
  ## See also:
  ## * `getFilePermissions proc`_
  setFilePermissions(filename.string, permissions, followSymlinks)

proc fileExists*(filename: Path): bool {.inline, tags: [ReadDirEffect], sideEffect.} =
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
  ## * `removeFile proc`_
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
  ## * `removeDir proc <dirs.html#removeDir>`_
  ## * `moveFile proc`_
  ## * `tryRemoveFile proc`_
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

proc copyFile*(source, dest: Path; options = cfSymlinkFollow; bufferSize = 16_384) {.inline, tags: [ReadDirEffect, ReadIOEffect, WriteIOEffect].} =
  ## Copies a file from `source` to `dest`, where `dest.parentDir` must exist.
  ##
  ## On non-Windows OSes, `options` specify the way file is copied; by default,
  ## if `source` is a symlink, copies the file symlink points to. `options` is
  ## ignored on Windows: symlinks are skipped.
  ##
  ## If this fails, `OSError` is raised.
  ##
  ## On the Windows platform this proc will
  ## copy the source file's attributes into dest.
  ##
  ## On other platforms you need
  ## to use `getFilePermissions`_ and
  ## `setFilePermissions`_
  ## procs
  ## to copy them by hand (or use the convenience `copyFileWithPermissions
  ## proc`_),
  ## otherwise `dest` will inherit the default permissions of a newly
  ## created file for the user.
  ##
  ## If `dest` already exists, the file attributes
  ## will be preserved and the content overwritten.
  ##
  ## On OSX, `copyfile` C api will be used (available since OSX 10.5) unless
  ## `-d:nimLegacyCopyFile` is used.
  ##
  ## `copyFile` allows to specify `bufferSize` to improve I/O performance.
  ## 
  ## See also:
  ## * `copyFileWithPermissions proc`_
  copyFile(source.string, dest.string, {options}, bufferSize)

proc copyFileWithPermissions*(source, dest: Path;
                              ignorePermissionErrors = true,
                              options = cfSymlinkFollow) {.inline.} =
  ## Copies a file from `source` to `dest` preserving file permissions.
  ##
  ## On non-Windows OSes, `options` specify the way file is copied; by default,
  ## if `source` is a symlink, copies the file symlink points to. `options` is
  ## ignored on Windows: symlinks are skipped.
  ##
  ## This is a wrapper proc around `copyFile`_,
  ## `getFilePermissions`_ and `setFilePermissions`_
  ## procs on non-Windows platforms.
  ##
  ## On Windows this proc is just a wrapper for `copyFile proc`_ since
  ## that proc already copies attributes.
  ##
  ## On non-Windows systems permissions are copied after the file itself has
  ## been copied, which won't happen atomically and could lead to a race
  ## condition. If `ignorePermissionErrors` is true (default), errors while
  ## reading/setting file attributes will be ignored, otherwise will raise
  ## `OSError`.
  ##
  ## See also:
  ## * `copyFile proc`_
  copyFileWithPermissions(source.string, dest.string,
                              ignorePermissionErrors, {options})

proc copyFileToDir*(source, dir: Path, options = cfSymlinkFollow; bufferSize = 16_384) {.inline.} =
  ## Copies a file `source` into directory `dir`, which must exist.
  ##
  ## On non-Windows OSes, `options` specify the way file is copied; by default,
  ## if `source` is a symlink, copies the file symlink points to. `options` is
  ## ignored on Windows: symlinks are skipped.
  ##
  ## `copyFileToDir` allows to specify `bufferSize` to improve I/O performance.
  copyFileToDir(source.string, dir.string, {options}, bufferSize)
