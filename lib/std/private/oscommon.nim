include system/inclrtl

import ospaths2
import std/[oserrors]

when defined(nimPreviewSlimSystem):
  import std/[syncio, assertions, widestrs]

const weirdTarget* = defined(nimscript) or defined(js)


when weirdTarget:
  discard
elif defined(windows):
  import winlean, times
elif defined(posix):
  import posix, times

  proc c_rename(oldname, newname: cstring): cint {.
    importc: "rename", header: "<stdio.h>".}

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


when defined(windows) and not weirdTarget:
  when useWinUnicode:
    template wrapUnary(varname, winApiProc, arg: untyped) =
      var varname = winApiProc(newWideCString(arg))

    template wrapBinary(varname, winApiProc, arg, arg2: untyped) =
      var varname = winApiProc(newWideCString(arg), arg2)
    proc findFirstFile(a: string, b: var WIN32_FIND_DATA): Handle =
      result = findFirstFileW(newWideCString(a), b)
    template findNextFile(a, b: untyped): untyped = findNextFileW(a, b)
    template getCommandLine(): untyped = getCommandLineW()

    template getFilename(f: untyped): untyped =
      $cast[WideCString](addr(f.cFileName[0]))
  else:
    template findFirstFile(a, b: untyped): untyped = findFirstFileA(a, b)
    template findNextFile(a, b: untyped): untyped = findNextFileA(a, b)
    template getCommandLine(): untyped = getCommandLineA()

    template getFilename(f: untyped): untyped = $cstring(addr f.cFileName)

  proc skipFindData(f: WIN32_FIND_DATA): bool {.inline.} =
    # Note - takes advantage of null delimiter in the cstring
    const dot = ord('.')
    result = f.cFileName[0].int == dot and (f.cFileName[1].int == 0 or
             f.cFileName[1].int == dot and f.cFileName[2].int == 0)


type
  PathComponent* = enum   ## Enumeration specifying a path component.
    ##
    ## See also:
    ## * `walkDirRec iterator`_
    ## * `FileInfo object`_
    pcFile,               ## path refers to a file
    pcLinkToFile,         ## path refers to a symbolic link to a file
    pcDir,                ## path refers to a directory
    pcLinkToDir           ## path refers to a symbolic link to a directory


when defined(posix) and not weirdTarget:
  proc getSymlinkFileKind*(path: string): PathComponent =
    # Helper function.
    var s: Stat
    assert(path != "")
    if stat(path, s) == 0'i32 and S_ISDIR(s.st_mode):
      result = pcLinkToDir
    else:
      result = pcLinkToFile

proc tryMoveFSObject*(source, dest: string, isDir: bool): bool {.noWeirdTarget.} =
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

when not defined(windows):
  const maxSymlinkLen* = 1024

proc fileExists*(filename: string): bool {.rtl, extern: "nos$1",
                                          tags: [ReadDirEffect], noNimJs.} =
  ## Returns true if `filename` exists and is a regular file or symlink.
  ##
  ## Directories, device files, named pipes and sockets return false.
  ##
  ## See also:
  ## * `dirExists proc`_
  ## * `symlinkExists proc`_
  when defined(windows):
    when useWinUnicode:
      wrapUnary(a, getFileAttributesW, filename)
    else:
      var a = getFileAttributesA(filename)
    if a != -1'i32:
      result = (a and FILE_ATTRIBUTE_DIRECTORY) == 0'i32
  else:
    var res: Stat
    return stat(filename, res) >= 0'i32 and S_ISREG(res.st_mode)


proc dirExists*(dir: string): bool {.rtl, extern: "nos$1", tags: [ReadDirEffect],
                                     noNimJs.} =
  ## Returns true if the directory `dir` exists. If `dir` is a file, false
  ## is returned. Follows symlinks.
  ##
  ## See also:
  ## * `fileExists proc`_
  ## * `symlinkExists proc`_
  when defined(windows):
    when useWinUnicode:
      wrapUnary(a, getFileAttributesW, dir)
    else:
      var a = getFileAttributesA(dir)
    if a != -1'i32:
      result = (a and FILE_ATTRIBUTE_DIRECTORY) != 0'i32
  else:
    var res: Stat
    result = stat(dir, res) >= 0'i32 and S_ISDIR(res.st_mode)


proc symlinkExists*(link: string): bool {.rtl, extern: "nos$1",
                                          tags: [ReadDirEffect],
                                          noWeirdTarget.} =
  ## Returns true if the symlink `link` exists. Will return true
  ## regardless of whether the link points to a directory or file.
  ##
  ## See also:
  ## * `fileExists proc`_
  ## * `dirExists proc`_
  when defined(windows):
    when useWinUnicode:
      wrapUnary(a, getFileAttributesW, link)
    else:
      var a = getFileAttributesA(link)
    if a != -1'i32:
      # xxx see: bug #16784 (bug9); checking `IO_REPARSE_TAG_SYMLINK`
      # may also be needed.
      result = (a and FILE_ATTRIBUTE_REPARSE_POINT) != 0'i32
  else:
    var res: Stat
    result = lstat(link, res) >= 0'i32 and S_ISLNK(res.st_mode)
