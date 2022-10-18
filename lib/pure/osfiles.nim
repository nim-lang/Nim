include system/inclrtl
import std/private/since
import std/oserrors

import oscommon
export fileExists

import ospaths


when defined(nimPreviewSlimSystem):
  import std/[syncio, assertions, widestrs]

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


when weirdTarget:
  {.pragma: noWeirdTarget, error: "this proc is not available on the NimScript/js target".}
else:
  {.pragma: noWeirdTarget.}


when defined(nimscript):
  # for procs already defined in scriptconfig.nim
  template noNimJs(body): untyped = discard
elif defined(js):
  {.pragma: noNimJs, error: "this proc is not available on the js target".}
else:
  {.pragma: noNimJs.}

{.pragma: paths.}
{.pragma: files.}
{.pragma: dirs.}
{.pragma: symlinks.}
{.pragma: appdirs.}


const hasCCopyfile = defined(osx) and not defined(nimLegacyCopyFile)
  # xxx instead of `nimLegacyCopyFile`, support something like: `when osxVersion >= (10, 5)`

when hasCCopyfile:
  # `copyfile` API available since osx 10.5.
  {.push nodecl, header: "<copyfile.h>".}
  type
    copyfile_state_t {.nodecl.} = pointer
    copyfile_flags_t = cint
  proc copyfile_state_alloc(): copyfile_state_t
  proc copyfile_state_free(state: copyfile_state_t): cint
  proc c_copyfile(src, dst: cstring,  state: copyfile_state_t, flags: copyfile_flags_t): cint {.importc: "copyfile".}
  # replace with `let` pending bootstrap >= 1.4.0
  var
    COPYFILE_DATA {.nodecl.}: copyfile_flags_t
    COPYFILE_XATTR {.nodecl.}: copyfile_flags_t
  {.pop.}

type
  CopyFlag* = enum    ## Copy options.
    cfSymlinkAsIs,    ## Copy symlinks as symlinks
    cfSymlinkFollow,  ## Copy the files symlinks point to
    cfSymlinkIgnore   ## Ignore symlinks

const copyFlagSymlink = {cfSymlinkAsIs, cfSymlinkFollow, cfSymlinkIgnore}

proc copyFile*(source, dest: string, options = {cfSymlinkFollow}) {.rtl,
  extern: "nos$1", tags: [ReadDirEffect, ReadIOEffect, WriteIOEffect],
  noWeirdTarget, files.} =
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
  ## See also:
  ## * `CopyFlag enum`_
  ## * `copyDir proc`_
  ## * `copyFileWithPermissions proc`_
  ## * `tryRemoveFile proc`_
  ## * `removeFile proc`_
  ## * `moveFile proc`_

  doAssert card(copyFlagSymlink * options) == 1, "There should be exactly " &
                                                 "one cfSymlink* in options"
  let isSymlink = source.symlinkExists
  if isSymlink and (cfSymlinkIgnore in options or defined(windows)):
    return
  when defined(windows):
    when useWinUnicode:
      let s = newWideCString(source)
      let d = newWideCString(dest)
      if copyFileW(s, d, 0'i32) == 0'i32:
        raiseOSError(osLastError(), $(source, dest))
    else:
      if copyFileA(source, dest, 0'i32) == 0'i32:
        raiseOSError(osLastError(), $(source, dest))
  else:
    if isSymlink and cfSymlinkAsIs in options:
      createSymlink(expandSymlink(source), dest)
    else:
      when hasCCopyfile:
        let state = copyfile_state_alloc()
        # xxx `COPYFILE_STAT` could be used for one-shot
        # `copyFileWithPermissions`.
        let status = c_copyfile(source.cstring, dest.cstring, state,
                                COPYFILE_DATA)
        if status != 0:
          let err = osLastError()
          discard copyfile_state_free(state)
          raiseOSError(err, $(source, dest))
        let status2 = copyfile_state_free(state)
        if status2 != 0: raiseOSError(osLastError(), $(source, dest))
      else:
        # generic version of copyFile which works for any platform:
        const bufSize = 8000 # better for memory manager
        var d, s: File
        if not open(s, source):raiseOSError(osLastError(), source)
        if not open(d, dest, fmWrite):
          close(s)
          raiseOSError(osLastError(), dest)
        var buf = alloc(bufSize)
        while true:
          var bytesread = readBuffer(s, buf, bufSize)
          if bytesread > 0:
            var byteswritten = writeBuffer(d, buf, bytesread)
            if bytesread != byteswritten:
              dealloc(buf)
              close(s)
              close(d)
              raiseOSError(osLastError(), dest)
          if bytesread != bufSize: break
        dealloc(buf)
        close(s)
        flushFile(d)
        close(d)

proc copyFileToDir*(source, dir: string, options = {cfSymlinkFollow})
  {.noWeirdTarget, since: (1,3,7), files.} =
  ## Copies a file `source` into directory `dir`, which must exist.
  ##
  ## On non-Windows OSes, `options` specify the way file is copied; by default,
  ## if `source` is a symlink, copies the file symlink points to. `options` is
  ## ignored on Windows: symlinks are skipped.
  ##
  ## See also:
  ## * `CopyFlag enum`_
  ## * `copyFile proc`_
  if dir.len == 0: # treating "" as "." is error prone
    raise newException(ValueError, "dest is empty")
  copyFile(source, dir / source.lastPathPart, options)


proc copyFileWithPermissions*(source, dest: string,
                              ignorePermissionErrors = true,
                              options = {cfSymlinkFollow}) {.noWeirdTarget.} =
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
  ## * `CopyFlag enum`_
  ## * `copyFile proc`_
  ## * `copyDir proc`_
  ## * `tryRemoveFile proc`_
  ## * `removeFile proc`_
  ## * `moveFile proc`_
  ## * `copyDirWithPermissions proc`_
  copyFile(source, dest, options)
  when not defined(windows):
    try:
      setFilePermissions(dest, getFilePermissions(source), followSymlinks =
                         (cfSymlinkFollow in options))
    except:
      if not ignorePermissionErrors:
        raise

when not declared(ENOENT) and not defined(windows):
  when defined(nimscript):
    when not defined(haiku):
      const ENOENT = cint(2) # 2 on most systems including Solaris
    else:
      const ENOENT = cint(-2147459069)
  else:
    var ENOENT {.importc, header: "<errno.h>".}: cint

when defined(windows) and not weirdTarget:
  when useWinUnicode:
    template deleteFile(file: untyped): untyped  = deleteFileW(file)
    template setFileAttributes(file, attrs: untyped): untyped =
      setFileAttributesW(file, attrs)
  else:
    template deleteFile(file: untyped): untyped = deleteFileA(file)
    template setFileAttributes(file, attrs: untyped): untyped =
      setFileAttributesA(file, attrs)

proc tryRemoveFile*(file: string): bool {.rtl, extern: "nos$1", tags: [WriteDirEffect], noWeirdTarget, files.} =
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
    when useWinUnicode:
      let f = newWideCString(file)
    else:
      let f = file
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

proc removeFile*(file: string) {.rtl, extern: "nos$1", tags: [WriteDirEffect], noWeirdTarget.} =
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
    raiseOSError(osLastError(), file)

proc tryMoveFSObject(source, dest: string, isDir: bool): bool {.noWeirdTarget.} =
  ## Moves a file (or directory if `isDir` is true) from `source` to `dest`.
  ##
  ## Returns false in case of `EXDEV` error or `AccessDeniedError` on Windows (if `isDir` is true).
  ## In case of other errors `OSError` is raised.
  ## Returns true in case of success.
  when defined(windows):
    when useWinUnicode:
      let s = newWideCString(source)
      let d = newWideCString(dest)
      result = moveFileExW(s, d, MOVEFILE_COPY_ALLOWED or MOVEFILE_REPLACE_EXISTING) != 0'i32
    else:
      result = moveFileExA(source, dest, MOVEFILE_COPY_ALLOWED or MOVEFILE_REPLACE_EXISTING) != 0'i32
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

proc moveFile*(source, dest: string) {.rtl, extern: "nos$1",
  tags: [ReadDirEffect, ReadIOEffect, WriteIOEffect], noWeirdTarget, files.} =
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

  if not tryMoveFSObject(source, dest, isDir = false):
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