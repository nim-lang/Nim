import paths

import std/oserrors



const weirdTarget = defined(nimscript) or defined(js)

when weirdTarget:
  {.pragma: noWeirdTarget, error: "this proc is not available on the NimScript/js target".}
else:
  {.pragma: noWeirdTarget.}


when weirdTarget:
  discard
elif defined(windows):
  import winlean, times
elif defined(posix):
  import posix, times

  proc toTime(ts: Timespec): times.Time {.inline.} =
    result = initTime(ts.tv_sec.int64, ts.tv_nsec.int)
else:
  {.error: "OS module not ported to your operating system!".}


when defined(windows) and not weirdTarget:
  template deleteFile(file: untyped): untyped  = deleteFileW(file)
  template setFileAttributes(file, attrs: untyped): untyped =
    setFileAttributesW(file, attrs)

proc tryRemoveFile*(file: Path): bool {.tags: [WriteDirEffect], noWeirdTarget.} =
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
  result = true
  when defined(windows):
    let f = newWideCString(file.string)
    if deleteFile(f) == 0:
      result = false
      let err = getLastError()
      if err == ERROR_FILE_NOT_FOUND or err == ERROR_PATH_NOT_FOUND:
        result = true
      elif err == ERROR_ACCESS_DENIED and
         setFileAttributes(f, FILE_ATTRIBUTE_NORMAL) != 0 and
         deleteFile(f) != 0:
        result = true
  else:
    if unlink(file) != 0'i32 and errno != ENOENT:
      result = false

proc removeFile*(file: Path) {.tags: [WriteDirEffect], noWeirdTarget.} =
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
  if not tryRemoveFile(file):
    raiseOSError(osLastError(), file.string)

proc tryMoveFSObject(source, dest: string, isDir: bool): bool {.noWeirdTarget.} =
  ## Moves a file (or directory if `isDir` is true) from `source` to `dest`.
  ##
  ## Returns false in case of `EXDEV` error or `AccessDeniedError` on Windows (if `isDir` is true).
  ## In case of other errors `OSError` is raised.
  ## Returns true in case of success.
  when defined(windows):
    let s = newWideCString(source)
    let d = newWideCString(dest)
    result = moveFileExW(s, d, MOVEFILE_COPY_ALLOWED or MOVEFILE_REPLACE_EXISTING) != 0'i32
  else:
    result = c_rename(source, dest) == 0'i32

  if not result:
    let err = osLastError()
    let isAccessDeniedError =
      when defined(windows):
        const AccessDeniedError = OSErrorCode(5)
        isDir and err == AccessDeniedError
      else:
        err == EXDEV.OSErrorCode
    if not isAccessDeniedError:
      raiseOSError(err, $(source, dest))

proc moveFile*(source, dest: Path) {.
  tags: [ReadDirEffect, ReadIOEffect, WriteIOEffect], noWeirdTarget.} =
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

  if not tryMoveFSObject(source.string, dest.string, isDir = false):
    when defined(windows):
      doAssert false
    else:
      # Fallback to copy & del
      copyFile(source, dest, {cfSymlinkAsIs})
      try:
        removeFile(source)
      except:
        discard tryRemoveFile(dest)
        raise
