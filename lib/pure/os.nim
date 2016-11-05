#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains basic operating system facilities like
## retrieving environment variables, reading command line arguments,
## working with directories, running shell commands, etc.
{.deadCodeElim: on.}

{.push debugger: off.}

include "system/inclrtl"

import
  strutils, times

when defined(windows):
  import winlean
elif defined(posix):
  import posix
else:
  {.error: "OS module not ported to your operating system!".}

include ospaths

when defined(posix):
  when NoFakeVars:
    const pathMax = 5000 # doesn't matter really. The concept of PATH_MAX
                         # doesn't work anymore on modern OSes.
  else:
    var
      pathMax {.importc: "PATH_MAX", header: "<stdlib.h>".}: cint

proc c_remove(filename: cstring): cint {.
  importc: "remove", header: "<stdio.h>".}
proc c_rename(oldname, newname: cstring): cint {.
  importc: "rename", header: "<stdio.h>".}
proc c_system(cmd: cstring): cint {.
  importc: "system", header: "<stdlib.h>".}
proc c_strerror(errnum: cint): cstring {.
  importc: "strerror", header: "<string.h>".}
proc c_strlen(a: cstring): cint {.
  importc: "strlen", header: "<string.h>", noSideEffect.}
proc c_getenv(env: cstring): cstring {.
  importc: "getenv", header: "<stdlib.h>".}
proc c_putenv(env: cstring): cint {.
  importc: "putenv", header: "<stdlib.h>".}
proc c_free(p: pointer) {.
  importc: "free", header: "<stdlib.h>".}

var errno {.importc, header: "<errno.h>".}: cint

proc osErrorMsg*(): string {.rtl, extern: "nos$1", deprecated.} =
  ## Retrieves the operating system's error flag, ``errno``.
  ## On Windows ``GetLastError`` is checked before ``errno``.
  ## Returns "" if no error occurred.
  ##
  ## **Deprecated since version 0.9.4**: use the other ``osErrorMsg`` proc.

  result = ""
  when defined(Windows):
    var err = getLastError()
    if err != 0'i32:
      when useWinUnicode:
        var msgbuf: WideCString
        if formatMessageW(0x00000100 or 0x00001000 or 0x00000200 or 0x000000FF,
                          nil, err, 0, addr(msgbuf), 0, nil) != 0'i32:
          result = $msgbuf
          if msgbuf != nil: localFree(cast[pointer](msgbuf))
      else:
        var msgbuf: cstring
        if formatMessageA(0x00000100 or 0x00001000 or 0x00000200 or 0x000000FF,
                          nil, err, 0, addr(msgbuf), 0, nil) != 0'i32:
          result = $msgbuf
          if msgbuf != nil: localFree(msgbuf)
  if errno != 0'i32:
    result = $os.c_strerror(errno)

{.push warning[deprecated]: off.}
proc raiseOSError*(msg: string = "") {.noinline, rtl, extern: "nos$1",
                                       deprecated.} =
  ## raises an OSError exception with the given message ``msg``.
  ## If ``msg == ""``, the operating system's error flag
  ## (``errno``) is converted to a readable error message. On Windows
  ## ``GetLastError`` is checked before ``errno``.
  ## If no error flag is set, the message ``unknown OS error`` is used.
  ##
  ## **Deprecated since version 0.9.4**: use the other ``raiseOSError`` proc.
  if len(msg) == 0:
    var m = osErrorMsg()
    raise newException(OSError, if m.len > 0: m else: "unknown OS error")
  else:
    raise newException(OSError, msg)
{.pop.}

when not defined(nimfix):
  {.deprecated: [osError: raiseOSError].}

proc `==`*(err1, err2: OSErrorCode): bool {.borrow.}
proc `$`*(err: OSErrorCode): string {.borrow.}

proc osErrorMsg*(errorCode: OSErrorCode): string =
  ## Converts an OS error code into a human readable string.
  ##
  ## The error code can be retrieved using the ``osLastError`` proc.
  ##
  ## If conversion fails, or ``errorCode`` is ``0`` then ``""`` will be
  ## returned.
  ##
  ## On Windows, the ``-d:useWinAnsi`` compilation flag can be used to
  ## make this procedure use the non-unicode Win API calls to retrieve the
  ## message.
  result = ""
  when defined(Windows):
    if errorCode != OSErrorCode(0'i32):
      when useWinUnicode:
        var msgbuf: WideCString
        if formatMessageW(0x00000100 or 0x00001000 or 0x00000200,
                        nil, errorCode.int32, 0, addr(msgbuf), 0, nil) != 0'i32:
          result = $msgbuf
          if msgbuf != nil: localFree(cast[pointer](msgbuf))
      else:
        var msgbuf: cstring
        if formatMessageA(0x00000100 or 0x00001000 or 0x00000200,
                        nil, errorCode.int32, 0, addr(msgbuf), 0, nil) != 0'i32:
          result = $msgbuf
          if msgbuf != nil: localFree(msgbuf)
  else:
    if errorCode != OSErrorCode(0'i32):
      result = $os.c_strerror(errorCode.int32)

proc raiseOSError*(errorCode: OSErrorCode; additionalInfo = "") {.noinline.} =
  ## Raises an ``OSError`` exception. The ``errorCode`` will determine the
  ## message, ``osErrorMsg`` will be used to get this message.
  ##
  ## The error code can be retrieved using the ``osLastError`` proc.
  ##
  ## If the error code is ``0`` or an error message could not be retrieved,
  ## the message ``unknown OS error`` will be used.
  var e: ref OSError; new(e)
  e.errorCode = errorCode.int32
  if additionalInfo.len == 0:
    e.msg = osErrorMsg(errorCode)
  else:
    e.msg = osErrorMsg(errorCode) & "\nAdditional info: " & additionalInfo
  if e.msg == "":
    e.msg = "unknown OS error"
  raise e

{.push stackTrace:off.}
proc osLastError*(): OSErrorCode =
  ## Retrieves the last operating system error code.
  ##
  ## This procedure is useful in the event when an OS call fails. In that case
  ## this procedure will return the error code describing the reason why the
  ## OS call failed. The ``OSErrorMsg`` procedure can then be used to convert
  ## this code into a string.
  ##
  ## **Warning**:
  ## The behaviour of this procedure varies between Windows and POSIX systems.
  ## On Windows some OS calls can reset the error code to ``0`` causing this
  ## procedure to return ``0``. It is therefore advised to call this procedure
  ## immediately after an OS call fails. On POSIX systems this is not a problem.

  when defined(windows):
    result = OSErrorCode(getLastError())
  else:
    result = OSErrorCode(errno)
{.pop.}

when defined(windows):
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
      $cast[WideCString](addr(f.cFilename[0]))
  else:
    template findFirstFile(a, b: untyped): untyped = findFirstFileA(a, b)
    template findNextFile(a, b: untyped): untyped = findNextFileA(a, b)
    template getCommandLine(): untyped = getCommandLineA()

    template getFilename(f: untyped): untyped = $f.cFilename

  proc skipFindData(f: WIN32_FIND_DATA): bool {.inline.} =
    # Note - takes advantage of null delimiter in the cstring
    const dot = ord('.')
    result = f.cFileName[0].int == dot and (f.cFileName[1].int == 0 or
             f.cFileName[1].int == dot and f.cFileName[2].int == 0)

proc existsFile*(filename: string): bool {.rtl, extern: "nos$1",
                                          tags: [ReadDirEffect].} =
  ## Returns true if the file exists, false otherwise.
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

proc existsDir*(dir: string): bool {.rtl, extern: "nos$1", tags: [ReadDirEffect].} =
  ## Returns true iff the directory `dir` exists. If `dir` is a file, false
  ## is returned.
  when defined(windows):
    when useWinUnicode:
      wrapUnary(a, getFileAttributesW, dir)
    else:
      var a = getFileAttributesA(dir)
    if a != -1'i32:
      result = (a and FILE_ATTRIBUTE_DIRECTORY) != 0'i32
  else:
    var res: Stat
    return stat(dir, res) >= 0'i32 and S_ISDIR(res.st_mode)

proc symlinkExists*(link: string): bool {.rtl, extern: "nos$1",
                                          tags: [ReadDirEffect].} =
  ## Returns true iff the symlink `link` exists. Will return true
  ## regardless of whether the link points to a directory or file.
  when defined(windows):
    when useWinUnicode:
      wrapUnary(a, getFileAttributesW, link)
    else:
      var a = getFileAttributesA(link)
    if a != -1'i32:
      result = (a and FILE_ATTRIBUTE_REPARSE_POINT) != 0'i32
  else:
    var res: Stat
    return lstat(link, res) >= 0'i32 and S_ISLNK(res.st_mode)

proc fileExists*(filename: string): bool {.inline.} =
  ## Synonym for existsFile
  existsFile(filename)

proc dirExists*(dir: string): bool {.inline.} =
  ## Synonym for existsDir
  existsDir(dir)

proc getLastModificationTime*(file: string): Time {.rtl, extern: "nos$1".} =
  ## Returns the `file`'s last modification time.
  when defined(posix):
    var res: Stat
    if stat(file, res) < 0'i32: raiseOSError(osLastError())
    return res.st_mtime
  else:
    var f: WIN32_FIND_DATA
    var h = findFirstFile(file, f)
    if h == -1'i32: raiseOSError(osLastError())
    result = winTimeToUnixTime(rdFileTime(f.ftLastWriteTime))
    findClose(h)

proc getLastAccessTime*(file: string): Time {.rtl, extern: "nos$1".} =
  ## Returns the `file`'s last read or write access time.
  when defined(posix):
    var res: Stat
    if stat(file, res) < 0'i32: raiseOSError(osLastError())
    return res.st_atime
  else:
    var f: WIN32_FIND_DATA
    var h = findFirstFile(file, f)
    if h == -1'i32: raiseOSError(osLastError())
    result = winTimeToUnixTime(rdFileTime(f.ftLastAccessTime))
    findClose(h)

proc getCreationTime*(file: string): Time {.rtl, extern: "nos$1".} =
  ## Returns the `file`'s creation time.
  ##
  ## **Note:** Under POSIX OS's, the returned time may actually be the time at
  ## which the file's attribute's were last modified. See
  ## `here <https://github.com/nim-lang/Nim/issues/1058>`_ for details.
  when defined(posix):
    var res: Stat
    if stat(file, res) < 0'i32: raiseOSError(osLastError())
    return res.st_ctime
  else:
    var f: WIN32_FIND_DATA
    var h = findFirstFile(file, f)
    if h == -1'i32: raiseOSError(osLastError())
    result = winTimeToUnixTime(rdFileTime(f.ftCreationTime))
    findClose(h)

proc fileNewer*(a, b: string): bool {.rtl, extern: "nos$1".} =
  ## Returns true if the file `a` is newer than file `b`, i.e. if `a`'s
  ## modification time is later than `b`'s.
  when defined(posix):
    result = getLastModificationTime(a) - getLastModificationTime(b) >= 0
    # Posix's resolution sucks so, we use '>=' for posix.
  else:
    result = getLastModificationTime(a) - getLastModificationTime(b) > 0

proc getCurrentDir*(): string {.rtl, extern: "nos$1", tags: [].} =
  ## Returns the `current working directory`:idx:.
  when defined(windows):
    var bufsize = MAX_PATH.int32
    when useWinUnicode:
      var res = newWideCString("", bufsize)
      while true:
        var L = getCurrentDirectoryW(bufsize, res)
        if L == 0'i32:
          raiseOSError(osLastError())
        elif L > bufsize:
          res = newWideCString("", L)
          bufsize = L
        else:
          result = res$L
          break
    else:
      result = newString(bufsize)
      while true:
        var L = getCurrentDirectoryA(bufsize, result)
        if L == 0'i32:
          raiseOSError(osLastError())
        elif L > bufsize:
          result = newString(L)
          bufsize = L
        else:
          setLen(result, L)
          break
  else:
    var bufsize = 1024 # should be enough
    result = newString(bufsize)
    while true:
      if getcwd(result, bufsize) != nil:
        setLen(result, c_strlen(result))
        break
      else:
        let err = osLastError()
        if err.int32 == ERANGE:
          bufsize = bufsize shl 1
          doAssert(bufsize >= 0)
          result = newString(bufsize)
        else:
          raiseOSError(osLastError())

proc setCurrentDir*(newDir: string) {.inline, tags: [].} =
  ## Sets the `current working directory`:idx:; `OSError` is raised if
  ## `newDir` cannot been set.
  when defined(Windows):
    when useWinUnicode:
      if setCurrentDirectoryW(newWideCString(newDir)) == 0'i32:
        raiseOSError(osLastError())
    else:
      if setCurrentDirectoryA(newDir) == 0'i32: raiseOSError(osLastError())
  else:
    if chdir(newDir) != 0'i32: raiseOSError(osLastError())

proc expandFilename*(filename: string): string {.rtl, extern: "nos$1",
  tags: [ReadDirEffect].} =
  ## Returns the full (`absolute`:idx:) path of the file `filename`,
  ## raises OSError in case of an error.
  when defined(windows):
    var bufsize = MAX_PATH.int32
    when useWinUnicode:
      var unused: WideCString = nil
      var res = newWideCString("", bufsize)
      while true:
        var L = getFullPathNameW(newWideCString(filename), bufsize, res, unused)
        if L == 0'i32:
          raiseOSError(osLastError())
        elif L > bufsize:
          res = newWideCString("", L)
          bufsize = L
        else:
          result = res$L
          break
    else:
      var unused: cstring = nil
      result = newString(bufsize)
      while true:
        var L = getFullPathNameA(filename, bufsize, result, unused)
        if L == 0'i32:
          raiseOSError(osLastError())
        elif L > bufsize:
          result = newString(L)
          bufsize = L
        else:
          setLen(result, L)
          break
  else:
    # according to Posix we don't need to allocate space for result pathname.
    # But we need to free return value with free(3).
    var r = realpath(filename, nil)
    if r.isNil:
      raiseOSError(osLastError())
    else:
      result = $r
      c_free(cast[pointer](r))

when defined(Windows):
  proc openHandle(path: string, followSymlink=true): Handle =
    var flags = FILE_FLAG_BACKUP_SEMANTICS or FILE_ATTRIBUTE_NORMAL
    if not followSymlink:
      flags = flags or FILE_FLAG_OPEN_REPARSE_POINT

    when useWinUnicode:
      result = createFileW(
        newWideCString(path), 0'i32,
        FILE_SHARE_DELETE or FILE_SHARE_READ or FILE_SHARE_WRITE,
        nil, OPEN_EXISTING, flags, 0
        )
    else:
      result = createFileA(
        path, 0'i32,
        FILE_SHARE_DELETE or FILE_SHARE_READ or FILE_SHARE_WRITE,
        nil, OPEN_EXISTING, flags, 0
        )

proc sameFile*(path1, path2: string): bool {.rtl, extern: "nos$1",
  tags: [ReadDirEffect].} =
  ## Returns true if both pathname arguments refer to the same physical
  ## file or directory. Raises an exception if any of the files does not
  ## exist or information about it can not be obtained.
  ##
  ## This proc will return true if given two alternative hard-linked or
  ## sym-linked paths to the same file or directory.
  when defined(Windows):
    var success = true
    var f1 = openHandle(path1)
    var f2 = openHandle(path2)

    var lastErr: OSErrorCode
    if f1 != INVALID_HANDLE_VALUE and f2 != INVALID_HANDLE_VALUE:
      var fi1, fi2: BY_HANDLE_FILE_INFORMATION

      if getFileInformationByHandle(f1, addr(fi1)) != 0 and
         getFileInformationByHandle(f2, addr(fi2)) != 0:
        result = fi1.dwVolumeSerialNumber == fi2.dwVolumeSerialNumber and
                 fi1.nFileIndexHigh == fi2.nFileIndexHigh and
                 fi1.nFileIndexLow == fi2.nFileIndexLow
      else:
        lastErr = osLastError()
        success = false
    else:
      lastErr = osLastError()
      success = false

    discard closeHandle(f1)
    discard closeHandle(f2)

    if not success: raiseOSError(lastErr)
  else:
    var a, b: Stat
    if stat(path1, a) < 0'i32 or stat(path2, b) < 0'i32:
      raiseOSError(osLastError())
    else:
      result = a.st_dev == b.st_dev and a.st_ino == b.st_ino

proc sameFileContent*(path1, path2: string): bool {.rtl, extern: "nos$1",
  tags: [ReadIOEffect].} =
  ## Returns true if both pathname arguments refer to files with identical
  ## binary content.
  const
    bufSize = 8192 # 8K buffer
  var
    a, b: File
  if not open(a, path1): return false
  if not open(b, path2):
    close(a)
    return false
  var bufA = alloc(bufSize)
  var bufB = alloc(bufSize)
  while true:
    var readA = readBuffer(a, bufA, bufSize)
    var readB = readBuffer(b, bufB, bufSize)
    if readA != readB:
      result = false
      break
    if readA == 0:
      result = true
      break
    result = equalMem(bufA, bufB, readA)
    if not result: break
    if readA != bufSize: break # end of file
  dealloc(bufA)
  dealloc(bufB)
  close(a)
  close(b)

type
  FilePermission* = enum   ## file access permission; modelled after UNIX
    fpUserExec,            ## execute access for the file owner
    fpUserWrite,           ## write access for the file owner
    fpUserRead,            ## read access for the file owner
    fpGroupExec,           ## execute access for the group
    fpGroupWrite,          ## write access for the group
    fpGroupRead,           ## read access for the group
    fpOthersExec,          ## execute access for others
    fpOthersWrite,         ## write access for others
    fpOthersRead           ## read access for others

{.deprecated: [TFilePermission: FilePermission].}

proc getFilePermissions*(filename: string): set[FilePermission] {.
  rtl, extern: "nos$1", tags: [ReadDirEffect].} =
  ## retrieves file permissions for `filename`. `OSError` is raised in case of
  ## an error. On Windows, only the ``readonly`` flag is checked, every other
  ## permission is available in any case.
  when defined(posix):
    var a: Stat
    if stat(filename, a) < 0'i32: raiseOSError(osLastError())
    result = {}
    if (a.st_mode and S_IRUSR) != 0'i32: result.incl(fpUserRead)
    if (a.st_mode and S_IWUSR) != 0'i32: result.incl(fpUserWrite)
    if (a.st_mode and S_IXUSR) != 0'i32: result.incl(fpUserExec)

    if (a.st_mode and S_IRGRP) != 0'i32: result.incl(fpGroupRead)
    if (a.st_mode and S_IWGRP) != 0'i32: result.incl(fpGroupWrite)
    if (a.st_mode and S_IXGRP) != 0'i32: result.incl(fpGroupExec)

    if (a.st_mode and S_IROTH) != 0'i32: result.incl(fpOthersRead)
    if (a.st_mode and S_IWOTH) != 0'i32: result.incl(fpOthersWrite)
    if (a.st_mode and S_IXOTH) != 0'i32: result.incl(fpOthersExec)
  else:
    when useWinUnicode:
      wrapUnary(res, getFileAttributesW, filename)
    else:
      var res = getFileAttributesA(filename)
    if res == -1'i32: raiseOSError(osLastError())
    if (res and FILE_ATTRIBUTE_READONLY) != 0'i32:
      result = {fpUserExec, fpUserRead, fpGroupExec, fpGroupRead,
                fpOthersExec, fpOthersRead}
    else:
      result = {fpUserExec..fpOthersRead}

proc setFilePermissions*(filename: string, permissions: set[FilePermission]) {.
  rtl, extern: "nos$1", tags: [WriteDirEffect].} =
  ## sets the file permissions for `filename`. `OSError` is raised in case of
  ## an error. On Windows, only the ``readonly`` flag is changed, depending on
  ## ``fpUserWrite``.
  when defined(posix):
    var p = 0'i32
    if fpUserRead in permissions: p = p or S_IRUSR
    if fpUserWrite in permissions: p = p or S_IWUSR
    if fpUserExec in permissions: p = p or S_IXUSR

    if fpGroupRead in permissions: p = p or S_IRGRP
    if fpGroupWrite in permissions: p = p or S_IWGRP
    if fpGroupExec in permissions: p = p or S_IXGRP

    if fpOthersRead in permissions: p = p or S_IROTH
    if fpOthersWrite in permissions: p = p or S_IWOTH
    if fpOthersExec in permissions: p = p or S_IXOTH

    if chmod(filename, p) != 0: raiseOSError(osLastError())
  else:
    when useWinUnicode:
      wrapUnary(res, getFileAttributesW, filename)
    else:
      var res = getFileAttributesA(filename)
    if res == -1'i32: raiseOSError(osLastError())
    if fpUserWrite in permissions:
      res = res and not FILE_ATTRIBUTE_READONLY
    else:
      res = res or FILE_ATTRIBUTE_READONLY
    when useWinUnicode:
      wrapBinary(res2, setFileAttributesW, filename, res)
    else:
      var res2 = setFileAttributesA(filename, res)
    if res2 == - 1'i32: raiseOSError(osLastError())

proc copyFile*(source, dest: string) {.rtl, extern: "nos$1",
  tags: [ReadIOEffect, WriteIOEffect].} =
  ## Copies a file from `source` to `dest`.
  ##
  ## If this fails, `OSError` is raised. On the Windows platform this proc will
  ## copy the source file's attributes into dest. On other platforms you need
  ## to use `getFilePermissions() <#getFilePermissions>`_ and
  ## `setFilePermissions() <#setFilePermissions>`_ to copy them by hand (or use
  ## the convenience `copyFileWithPermissions() <#copyFileWithPermissions>`_
  ## proc), otherwise `dest` will inherit the default permissions of a newly
  ## created file for the user. If `dest` already exists, the file attributes
  ## will be preserved and the content overwritten.
  when defined(Windows):
    when useWinUnicode:
      let s = newWideCString(source)
      let d = newWideCString(dest)
      if copyFileW(s, d, 0'i32) == 0'i32: raiseOSError(osLastError())
    else:
      if copyFileA(source, dest, 0'i32) == 0'i32: raiseOSError(osLastError())
  else:
    # generic version of copyFile which works for any platform:
    const bufSize = 8000 # better for memory manager
    var d, s: File
    if not open(s, source): raiseOSError(osLastError())
    if not open(d, dest, fmWrite):
      close(s)
      raiseOSError(osLastError())
    var buf = alloc(bufSize)
    while true:
      var bytesread = readBuffer(s, buf, bufSize)
      if bytesread > 0:
        var byteswritten = writeBuffer(d, buf, bytesread)
        if bytesread != byteswritten:
          dealloc(buf)
          close(s)
          close(d)
          raiseOSError(osLastError())
      if bytesread != bufSize: break
    dealloc(buf)
    close(s)
    flushFile(d)
    close(d)

proc moveFile*(source, dest: string) {.rtl, extern: "nos$1",
  tags: [ReadIOEffect, WriteIOEffect].} =
  ## Moves a file from `source` to `dest`. If this fails, `OSError` is raised.
  when defined(Windows):
    when useWinUnicode:
      let s = newWideCString(source)
      let d = newWideCString(dest)
      if moveFileW(s, d) == 0'i32: raiseOSError(osLastError())
    else:
      if moveFileA(source, dest) == 0'i32: raiseOSError(osLastError())
  else:
    if c_rename(source, dest) != 0'i32:
      raiseOSError(osLastError(), $strerror(errno))

when not declared(ENOENT) and not defined(Windows):
  when NoFakeVars:
    const ENOENT = cint(2) # 2 on most systems including Solaris
  else:
    var ENOENT {.importc, header: "<errno.h>".}: cint

when defined(Windows):
  when useWinUnicode:
    template deleteFile(file: untyped): untyped  = deleteFileW(file)
    template setFileAttributes(file, attrs: untyped): untyped =
      setFileAttributesW(file, attrs)
  else:
    template deleteFile(file: untyped): untyped = deleteFileA(file)
    template setFileAttributes(file, attrs: untyped): untyped =
      setFileAttributesA(file, attrs)

proc removeFile*(file: string) {.rtl, extern: "nos$1", tags: [WriteDirEffect].} =
  ## Removes the `file`. If this fails, `OSError` is raised. This does not fail
  ## if the file never existed in the first place.
  ## On Windows, ignores the read-only attribute.
  when defined(Windows):
    when useWinUnicode:
      let f = newWideCString(file)
    else:
      let f = file
    if deleteFile(f) == 0:
      if getLastError() == ERROR_ACCESS_DENIED:
        if setFileAttributes(f, FILE_ATTRIBUTE_NORMAL) == 0:
          raiseOSError(osLastError())
        if deleteFile(f) == 0:
          raiseOSError(osLastError())
  else:
    if c_remove(file) != 0'i32 and errno != ENOENT:
      raiseOSError(osLastError(), $strerror(errno))

proc execShellCmd*(command: string): int {.rtl, extern: "nos$1",
  tags: [ExecIOEffect].} =
  ## Executes a `shell command`:idx:.
  ##
  ## Command has the form 'program args' where args are the command
  ## line arguments given to program. The proc returns the error code
  ## of the shell when it has finished. The proc does not return until
  ## the process has finished. To execute a program without having a
  ## shell involved, use the `execProcess` proc of the `osproc`
  ## module.
  when defined(linux):
    result = c_system(command) shr 8
  else:
    result = c_system(command)

# Environment handling cannot be put into RTL, because the ``envPairs``
# iterator depends on ``environment``.

var
  envComputed {.threadvar.}: bool
  environment {.threadvar.}: seq[string]

when defined(windows):
  # because we support Windows GUI applications, things get really
  # messy here...
  when useWinUnicode:
    when defined(cpp):
      proc strEnd(cstr: WideCString, c = 0'i32): WideCString {.
        importcpp: "(NI16*)wcschr((const wchar_t *)#, #)", header: "<string.h>".}
    else:
      proc strEnd(cstr: WideCString, c = 0'i32): WideCString {.
        importc: "wcschr", header: "<string.h>".}
  else:
    proc strEnd(cstr: cstring, c = 0'i32): cstring {.
      importc: "strchr", header: "<string.h>".}

  proc getEnvVarsC() =
    if not envComputed:
      environment = @[]
      when useWinUnicode:
        var
          env = getEnvironmentStringsW()
          e = env
        if e == nil: return # an error occurred
        while true:
          var eend = strEnd(e)
          add(environment, $e)
          e = cast[WideCString](cast[ByteAddress](eend)+2)
          if eend[1].int == 0: break
        discard freeEnvironmentStringsW(env)
      else:
        var
          env = getEnvironmentStringsA()
          e = env
        if e == nil: return # an error occurred
        while true:
          var eend = strEnd(e)
          add(environment, $e)
          e = cast[cstring](cast[ByteAddress](eend)+1)
          if eend[1] == '\0': break
        discard freeEnvironmentStringsA(env)
      envComputed = true

else:
  const
    useNSGetEnviron = defined(macosx) and not defined(ios)

  when useNSGetEnviron:
    # From the manual:
    # Shared libraries and bundles don't have direct access to environ,
    # which is only available to the loader ld(1) when a complete program
    # is being linked.
    # The environment routines can still be used, but if direct access to
    # environ is needed, the _NSGetEnviron() routine, defined in
    # <crt_externs.h>, can be used to retrieve the address of environ
    # at runtime.
    proc NSGetEnviron(): ptr cstringArray {.
      importc: "_NSGetEnviron", header: "<crt_externs.h>".}
  else:
    var gEnv {.importc: "environ".}: cstringArray

  proc getEnvVarsC() =
    # retrieves the variables of char** env of C's main proc
    if not envComputed:
      environment = @[]
      when useNSGetEnviron:
        var gEnv = NSGetEnviron()[]
      var i = 0
      while true:
        if gEnv[i] == nil: break
        add environment, $gEnv[i]
        inc(i)
      envComputed = true

proc findEnvVar(key: string): int =
  getEnvVarsC()
  var temp = key & '='
  for i in 0..high(environment):
    if startsWith(environment[i], temp): return i
  return -1

proc getEnv*(key: string): TaintedString {.tags: [ReadEnvEffect].} =
  ## Returns the value of the `environment variable`:idx: named `key`.
  ##
  ## If the variable does not exist, "" is returned. To distinguish
  ## whether a variable exists or it's value is just "", call
  ## `existsEnv(key)`.
  var i = findEnvVar(key)
  if i >= 0:
    return TaintedString(substr(environment[i], find(environment[i], '=')+1))
  else:
    var env = c_getenv(key)
    if env == nil: return TaintedString("")
    result = TaintedString($env)

proc existsEnv*(key: string): bool {.tags: [ReadEnvEffect].} =
  ## Checks whether the environment variable named `key` exists.
  ## Returns true if it exists, false otherwise.
  if c_getenv(key) != nil: return true
  else: return findEnvVar(key) >= 0

proc putEnv*(key, val: string) {.tags: [WriteEnvEffect].} =
  ## Sets the value of the `environment variable`:idx: named `key` to `val`.
  ## If an error occurs, `EInvalidEnvVar` is raised.

  # Note: by storing the string in the environment sequence,
  # we guarantee that we don't free the memory before the program
  # ends (this is needed for POSIX compliance). It is also needed so that
  # the process itself may access its modified environment variables!
  var indx = findEnvVar(key)
  if indx >= 0:
    environment[indx] = key & '=' & val
  else:
    add environment, (key & '=' & val)
    indx = high(environment)
  when defined(unix):
    if c_putenv(environment[indx]) != 0'i32:
      raiseOSError(osLastError())
  else:
    when useWinUnicode:
      var k = newWideCString(key)
      var v = newWideCString(val)
      if setEnvironmentVariableW(k, v) == 0'i32: raiseOSError(osLastError())
    else:
      if setEnvironmentVariableA(key, val) == 0'i32: raiseOSError(osLastError())

iterator envPairs*(): tuple[key, value: TaintedString] {.tags: [ReadEnvEffect].} =
  ## Iterate over all `environments variables`:idx:. In the first component
  ## of the tuple is the name of the current variable stored, in the second
  ## its value.
  getEnvVarsC()
  for i in 0..high(environment):
    var p = find(environment[i], '=')
    yield (TaintedString(substr(environment[i], 0, p-1)),
           TaintedString(substr(environment[i], p+1)))

# Templates for filtering directories and files
when defined(windows):
  template isDir(f: WIN32_FIND_DATA): bool =
    (f.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) != 0'i32
  template isFile(f: WIN32_FIND_DATA): bool =
    not isDir(f)
else:
  template isDir(f: string): bool =
    dirExists(f)
  template isFile(f: string): bool =
    fileExists(f)

template defaultWalkFilter(item): bool =
  ## Walk filter used to return true on both
  ## files and directories
  true

template walkCommon(pattern: string, filter) =
  ## Common code for getting the files and directories with the
  ## specified `pattern`
  when defined(windows):
    var
      f: WIN32_FIND_DATA
      res: int
    res = findFirstFile(pattern, f)
    if res != -1:
      defer: findClose(res)
      while true:
        if not skipFindData(f) and filter(f):
          # Windows bug/gotcha: 't*.nim' matches 'tfoo.nims' -.- so we check
          # that the file extensions have the same length ...
          let ff = getFilename(f)
          let dotPos = searchExtPos(pattern)
          let idx = ff.len - pattern.len + dotPos
          if dotPos < 0 or idx >= ff.len or ff[idx] == '.' or
              pattern[dotPos+1] == '*':
            yield splitFile(pattern).dir / extractFilename(ff)
        if findNextFile(res, f) == 0'i32: break
  else: # here we use glob
    var
      f: Glob
      res: int
    f.gl_offs = 0
    f.gl_pathc = 0
    f.gl_pathv = nil
    res = glob(pattern, 0, nil, addr(f))
    defer: globfree(addr(f))
    if res == 0:
      for i in 0.. f.gl_pathc - 1:
        assert(f.gl_pathv[i] != nil)
        let path = $f.gl_pathv[i]
        if filter(path):
          yield path

iterator walkPattern*(pattern: string): string {.tags: [ReadDirEffect].} =
  ## Iterate over all the files and directories that match the `pattern`.
  ## On POSIX this uses the `glob`:idx: call.
  ##
  ## `pattern` is OS dependent, but at least the "\*.ext"
  ## notation is supported.
  walkCommon(pattern, defaultWalkFilter)

iterator walkFiles*(pattern: string): string {.tags: [ReadDirEffect].} =
  ## Iterate over all the files that match the `pattern`. On POSIX this uses
  ## the `glob`:idx: call.
  ##
  ## `pattern` is OS dependent, but at least the "\*.ext"
  ## notation is supported.
  walkCommon(pattern, isFile)

iterator walkDirs*(pattern: string): string {.tags: [ReadDirEffect].} =
  ## Iterate over all the directories that match the `pattern`.
  ## On POSIX this uses the `glob`:idx: call.
  ##
  ## `pattern` is OS dependent, but at least the "\*.ext"
  ## notation is supported.
  walkCommon(pattern, isDir)

type
  PathComponent* = enum   ## Enumeration specifying a path component.
    pcFile,               ## path refers to a file
    pcLinkToFile,         ## path refers to a symbolic link to a file
    pcDir,                ## path refers to a directory
    pcLinkToDir           ## path refers to a symbolic link to a directory

{.deprecated: [TPathComponent: PathComponent].}


when defined(posix):
  proc getSymlinkFileKind(path: string): PathComponent =
    # Helper function.
    var s: Stat
    assert(path != "")
    if stat(path, s) < 0'i32:
      raiseOSError(osLastError())
    if S_ISDIR(s.st_mode):
      result = pcLinkToDir
    else:
      result = pcLinkToFile


proc staticWalkDir(dir: string; relative: bool): seq[
                  tuple[kind: PathComponent, path: string]] =
  discard

iterator walkDir*(dir: string; relative=false): tuple[kind: PathComponent, path: string] {.
  tags: [ReadDirEffect].} =
  ## walks over the directory `dir` and yields for each directory or file in
  ## `dir`. The component type and full path for each item is returned.
  ## Walking is not recursive. If ``relative`` is true the resulting path is
  ## shortened to be relative to ``dir``.
  ## Example: This directory structure::
  ##   dirA / dirB / fileB1.txt
  ##        / dirC
  ##        / fileA1.txt
  ##        / fileA2.txt
  ##
  ## and this code:
  ##
  ## .. code-block:: Nim
  ##     for kind, path in walkDir("dirA"):
  ##       echo(path)
  ##
  ## produces this output (but not necessarily in this order!)::
  ##   dirA/dirB
  ##   dirA/dirC
  ##   dirA/fileA1.txt
  ##   dirA/fileA2.txt
  when nimvm:
    for k, v in items(staticWalkDir(dir, relative)):
      yield (k, v)
  else:
    when defined(windows):
      var f: WIN32_FIND_DATA
      var h = findFirstFile(dir / "*", f)
      if h != -1:
        defer: findClose(h)
        while true:
          var k = pcFile
          if not skipFindData(f):
            if (f.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) != 0'i32:
              k = pcDir
            if (f.dwFileAttributes and FILE_ATTRIBUTE_REPARSE_POINT) != 0'i32:
              k = succ(k)
            let xx = if relative: extractFilename(getFilename(f))
                     else: dir / extractFilename(getFilename(f))
            yield (k, xx)
          if findNextFile(h, f) == 0'i32: break
    else:
      var d = opendir(dir)
      if d != nil:
        defer: discard closedir(d)
        while true:
          var x = readdir(d)
          if x == nil: break
          var y = $x.d_name
          if y != "." and y != "..":
            var s: Stat
            if not relative:
              y = dir / y
            var k = pcFile

            when defined(linux) or defined(macosx) or defined(bsd):
              if x.d_type != DT_UNKNOWN:
                if x.d_type == DT_DIR: k = pcDir
                if x.d_type == DT_LNK:
                  if dirExists(y): k = pcLinkToDir
                  else: k = pcLinkToFile
                yield (k, y)
                continue

            if lstat(y, s) < 0'i32: break
            if S_ISDIR(s.st_mode):
              k = pcDir
            elif S_ISLNK(s.st_mode):
              k = getSymlinkFileKind(y)
            yield (k, y)

iterator walkDirRec*(dir: string, filter={pcFile, pcDir}): string {.
  tags: [ReadDirEffect].} =
  ## walks over the directory `dir` and yields for each file in `dir`. The
  ## full path for each file is returned.
  ## **Warning**:
  ## Modifying the directory structure while the iterator
  ## is traversing may result in undefined behavior!
  ##
  ## Walking is recursive. `filter` controls the behaviour of the iterator:
  ##
  ## ---------------------   ---------------------------------------------
  ## filter                  meaning
  ## ---------------------   ---------------------------------------------
  ## ``pcFile``              yield real files
  ## ``pcLinkToFile``        yield symbolic links to files
  ## ``pcDir``               follow real directories
  ## ``pcLinkToDir``         follow symbolic links to directories
  ## ---------------------   ---------------------------------------------
  ##
  var stack = @[dir]
  while stack.len > 0:
    for k,p in walkDir(stack.pop()):
      if k in filter:
        case k
        of pcFile, pcLinkToFile: yield p
        of pcDir, pcLinkToDir: stack.add(p)

proc rawRemoveDir(dir: string) =
  when defined(windows):
    when useWinUnicode:
      wrapUnary(res, removeDirectoryW, dir)
    else:
      var res = removeDirectoryA(dir)
    let lastError = osLastError()
    if res == 0'i32 and lastError.int32 != 3'i32 and
        lastError.int32 != 18'i32 and lastError.int32 != 2'i32:
      raiseOSError(lastError)
  else:
    if rmdir(dir) != 0'i32 and errno != ENOENT: raiseOSError(osLastError())

proc removeDir*(dir: string) {.rtl, extern: "nos$1", tags: [
  WriteDirEffect, ReadDirEffect], benign.} =
  ## Removes the directory `dir` including all subdirectories and files
  ## in `dir` (recursively).
  ##
  ## If this fails, `OSError` is raised. This does not fail if the directory never
  ## existed in the first place.
  for kind, path in walkDir(dir):
    case kind
    of pcFile, pcLinkToFile, pcLinkToDir: removeFile(path)
    of pcDir: removeDir(path)
  rawRemoveDir(dir)

proc rawCreateDir(dir: string): bool =
  # Try to create one directory (not the whole path).
  # returns `true` for success, `false` if the path has previously existed
  #
  # This is a thin wrapper over mkDir (or alternatives on other systems),
  # so in case of a pre-existing path we don't check that it is a directory.
  when defined(solaris):
    let res = mkdir(dir, 0o777)
    if res == 0'i32:
      result = true
    elif errno in {EEXIST, ENOSYS}:
      result = false
    else:
      raiseOSError(osLastError())
  elif defined(unix):
    let res = mkdir(dir, 0o777)
    if res == 0'i32:
      result = true
    elif errno == EEXIST:
      result = false
    else:
      echo res
      raiseOSError(osLastError())
  else:
    when useWinUnicode:
      wrapUnary(res, createDirectoryW, dir)
    else:
      let res = createDirectoryA(dir)

    if res != 0'i32:
      result = true
    elif getLastError() == 183'i32:
      result = false
    else:
      raiseOSError(osLastError())

proc existsOrCreateDir*(dir: string): bool =
  ## Check if a `directory`:idx: `dir` exists, and create it otherwise.
  ##
  ## Does not create parent directories (fails if parent does not exist).
  ## Returns `true` if the directory already exists, and `false`
  ## otherwise.
  result = not rawCreateDir(dir)
  if result:
    # path already exists - need to check that it is indeed a directory
    if not existsDir(dir):
      raise newException(IOError, "Failed to create the directory")

proc createDir*(dir: string) {.rtl, extern: "nos$1",
  tags: [WriteDirEffect, ReadDirEffect].} =
  ## Creates the `directory`:idx: `dir`.
  ##
  ## The directory may contain several subdirectories that do not exist yet.
  ## The full path is created. If this fails, `OSError` is raised. It does **not**
  ## fail if the directory already exists because for most usages this does not
  ## indicate an error.
  var omitNext = false
  when doslike:
    omitNext = isAbsolute(dir)
  for i in 1.. dir.len-1:
    if dir[i] in {DirSep, AltSep}:
      if omitNext:
        omitNext = false
      else:
        discard existsOrCreateDir(substr(dir, 0, i-1))

  # The loop does not create the dir itself if it doesn't end in separator
  if dir.len > 0 and not omitNext and
     dir[^1] notin {DirSep, AltSep}:
    discard existsOrCreateDir(dir)

proc copyDir*(source, dest: string) {.rtl, extern: "nos$1",
  tags: [WriteIOEffect, ReadIOEffect], benign.} =
  ## Copies a directory from `source` to `dest`.
  ##
  ## If this fails, `OSError` is raised. On the Windows platform this proc will
  ## copy the attributes from `source` into `dest`. On other platforms created
  ## files and directories will inherit the default permissions of a newly
  ## created file/directory for the user. To preserve attributes recursively on
  ## these platforms use `copyDirWithPermissions() <#copyDirWithPermissions>`_.
  createDir(dest)
  for kind, path in walkDir(source):
    var noSource = path.substr(source.len()+1)
    case kind
    of pcFile:
      copyFile(path, dest / noSource)
    of pcDir:
      copyDir(path, dest / noSource)
    else: discard

proc createSymlink*(src, dest: string) =
  ## Create a symbolic link at `dest` which points to the item specified
  ## by `src`. On most operating systems, will fail if a link already exists.
  ##
  ## **Warning**:
  ## Some OS's (such as Microsoft Windows) restrict the creation
  ## of symlinks to root users (administrators).
  when defined(Windows):
    let flag = dirExists(src).int32
    when useWinUnicode:
      var wSrc = newWideCString(src)
      var wDst = newWideCString(dest)
      if createSymbolicLinkW(wDst, wSrc, flag) == 0 or getLastError() != 0:
        raiseOSError(osLastError())
    else:
      if createSymbolicLinkA(dest, src, flag) == 0 or getLastError() != 0:
        raiseOSError(osLastError())
  else:
    if symlink(src, dest) != 0:
      raiseOSError(osLastError())

proc createHardlink*(src, dest: string) =
  ## Create a hard link at `dest` which points to the item specified
  ## by `src`.
  ##
  ## **Warning**: Some OS's restrict the creation of hard links to
  ## root users (administrators).
  when defined(Windows):
    when useWinUnicode:
      var wSrc = newWideCString(src)
      var wDst = newWideCString(dest)
      if createHardLinkW(wDst, wSrc, nil) == 0:
        raiseOSError(osLastError())
    else:
      if createHardLinkA(dest, src, nil) == 0:
        raiseOSError(osLastError())
  else:
    if link(src, dest) != 0:
      raiseOSError(osLastError())

proc parseCmdLine*(c: string): seq[string] {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Splits a command line into several components;
  ## This proc is only occasionally useful, better use the `parseopt` module.
  ##
  ## On Windows, it uses the following parsing rules
  ## (see http://msdn.microsoft.com/en-us/library/17w5ykft.aspx ):
  ##
  ## * Arguments are delimited by white space, which is either a space or a tab.
  ## * The caret character (^) is not recognized as an escape character or
  ##   delimiter. The character is handled completely by the command-line parser
  ##   in the operating system before being passed to the argv array in the
  ##   program.
  ## * A string surrounded by double quotation marks ("string") is interpreted
  ##   as a single argument, regardless of white space contained within. A
  ##   quoted string can be embedded in an argument.
  ## * A double quotation mark preceded by a backslash (\") is interpreted as a
  ##   literal double quotation mark character (").
  ## * Backslashes are interpreted literally, unless they immediately precede
  ##   a double quotation mark.
  ## * If an even number of backslashes is followed by a double quotation mark,
  ##   one backslash is placed in the argv array for every pair of backslashes,
  ##   and the double quotation mark is interpreted as a string delimiter.
  ## * If an odd number of backslashes is followed by a double quotation mark,
  ##   one backslash is placed in the argv array for every pair of backslashes,
  ##   and the double quotation mark is "escaped" by the remaining backslash,
  ##   causing a literal double quotation mark (") to be placed in argv.
  ##
  ## On Posix systems, it uses the following parsing rules:
  ## Components are separated by whitespace unless the whitespace
  ## occurs within ``"`` or ``'`` quotes.
  result = @[]
  var i = 0
  var a = ""
  while true:
    setLen(a, 0)
    # eat all delimiting whitespace
    while c[i] == ' ' or c[i] == '\t' or c[i] == '\l' or c[i] == '\r' : inc(i)
    when defined(windows):
      # parse a single argument according to the above rules:
      if c[i] == '\0': break
      var inQuote = false
      while true:
        case c[i]
        of '\0': break
        of '\\':
          var j = i
          while c[j] == '\\': inc(j)
          if c[j] == '"':
            for k in 1..(j-i) div 2: a.add('\\')
            if (j-i) mod 2 == 0:
              i = j
            else:
              a.add('"')
              i = j+1
          else:
            a.add(c[i])
            inc(i)
        of '"':
          inc(i)
          if not inQuote: inQuote = true
          elif c[i] == '"':
            a.add(c[i])
            inc(i)
          else:
            inQuote = false
            break
        of ' ', '\t':
          if not inQuote: break
          a.add(c[i])
          inc(i)
        else:
          a.add(c[i])
          inc(i)
    else:
      case c[i]
      of '\'', '\"':
        var delim = c[i]
        inc(i) # skip ' or "
        while c[i] != '\0' and c[i] != delim:
          add a, c[i]
          inc(i)
        if c[i] != '\0': inc(i)
      of '\0': break
      else:
        while c[i] > ' ':
          add(a, c[i])
          inc(i)
    add(result, a)

proc copyFileWithPermissions*(source, dest: string,
                              ignorePermissionErrors = true) =
  ## Copies a file from `source` to `dest` preserving file permissions.
  ##
  ## This is a wrapper proc around `copyFile() <#copyFile>`_,
  ## `getFilePermissions() <#getFilePermissions>`_ and `setFilePermissions()
  ## <#setFilePermissions>`_ on non Windows platform. On Windows this proc is
  ## just a wrapper for `copyFile() <#copyFile>`_ since that proc already
  ## copies attributes.
  ##
  ## On non Windows systems permissions are copied after the file itself has
  ## been copied, which won't happen atomically and could lead to a race
  ## condition. If `ignorePermissionErrors` is true, errors while
  ## reading/setting file attributes will be ignored, otherwise will raise
  ## `OSError`.
  copyFile(source, dest)
  when not defined(Windows):
    try:
      setFilePermissions(dest, getFilePermissions(source))
    except:
      if not ignorePermissionErrors:
        raise

proc copyDirWithPermissions*(source, dest: string,
    ignorePermissionErrors = true) {.rtl, extern: "nos$1",
    tags: [WriteIOEffect, ReadIOEffect], benign.} =
  ## Copies a directory from `source` to `dest` preserving file permissions.
  ##
  ## If this fails, `OSError` is raised. This is a wrapper proc around `copyDir()
  ## <#copyDir>`_ and `copyFileWithPermissions() <#copyFileWithPermissions>`_
  ## on non Windows platforms. On Windows this proc is just a wrapper for
  ## `copyDir() <#copyDir>`_ since that proc already copies attributes.
  ##
  ## On non Windows systems permissions are copied after the file or directory
  ## itself has been copied, which won't happen atomically and could lead to a
  ## race condition. If `ignorePermissionErrors` is true, errors while
  ## reading/setting file attributes will be ignored, otherwise will raise
  ## `OSError`.
  createDir(dest)
  when not defined(Windows):
    try:
      setFilePermissions(dest, getFilePermissions(source))
    except:
      if not ignorePermissionErrors:
        raise
  for kind, path in walkDir(source):
    var noSource = path.substr(source.len()+1)
    case kind
    of pcFile:
      copyFileWithPermissions(path, dest / noSource, ignorePermissionErrors)
    of pcDir:
      copyDirWithPermissions(path, dest / noSource, ignorePermissionErrors)
    else: discard

proc inclFilePermissions*(filename: string,
                          permissions: set[FilePermission]) {.
  rtl, extern: "nos$1", tags: [ReadDirEffect, WriteDirEffect].} =
  ## a convenience procedure for:
  ##
  ## .. code-block:: nim
  ##   setFilePermissions(filename, getFilePermissions(filename)+permissions)
  setFilePermissions(filename, getFilePermissions(filename)+permissions)

proc exclFilePermissions*(filename: string,
                          permissions: set[FilePermission]) {.
  rtl, extern: "nos$1", tags: [ReadDirEffect, WriteDirEffect].} =
  ## a convenience procedure for:
  ##
  ## .. code-block:: nim
  ##   setFilePermissions(filename, getFilePermissions(filename)-permissions)
  setFilePermissions(filename, getFilePermissions(filename)-permissions)

include ospaths

proc expandSymlink*(symlinkPath: string): string =
  ## Returns a string representing the path to which the symbolic link points.
  ##
  ## On Windows this is a noop, ``symlinkPath`` is simply returned.
  when defined(windows):
    result = symlinkPath
  else:
    result = newString(256)
    var len = readlink(symlinkPath, result, 256)
    if len < 0:
      raiseOSError(osLastError())
    if len > 256:
      result = newString(len+1)
      len = readlink(symlinkPath, result, len)
    setLen(result, len)

when defined(nimdoc):
  # Common forward declaration docstring block for parameter retrieval procs.
  proc paramCount*(): int {.tags: [ReadIOEffect].} =
    ## Returns the number of `command line arguments`:idx: given to the
    ## application.
    ##
    ## If your binary was called without parameters this will return zero.  You
    ## can later query each individual paramater with `paramStr() <#paramStr>`_
    ## or retrieve all of them in one go with `commandLineParams()
    ## <#commandLineParams>`_.
    ##
    ## **Availability**: On Posix there is no portable way to get the command
    ## line from a DLL and thus the proc isn't defined in this environment. You
    ## can test for its availability with `declared() <system.html#declared>`_.
    ## Example:
    ##
    ## .. code-block:: nim
    ##   when declared(paramCount):
    ##     # Use paramCount() here
    ##   else:
    ##     # Do something else!

  proc paramStr*(i: int): TaintedString {.tags: [ReadIOEffect].} =
    ## Returns the `i`-th `command line argument`:idx: given to the application.
    ##
    ## `i` should be in the range `1..paramCount()`, the `EInvalidIndex`
    ## exception will be raised for invalid values.  Instead of iterating over
    ## `paramCount() <#paramCount>`_ with this proc you can call the
    ## convenience `commandLineParams() <#commandLineParams>`_.
    ##
    ## It is possible to call ``paramStr(0)`` but this will return OS specific
    ## contents (usually the name of the invoked executable). You should avoid
    ## this and call `getAppFilename() <#getAppFilename>`_ instead.
    ##
    ## **Availability**: On Posix there is no portable way to get the command
    ## line from a DLL and thus the proc isn't defined in this environment. You
    ## can test for its availability with `declared() <system.html#declared>`_.
    ## Example:
    ##
    ## .. code-block:: nim
    ##   when declared(paramStr):
    ##     # Use paramStr() here
    ##   else:
    ##     # Do something else!

elif defined(windows):
  # Since we support GUI applications with Nim, we sometimes generate
  # a WinMain entry proc. But a WinMain proc has no access to the parsed
  # command line arguments. The way to get them differs. Thus we parse them
  # ourselves. This has the additional benefit that the program's behaviour
  # is always the same -- independent of the used C compiler.
  var
    ownArgv {.threadvar.}: seq[string]

  proc paramCount*(): int {.rtl, extern: "nos$1", tags: [ReadIOEffect].} =
    # Docstring in nimdoc block.
    if isNil(ownArgv): ownArgv = parseCmdLine($getCommandLine())
    result = ownArgv.len-1

  proc paramStr*(i: int): TaintedString {.rtl, extern: "nos$1",
    tags: [ReadIOEffect].} =
    # Docstring in nimdoc block.
    if isNil(ownArgv): ownArgv = parseCmdLine($getCommandLine())
    return TaintedString(ownArgv[i])

elif not defined(createNimRtl):
  # On Posix, there is no portable way to get the command line from a DLL.
  var
    cmdCount {.importc: "cmdCount".}: cint
    cmdLine {.importc: "cmdLine".}: cstringArray

  proc paramStr*(i: int): TaintedString {.tags: [ReadIOEffect].} =
    # Docstring in nimdoc block.
    if i < cmdCount and i >= 0: return TaintedString($cmdLine[i])
    raise newException(IndexError, "invalid index")

  proc paramCount*(): int {.tags: [ReadIOEffect].} =
    # Docstring in nimdoc block.
    result = cmdCount-1

when declared(paramCount) or defined(nimdoc):
  proc commandLineParams*(): seq[TaintedString] =
    ## Convenience proc which returns the command line parameters.
    ##
    ## This returns **only** the parameters. If you want to get the application
    ## executable filename, call `getAppFilename() <#getAppFilename>`_.
    ##
    ## **Availability**: On Posix there is no portable way to get the command
    ## line from a DLL and thus the proc isn't defined in this environment. You
    ## can test for its availability with `declared() <system.html#declared>`_.
    ## Example:
    ##
    ## .. code-block:: nim
    ##   when declared(commandLineParams):
    ##     # Use commandLineParams() here
    ##   else:
    ##     # Do something else!
    result = @[]
    for i in 1..paramCount():
      result.add(paramStr(i))

when defined(freebsd):
  proc sysctl(name: ptr cint, namelen: cuint, oldp: pointer, oldplen: ptr csize,
              newp: pointer, newplen: csize): cint
       {.importc: "sysctl",header: """#include <sys/types.h>
                                      #include <sys/sysctl.h>"""}
  const
    CTL_KERN = 1
    KERN_PROC = 14
    KERN_PROC_PATHNAME = 12
    MAX_PATH = 1024

  proc getApplFreebsd(): string =
    var pathLength = csize(MAX_PATH)
    result = newString(pathLength)
    var req = [CTL_KERN.cint, KERN_PROC.cint, KERN_PROC_PATHNAME.cint, -1.cint]
    while true:
      let res = sysctl(addr req[0], 4, cast[pointer](addr result[0]),
                       addr pathLength, nil, 0)
      if res < 0:
        let err = osLastError()
        if err.int32 == ENOMEM:
          result = newString(pathLength)
        else:
          result.setLen(0) # error!
          break
      else:
        result.setLen(pathLength)
        break

when defined(linux) or defined(solaris) or defined(bsd) or defined(aix):
  proc getApplAux(procPath: string): string =
    result = newString(256)
    var len = readlink(procPath, result, 256)
    if len > 256:
      result = newString(len+1)
      len = readlink(procPath, result, len)
    setLen(result, len)

when not (defined(windows) or defined(macosx)):
  proc getApplHeuristic(): string =
    when declared(paramStr):
      result = string(paramStr(0))
      # POSIX guaranties that this contains the executable
      # as it has been executed by the calling process
      if len(result) > 0 and result[0] != DirSep: # not an absolute path?
        # iterate over any path in the $PATH environment variable
        for p in split(string(getEnv("PATH")), {PathSep}):
          var x = joinPath(p, result)
          if existsFile(x): return x
    else:
      result = ""

when defined(macosx):
  type
    cuint32* {.importc: "unsigned int", nodecl.} = int
    ## This is the same as the type ``uint32_t`` in *C*.

  # a really hacky solution: since we like to include 2 headers we have to
  # define two procs which in reality are the same
  proc getExecPath1(c: cstring, size: var cuint32) {.
    importc: "_NSGetExecutablePath", header: "<sys/param.h>".}
  proc getExecPath2(c: cstring, size: var cuint32): bool {.
    importc: "_NSGetExecutablePath", header: "<mach-o/dyld.h>".}

proc getAppFilename*(): string {.rtl, extern: "nos$1", tags: [ReadIOEffect].} =
  ## Returns the filename of the application's executable.
  ##
  ## This procedure will resolve symlinks.

  # Linux: /proc/<pid>/exe
  # Solaris:
  # /proc/<pid>/object/a.out (filename only)
  # /proc/<pid>/path/a.out (complete pathname)
  when defined(windows):
    var bufsize = int32(MAX_PATH)
    when useWinUnicode:
      var buf = newWideCString("", bufsize)
      while true:
        var L = getModuleFileNameW(0, buf, bufsize)
        if L == 0'i32:
          result = "" # error!
          break
        elif L > bufsize:
          buf = newWideCString("", L)
          bufsize = L
        else:
          result = buf$L
          break
    else:
      result = newString(bufsize)
      while true:
        var L = getModuleFileNameA(0, result, bufsize)
        if L == 0'i32:
          result = "" # error!
          break
        elif L > bufsize:
          result = newString(L)
          bufsize = L
        else:
          setLen(result, L)
          break
  elif defined(macosx):
    var size: cuint32
    getExecPath1(nil, size)
    result = newString(int(size))
    if getExecPath2(result, size):
      result = "" # error!
    if result.len > 0:
      result = result.expandFilename
  else:
    when defined(linux) or defined(aix) or defined(netbsd):
      result = getApplAux("/proc/self/exe")
    elif defined(solaris):
      result = getApplAux("/proc/" & $getpid() & "/path/a.out")
    elif defined(freebsd):
      result = getApplFreebsd()
    # little heuristic that may work on other POSIX-like systems:
    if result.len == 0:
      result = getApplHeuristic()

proc getApplicationFilename*(): string {.rtl, extern: "nos$1", deprecated.} =
  ## Returns the filename of the application's executable.
  ## **Deprecated since version 0.8.12**: use ``getAppFilename``
  ## instead.
  result = getAppFilename()

proc getApplicationDir*(): string {.rtl, extern: "nos$1", deprecated.} =
  ## Returns the directory of the application's executable.
  ## **Deprecated since version 0.8.12**: use ``getAppDir``
  ## instead.
  result = splitFile(getAppFilename()).dir

proc getAppDir*(): string {.rtl, extern: "nos$1", tags: [ReadIOEffect].} =
  ## Returns the directory of the application's executable.
  result = splitFile(getAppFilename()).dir

proc sleep*(milsecs: int) {.rtl, extern: "nos$1", tags: [TimeEffect].} =
  ## sleeps `milsecs` milliseconds.
  when defined(windows):
    winlean.sleep(int32(milsecs))
  else:
    var a, b: Timespec
    a.tv_sec = Time(milsecs div 1000)
    a.tv_nsec = (milsecs mod 1000) * 1000 * 1000
    discard posix.nanosleep(a, b)

proc getFileSize*(file: string): BiggestInt {.rtl, extern: "nos$1",
  tags: [ReadIOEffect].} =
  ## returns the file size of `file`. Can raise ``OSError``.
  when defined(windows):
    var a: WIN32_FIND_DATA
    var resA = findFirstFile(file, a)
    if resA == -1: raiseOSError(osLastError())
    result = rdFileSize(a)
    findClose(resA)
  else:
    var f: File
    if open(f, file):
      result = getFileSize(f)
      close(f)
    else: raiseOSError(osLastError())

when defined(Windows):
  type
    DeviceId* = int32
    FileId* = int64
else:
  type
    DeviceId* = Dev
    FileId* = Ino

type
  FileInfo* = object
    ## Contains information associated with a file object.
    id*: tuple[device: DeviceId, file: FileId] # Device and file id.
    kind*: PathComponent # Kind of file object - directory, symlink, etc.
    size*: BiggestInt # Size of file.
    permissions*: set[FilePermission] # File permissions
    linkCount*: BiggestInt # Number of hard links the file object has.
    lastAccessTime*: Time # Time file was last accessed.
    lastWriteTime*: Time # Time file was last modified/written to.
    creationTime*: Time # Time file was created. Not supported on all systems!

template rawToFormalFileInfo(rawInfo, path, formalInfo): untyped =
  ## Transforms the native file info structure into the one nim uses.
  ## 'rawInfo' is either a 'TBY_HANDLE_FILE_INFORMATION' structure on Windows,
  ## or a 'Stat' structure on posix
  when defined(Windows):
    template toTime(e: FILETIME): untyped {.gensym.} = winTimeToUnixTime(rdFileTime(e)) # local templates default to bind semantics
    template merge(a, b): untyped = a or (b shl 32)
    formalInfo.id.device = rawInfo.dwVolumeSerialNumber
    formalInfo.id.file = merge(rawInfo.nFileIndexLow, rawInfo.nFileIndexHigh)
    formalInfo.size = merge(rawInfo.nFileSizeLow, rawInfo.nFileSizeHigh)
    formalInfo.linkCount = rawInfo.nNumberOfLinks
    formalInfo.lastAccessTime = toTime(rawInfo.ftLastAccessTime)
    formalInfo.lastWriteTime = toTime(rawInfo.ftLastWriteTime)
    formalInfo.creationTime = toTime(rawInfo.ftCreationTime)

    # Retrieve basic permissions
    if (rawInfo.dwFileAttributes and FILE_ATTRIBUTE_READONLY) != 0'i32:
      formalInfo.permissions = {fpUserExec, fpUserRead, fpGroupExec,
                                fpGroupRead, fpOthersExec, fpOthersRead}
    else:
      result.permissions = {fpUserExec..fpOthersRead}

    # Retrieve basic file kind
    result.kind = pcFile
    if (rawInfo.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) != 0'i32:
      formalInfo.kind = pcDir
    if (rawInfo.dwFileAttributes and FILE_ATTRIBUTE_REPARSE_POINT) != 0'i32:
      formalInfo.kind = succ(result.kind)


  else:
    template checkAndIncludeMode(rawMode, formalMode: untyped) =
      if (rawInfo.st_mode and rawMode) != 0'i32:
        formalInfo.permissions.incl(formalMode)
    formalInfo.id = (rawInfo.st_dev, rawInfo.st_ino)
    formalInfo.size = rawInfo.st_size
    formalInfo.linkCount = rawInfo.st_Nlink
    formalInfo.lastAccessTime = rawInfo.st_atime
    formalInfo.lastWriteTime = rawInfo.st_mtime
    formalInfo.creationTime = rawInfo.st_ctime

    result.permissions = {}
    checkAndIncludeMode(S_IRUSR, fpUserRead)
    checkAndIncludeMode(S_IWUSR, fpUserWrite)
    checkAndIncludeMode(S_IXUSR, fpUserExec)

    checkAndIncludeMode(S_IRGRP, fpGroupRead)
    checkAndIncludeMode(S_IWGRP, fpGroupWrite)
    checkAndIncludeMode(S_IXGRP, fpGroupExec)

    checkAndIncludeMode(S_IROTH, fpOthersRead)
    checkAndIncludeMode(S_IWOTH, fpOthersWrite)
    checkAndIncludeMode(S_IXOTH, fpOthersExec)

    formalInfo.kind = pcFile
    if S_ISDIR(rawInfo.st_mode):
      formalInfo.kind = pcDir
    elif S_ISLNK(rawInfo.st_mode):
      assert(path != "") # symlinks can't occur for file handles
      formalInfo.kind = getSymlinkFileKind(path)

proc getFileInfo*(handle: FileHandle): FileInfo =
  ## Retrieves file information for the file object represented by the given
  ## handle.
  ##
  ## If the information cannot be retrieved, such as when the file handle
  ## is invalid, an error will be thrown.
  # Done: ID, Kind, Size, Permissions, Link Count
  when defined(Windows):
    var rawInfo: BY_HANDLE_FILE_INFORMATION
    # We have to use the super special '_get_osfhandle' call (wrapped above)
    # To transform the C file descripter to a native file handle.
    var realHandle = get_osfhandle(handle)
    if getFileInformationByHandle(realHandle, addr rawInfo) == 0:
      raiseOSError(osLastError())
    rawToFormalFileInfo(rawInfo, "", result)
  else:
    var rawInfo: Stat
    if fstat(handle, rawInfo) < 0'i32:
      raiseOSError(osLastError())
    rawToFormalFileInfo(rawInfo, "", result)

proc getFileInfo*(file: File): FileInfo =
  if file.isNil:
    raise newException(IOError, "File is nil")
  result = getFileInfo(file.getFileHandle())

proc getFileInfo*(path: string, followSymlink = true): FileInfo =
  ## Retrieves file information for the file object pointed to by `path`.
  ##
  ## Due to intrinsic differences between operating systems, the information
  ## contained by the returned `FileInfo` structure will be slightly different
  ## across platforms, and in some cases, incomplete or inaccurate.
  ##
  ## When `followSymlink` is true, symlinks are followed and the information
  ## retrieved is information related to the symlink's target. Otherwise,
  ## information on the symlink itself is retrieved.
  ##
  ## If the information cannot be retrieved, such as when the path doesn't
  ## exist, or when permission restrictions prevent the program from retrieving
  ## file information, an error will be thrown.
  when defined(Windows):
    var
      handle = openHandle(path, followSymlink)
      rawInfo: BY_HANDLE_FILE_INFORMATION
    if handle == INVALID_HANDLE_VALUE:
      raiseOSError(osLastError())
    if getFileInformationByHandle(handle, addr rawInfo) == 0:
      raiseOSError(osLastError())
    rawToFormalFileInfo(rawInfo, path, result)
    discard closeHandle(handle)
  else:
    var rawInfo: Stat
    if followSymlink:
      if stat(path, rawInfo) < 0'i32:
        raiseOSError(osLastError())
    else:
      if lstat(path, rawInfo) < 0'i32:
        raiseOSError(osLastError())
    rawToFormalFileInfo(rawInfo, path, result)

proc isHidden*(path: string): bool =
  ## Determines whether a given path is hidden or not. Returns false if the
  ## file doesn't exist. The given path must be accessible from the current
  ## working directory of the program.
  ##
  ## On Windows, a file is hidden if the file's 'hidden' attribute is set.
  ## On Unix-like systems, a file is hidden if it starts with a '.' (period)
  ## and is not *just* '.' or '..' ' ."
  when defined(Windows):
    when useWinUnicode:
      wrapUnary(attributes, getFileAttributesW, path)
    else:
      var attributes = getFileAttributesA(path)
    if attributes != -1'i32:
      result = (attributes and FILE_ATTRIBUTE_HIDDEN) != 0'i32
  else:
    if fileExists(path):
      let
        fileName = extractFilename(path)
        nameLen = len(fileName)
      if nameLen == 2:
        result = (fileName[0] == '.') and (fileName[1] != '.')
      elif nameLen > 2:
        result = (fileName[0] == '.') and (fileName[3] != '.')

{.pop.}
