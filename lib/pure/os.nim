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

runnableExamples:
  let myFile = "/path/to/my/file.nim"
  assert splitPath(myFile) == (head: "/path/to/my", tail: "file.nim")
  when defined(posix):
    assert parentDir(myFile) == "/path/to/my"
  assert splitFile(myFile) == (dir: "/path/to/my", name: "file", ext: ".nim")
  assert myFile.changeFileExt("c") == "/path/to/my/file.c"

## **See also:**
## * `osproc module <osproc.html>`_ for process communication beyond
##   `execShellCmd proc`_
## * `parseopt module <parseopt.html>`_ for command-line parser beyond
##   `parseCmdLine proc`_
## * `uri module <uri.html>`_
## * `distros module <distros.html>`_
## * `dynlib module <dynlib.html>`_
## * `streams module <streams.html>`_
import ospaths
export ospaths

import osfiles
export osfiles

import osdirs
export osdirs

import ossymlinks
export ossymlinks


include system/inclrtl
import std/private/since

import strutils, pathnorm

when defined(nimPreviewSlimSystem):
  import std/[syncio, assertions, widestrs]

const weirdTarget = defined(nimscript) or defined(js)

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

import std/oserrors
export oserrors
import std/envvars
export envvars

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

proc getHomeDir*(): string {.rtl, extern: "nos$1",
  tags: [ReadEnvEffect, ReadIOEffect], appdirs.} =
  ## Returns the home directory of the current user.
  ##
  ## This proc is wrapped by the `expandTilde proc`_
  ## for the convenience of processing paths coming from user configuration files.
  ##
  ## See also:
  ## * `getConfigDir proc`_
  ## * `getTempDir proc`_
  ## * `expandTilde proc`_
  ## * `getCurrentDir proc`_
  ## * `setCurrentDir proc`_
  runnableExamples:
    assert getHomeDir() == expandTilde("~")

  when defined(windows): return getEnv("USERPROFILE") & "\\"
  else: return getEnv("HOME") & "/"

proc getConfigDir*(): string {.rtl, extern: "nos$1",
  tags: [ReadEnvEffect, ReadIOEffect], appdirs.} =
  ## Returns the config directory of the current user for applications.
  ##
  ## On non-Windows OSs, this proc conforms to the XDG Base Directory
  ## spec. Thus, this proc returns the value of the `XDG_CONFIG_HOME` environment
  ## variable if it is set, otherwise it returns the default configuration
  ## directory ("~/.config/").
  ##
  ## An OS-dependent trailing slash is always present at the end of the
  ## returned string: `\\` on Windows and `/` on all other OSs.
  ##
  ## See also:
  ## * `getHomeDir proc`_
  ## * `getTempDir proc`_
  ## * `expandTilde proc`_
  ## * `getCurrentDir proc`_
  ## * `setCurrentDir proc`_
  when defined(windows):
    result = getEnv("APPDATA")
  else:
    result = getEnv("XDG_CONFIG_HOME", getEnv("HOME") / ".config")
  result.normalizePathEnd(trailingSep = true)


proc getCacheDir*(): string {.appdirs.} =
  ## Returns the cache directory of the current user for applications.
  ##
  ## This makes use of the following environment variables:
  ##
  ## * On Windows: `getEnv("LOCALAPPDATA")`
  ##
  ## * On macOS: `getEnv("XDG_CACHE_HOME", getEnv("HOME") / "Library/Caches")`
  ##
  ## * On other platforms: `getEnv("XDG_CACHE_HOME", getEnv("HOME") / ".cache")`
  ##
  ## **See also:**
  ## * `getHomeDir proc`_
  ## * `getTempDir proc`_
  ## * `getConfigDir proc`_
  # follows https://crates.io/crates/platform-dirs
  when defined(windows):
    result = getEnv("LOCALAPPDATA")
  elif defined(osx):
    result = getEnv("XDG_CACHE_HOME", getEnv("HOME") / "Library/Caches")
  else:
    result = getEnv("XDG_CACHE_HOME", getEnv("HOME") / ".cache")
  result.normalizePathEnd(false)

proc getCacheDir*(app: string): string {.appdirs.} =
  ## Returns the cache directory for an application `app`.
  ##
  ## * On Windows, this uses: `getCacheDir() / app / "cache"`
  ## * On other platforms, this uses: `getCacheDir() / app`
  when defined(windows):
    getCacheDir() / app / "cache"
  else:
    getCacheDir() / app


when defined(windows):
  type DWORD = uint32

  when defined(nimPreviewSlimSystem):
    import std/widestrs

  proc getTempPath(
    nBufferLength: DWORD, lpBuffer: WideCString
  ): DWORD {.stdcall, dynlib: "kernel32.dll", importc: "GetTempPathW".} =
    ## Retrieves the path of the directory designated for temporary files.

template getEnvImpl(result: var string, tempDirList: openArray[string]) =
  for dir in tempDirList:
    if existsEnv(dir):
      result = getEnv(dir)
      break

template getTempDirImpl(result: var string) =
  when defined(windows):
    getEnvImpl(result, ["TMP", "TEMP", "USERPROFILE"])
  else:
    getEnvImpl(result, ["TMPDIR", "TEMP", "TMP", "TEMPDIR"])

proc getTempDir*(): string {.rtl, extern: "nos$1",
  tags: [ReadEnvEffect, ReadIOEffect], appdirs.} =
  ## Returns the temporary directory of the current user for applications to
  ## save temporary files in.
  ##
  ## On Windows, it calls [GetTempPath](https://docs.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-gettemppathw).
  ## On Posix based platforms, it will check `TMPDIR`, `TEMP`, `TMP` and `TEMPDIR` environment variables in order.
  ## On all platforms, `/tmp` will be returned if the procs fails.
  ##
  ## You can override this implementation
  ## by adding `-d:tempDir=mytempname` to your compiler invocation.
  ##
  ## **Note:** This proc does not check whether the returned path exists.
  ##
  ## See also:
  ## * `getHomeDir proc`_
  ## * `getConfigDir proc`_
  ## * `expandTilde proc`_
  ## * `getCurrentDir proc`_
  ## * `setCurrentDir proc`_
  const tempDirDefault = "/tmp"
  when defined(tempDir):
    const tempDir {.strdefine.}: string = tempDirDefault
    result = tempDir
  else:
    when nimvm:
      getTempDirImpl(result)
    else:
      when defined(windows):
        let size = getTempPath(0, nil)
        # If the function fails, the return value is zero.
        if size > 0:
          let buffer = newWideCString(size.int)
          if getTempPath(size, buffer) > 0:
            result = $buffer
      elif defined(android): result = "/data/local/tmp"
      else:
        getTempDirImpl(result)
    if result.len == 0:
      result = tempDirDefault
  normalizePathEnd(result, trailingSep=true)

proc expandTilde*(path: string): string {.
  tags: [ReadEnvEffect, ReadIOEffect], paths.} =
  ## Expands ``~`` or a path starting with ``~/`` to a full path, replacing
  ## ``~`` with `getHomeDir()`_ (otherwise returns ``path`` unmodified).
  ##
  ## Windows: this is still supported despite the Windows platform not having this
  ## convention; also, both ``~/`` and ``~\`` are handled.
  ##
  ## See also:
  ## * `getHomeDir proc`_
  ## * `getConfigDir proc`_
  ## * `getTempDir proc`_
  ## * `getCurrentDir proc`_
  ## * `setCurrentDir proc`_
  runnableExamples:
    assert expandTilde("~" / "appname.cfg") == getHomeDir() / "appname.cfg"
    assert expandTilde("~/foo/bar") == getHomeDir() / "foo/bar"
    assert expandTilde("/foo/bar") == "/foo/bar"

  if len(path) == 0 or path[0] != '~':
    result = path
  elif len(path) == 1:
    result = getHomeDir()
  elif (path[1] in {DirSep, AltSep}):
    result = getHomeDir() / path.substr(2)
  else:
    # TODO: handle `~bob` and `~bob/` which means home of bob
    result = path

proc quoteShellWindows*(s: string): string {.noSideEffect, rtl, extern: "nosp$1".} =
  ## Quote `s`, so it can be safely passed to Windows API.
  ##
  ## Based on Python's `subprocess.list2cmdline`.
  ## See `this link <http://msdn.microsoft.com/en-us/library/17w5ykft.aspx>`_
  ## for more details.
  let needQuote = {' ', '\t'} in s or s.len == 0
  result = ""
  var backslashBuff = ""
  if needQuote:
    result.add("\"")

  for c in s:
    if c == '\\':
      backslashBuff.add(c)
    elif c == '\"':
      for i in 0..<backslashBuff.len*2:
        result.add('\\')
      backslashBuff.setLen(0)
      result.add("\\\"")
    else:
      if backslashBuff.len != 0:
        result.add(backslashBuff)
        backslashBuff.setLen(0)
      result.add(c)

  if backslashBuff.len > 0:
    result.add(backslashBuff)
  if needQuote:
    result.add(backslashBuff)
    result.add("\"")


proc quoteShellPosix*(s: string): string {.noSideEffect, rtl, extern: "nosp$1".} =
  ## Quote ``s``, so it can be safely passed to POSIX shell.
  const safeUnixChars = {'%', '+', '-', '.', '/', '_', ':', '=', '@',
                         '0'..'9', 'A'..'Z', 'a'..'z'}
  if s.len == 0:
    result = "''"
  elif s.allCharsInSet(safeUnixChars):
    result = s
  else:
    result = "'" & s.replace("'", "'\"'\"'") & "'"

when defined(windows) or defined(posix) or defined(nintendoswitch):
  proc quoteShell*(s: string): string {.noSideEffect, rtl, extern: "nosp$1".} =
    ## Quote ``s``, so it can be safely passed to shell.
    ##
    ## When on Windows, it calls `quoteShellWindows proc`_.
    ## Otherwise, calls `quoteShellPosix proc`_.
    when defined(windows):
      result = quoteShellWindows(s)
    else:
      result = quoteShellPosix(s)

  proc quoteShellCommand*(args: openArray[string]): string =
    ## Concatenates and quotes shell arguments `args`.
    runnableExamples:
      when defined(posix):
        assert quoteShellCommand(["aaa", "", "c d"]) == "aaa '' 'c d'"
      when defined(windows):
        assert quoteShellCommand(["aaa", "", "c d"]) == "aaa \"\" \"c d\""

    # can't use `map` pending https://github.com/nim-lang/Nim/issues/8303
    result = ""
    for i in 0..<args.len:
      if i > 0: result.add " "
      result.add quoteShell(args[i])

when not weirdTarget:
  proc c_system(cmd: cstring): cint {.
    importc: "system", header: "<stdlib.h>".}

  when not defined(windows):
    proc c_rename(oldname, newname: cstring): cint {.
      importc: "rename", header: "<stdio.h>".}
    proc c_strlen(a: cstring): cint {.
      importc: "strlen", header: "<string.h>", noSideEffect.}
    proc c_free(p: pointer) {.
      importc: "free", header: "<stdlib.h>".}

when not defined(windows):
  const maxSymlinkLen = 1024

const
  ExeExts* = ## Platform specific file extension for executables.
    ## On Windows ``["exe", "cmd", "bat"]``, on Posix ``[""]``.
    when defined(windows): ["exe", "cmd", "bat"] else: [""]

proc findExe*(exe: string, followSymlinks: bool = true;
              extensions: openArray[string]=ExeExts): string {.
  tags: [ReadDirEffect, ReadEnvEffect, ReadIOEffect], noNimJs.} =
  ## Searches for `exe` in the current working directory and then
  ## in directories listed in the ``PATH`` environment variable.
  ##
  ## Returns `""` if the `exe` cannot be found. `exe`
  ## is added the `ExeExts`_ file extensions if it has none.
  ##
  ## If the system supports symlinks it also resolves them until it
  ## meets the actual file. This behavior can be disabled if desired
  ## by setting `followSymlinks = false`.

  if exe.len == 0: return
  template checkCurrentDir() =
    for ext in extensions:
      result = addFileExt(exe, ext)
      if fileExists(result): return
  when defined(posix):
    if '/' in exe: checkCurrentDir()
  else:
    checkCurrentDir()
  let path = getEnv("PATH")
  for candidate in split(path, PathSep):
    if candidate.len == 0: continue
    when defined(windows):
      var x = (if candidate[0] == '"' and candidate[^1] == '"':
                substr(candidate, 1, candidate.len-2) else: candidate) /
              exe
    else:
      var x = expandTilde(candidate) / exe
    for ext in extensions:
      var x = addFileExt(x, ext)
      if fileExists(x):
        when not defined(windows):
          while followSymlinks: # doubles as if here
            if x.symlinkExists:
              var r = newString(maxSymlinkLen)
              var len = readlink(x.cstring, r.cstring, maxSymlinkLen)
              if len < 0:
                raiseOSError(osLastError(), exe)
              if len > maxSymlinkLen:
                r = newString(len+1)
                len = readlink(x.cstring, r.cstring, len)
              setLen(r, len)
              if isAbsolute(r):
                x = r
              else:
                x = parentDir(x) / r
            else:
              break
        return x
  result = ""

when weirdTarget:
  const times = "fake const"
  template Time(x: untyped): untyped = string

proc getLastModificationTime*(file: string): times.Time {.rtl, extern: "nos$1", noWeirdTarget.} =
  ## Returns the `file`'s last modification time.
  ##
  ## See also:
  ## * `getLastAccessTime proc`_
  ## * `getCreationTime proc`_
  ## * `fileNewer proc`_
  when defined(posix):
    var res: Stat
    if stat(file, res) < 0'i32: raiseOSError(osLastError(), file)
    result = res.st_mtim.toTime
  else:
    var f: WIN32_FIND_DATA
    var h = findFirstFile(file, f)
    if h == -1'i32: raiseOSError(osLastError(), file)
    result = fromWinTime(rdFileTime(f.ftLastWriteTime))
    findClose(h)

proc getLastAccessTime*(file: string): times.Time {.rtl, extern: "nos$1", noWeirdTarget.} =
  ## Returns the `file`'s last read or write access time.
  ##
  ## See also:
  ## * `getLastModificationTime proc`_
  ## * `getCreationTime proc`_
  ## * `fileNewer proc`_
  when defined(posix):
    var res: Stat
    if stat(file, res) < 0'i32: raiseOSError(osLastError(), file)
    result = res.st_atim.toTime
  else:
    var f: WIN32_FIND_DATA
    var h = findFirstFile(file, f)
    if h == -1'i32: raiseOSError(osLastError(), file)
    result = fromWinTime(rdFileTime(f.ftLastAccessTime))
    findClose(h)

proc getCreationTime*(file: string): times.Time {.rtl, extern: "nos$1", noWeirdTarget.} =
  ## Returns the `file`'s creation time.
  ##
  ## **Note:** Under POSIX OS's, the returned time may actually be the time at
  ## which the file's attribute's were last modified. See
  ## `here <https://github.com/nim-lang/Nim/issues/1058>`_ for details.
  ##
  ## See also:
  ## * `getLastModificationTime proc`_
  ## * `getLastAccessTime proc`_
  ## * `fileNewer proc`_
  when defined(posix):
    var res: Stat
    if stat(file, res) < 0'i32: raiseOSError(osLastError(), file)
    result = res.st_ctim.toTime
  else:
    var f: WIN32_FIND_DATA
    var h = findFirstFile(file, f)
    if h == -1'i32: raiseOSError(osLastError(), file)
    result = fromWinTime(rdFileTime(f.ftCreationTime))
    findClose(h)

proc fileNewer*(a, b: string): bool {.rtl, extern: "nos$1", noWeirdTarget.} =
  ## Returns true if the file `a` is newer than file `b`, i.e. if `a`'s
  ## modification time is later than `b`'s.
  ##
  ## See also:
  ## * `getLastModificationTime proc`_
  ## * `getLastAccessTime proc`_
  ## * `getCreationTime proc`_
  when defined(posix):
    # If we don't have access to nanosecond resolution, use '>='
    when not StatHasNanoseconds:
      result = getLastModificationTime(a) >= getLastModificationTime(b)
    else:
      result = getLastModificationTime(a) > getLastModificationTime(b)
  else:
    result = getLastModificationTime(a) > getLastModificationTime(b)

when defined(windows) and not weirdTarget:
  proc openHandle(path: string, followSymlink=true, writeAccess=false): Handle =
    var flags = FILE_FLAG_BACKUP_SEMANTICS or FILE_ATTRIBUTE_NORMAL
    if not followSymlink:
      flags = flags or FILE_FLAG_OPEN_REPARSE_POINT
    let access = if writeAccess: GENERIC_WRITE else: 0'i32

    when useWinUnicode:
      result = createFileW(
        newWideCString(path), access,
        FILE_SHARE_DELETE or FILE_SHARE_READ or FILE_SHARE_WRITE,
        nil, OPEN_EXISTING, flags, 0
        )
    else:
      result = createFileA(
        path, access,
        FILE_SHARE_DELETE or FILE_SHARE_READ or FILE_SHARE_WRITE,
        nil, OPEN_EXISTING, flags, 0
        )

proc sameFile*(path1, path2: string): bool {.rtl, extern: "nos$1",
  tags: [ReadDirEffect], noWeirdTarget.} =
  ## Returns true if both pathname arguments refer to the same physical
  ## file or directory.
  ##
  ## Raises `OSError` if any of the files does not
  ## exist or information about it can not be obtained.
  ##
  ## This proc will return true if given two alternative hard-linked or
  ## sym-linked paths to the same file or directory.
  ##
  ## See also:
  ## * `sameFileContent proc`_
  when defined(windows):
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

    if not success: raiseOSError(lastErr, $(path1, path2))
  else:
    var a, b: Stat
    if stat(path1, a) < 0'i32 or stat(path2, b) < 0'i32:
      raiseOSError(osLastError(), $(path1, path2))
    else:
      result = a.st_dev == b.st_dev and a.st_ino == b.st_ino

type
  FilePermission* = enum   ## File access permission, modelled after UNIX.
    ##
    ## See also:
    ## * `getFilePermissions`_
    ## * `setFilePermissions`_
    ## * `FileInfo object`_
    fpUserExec,            ## execute access for the file owner
    fpUserWrite,           ## write access for the file owner
    fpUserRead,            ## read access for the file owner
    fpGroupExec,           ## execute access for the group
    fpGroupWrite,          ## write access for the group
    fpGroupRead,           ## read access for the group
    fpOthersExec,          ## execute access for others
    fpOthersWrite,         ## write access for others
    fpOthersRead           ## read access for others

proc getFilePermissions*(filename: string): set[FilePermission] {.
  rtl, extern: "nos$1", tags: [ReadDirEffect], noWeirdTarget.} =
  ## Retrieves file permissions for `filename`.
  ##
  ## `OSError` is raised in case of an error.
  ## On Windows, only the ``readonly`` flag is checked, every other
  ## permission is available in any case.
  ##
  ## See also:
  ## * `setFilePermissions proc`_
  ## * `FilePermission enum`_
  when defined(posix):
    var a: Stat
    if stat(filename, a) < 0'i32: raiseOSError(osLastError(), filename)
    result = {}
    if (a.st_mode and S_IRUSR.Mode) != 0.Mode: result.incl(fpUserRead)
    if (a.st_mode and S_IWUSR.Mode) != 0.Mode: result.incl(fpUserWrite)
    if (a.st_mode and S_IXUSR.Mode) != 0.Mode: result.incl(fpUserExec)

    if (a.st_mode and S_IRGRP.Mode) != 0.Mode: result.incl(fpGroupRead)
    if (a.st_mode and S_IWGRP.Mode) != 0.Mode: result.incl(fpGroupWrite)
    if (a.st_mode and S_IXGRP.Mode) != 0.Mode: result.incl(fpGroupExec)

    if (a.st_mode and S_IROTH.Mode) != 0.Mode: result.incl(fpOthersRead)
    if (a.st_mode and S_IWOTH.Mode) != 0.Mode: result.incl(fpOthersWrite)
    if (a.st_mode and S_IXOTH.Mode) != 0.Mode: result.incl(fpOthersExec)
  else:
    when useWinUnicode:
      wrapUnary(res, getFileAttributesW, filename)
    else:
      var res = getFileAttributesA(filename)
    if res == -1'i32: raiseOSError(osLastError(), filename)
    if (res and FILE_ATTRIBUTE_READONLY) != 0'i32:
      result = {fpUserExec, fpUserRead, fpGroupExec, fpGroupRead,
                fpOthersExec, fpOthersRead}
    else:
      result = {fpUserExec..fpOthersRead}

proc setFilePermissions*(filename: string, permissions: set[FilePermission],
                         followSymlinks = true)
  {.rtl, extern: "nos$1", tags: [ReadDirEffect, WriteDirEffect],
   noWeirdTarget.} =
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
  ## * `FilePermission enum`_
  when defined(posix):
    var p = 0.Mode
    if fpUserRead in permissions: p = p or S_IRUSR.Mode
    if fpUserWrite in permissions: p = p or S_IWUSR.Mode
    if fpUserExec in permissions: p = p or S_IXUSR.Mode

    if fpGroupRead in permissions: p = p or S_IRGRP.Mode
    if fpGroupWrite in permissions: p = p or S_IWGRP.Mode
    if fpGroupExec in permissions: p = p or S_IXGRP.Mode

    if fpOthersRead in permissions: p = p or S_IROTH.Mode
    if fpOthersWrite in permissions: p = p or S_IWOTH.Mode
    if fpOthersExec in permissions: p = p or S_IXOTH.Mode

    if not followSymlinks and filename.symlinkExists:
      when declared(lchmod):
        if lchmod(filename, cast[Mode](p)) != 0:
          raiseOSError(osLastError(), $(filename, permissions))
    else:
      if chmod(filename, cast[Mode](p)) != 0:
        raiseOSError(osLastError(), $(filename, permissions))
  else:
    when useWinUnicode:
      wrapUnary(res, getFileAttributesW, filename)
    else:
      var res = getFileAttributesA(filename)
    if res == -1'i32: raiseOSError(osLastError(), filename)
    if fpUserWrite in permissions:
      res = res and not FILE_ATTRIBUTE_READONLY
    else:
      res = res or FILE_ATTRIBUTE_READONLY
    when useWinUnicode:
      wrapBinary(res2, setFileAttributesW, filename, res)
    else:
      var res2 = setFileAttributesA(filename, res)
    if res2 == - 1'i32: raiseOSError(osLastError(), $(filename, permissions))

proc isAdmin*: bool {.noWeirdTarget.} =
  ## Returns whether the caller's process is a member of the Administrators local
  ## group (on Windows) or a root (on POSIX), via `geteuid() == 0`.
  when defined(windows):
    # Rewrite of the example from Microsoft Docs:
    # https://docs.microsoft.com/en-us/windows/win32/api/securitybaseapi/nf-securitybaseapi-checktokenmembership#examples
    # and corresponding PostgreSQL function:
    # https://doxygen.postgresql.org/win32security_8c.html#ae6b61e106fa5d6c5d077a9d14ee80569
    var ntAuthority = SID_IDENTIFIER_AUTHORITY(value: SECURITY_NT_AUTHORITY)
    var administratorsGroup: PSID
    if not isSuccess(allocateAndInitializeSid(addr ntAuthority,
                                              BYTE(2),
                                              SECURITY_BUILTIN_DOMAIN_RID,
                                              DOMAIN_ALIAS_RID_ADMINS,
                                              0, 0, 0, 0, 0, 0,
                                              addr administratorsGroup)):
      raiseOSError(osLastError(), "could not get SID for Administrators group")

    try:
      var b: WINBOOL
      if not isSuccess(checkTokenMembership(0, administratorsGroup, addr b)):
        raiseOSError(osLastError(), "could not check access token membership")

      result = isSuccess(b)
    finally:
      if freeSid(administratorsGroup) != nil:
        raiseOSError(osLastError(), "failed to free SID for Administrators group")

  else:
    result = geteuid() == 0



proc exitStatusLikeShell*(status: cint): cint =
  ## Converts exit code from `c_system` into a shell exit code.
  when defined(posix) and not weirdTarget:
    if WIFSIGNALED(status):
      # like the shell!
      128 + WTERMSIG(status)
    else:
      WEXITSTATUS(status)
  else:
    status

proc execShellCmd*(command: string): int {.rtl, extern: "nos$1",
  tags: [ExecIOEffect], noWeirdTarget.} =
  ## Executes a `shell command`:idx:.
  ##
  ## Command has the form 'program args' where args are the command
  ## line arguments given to program. The proc returns the error code
  ## of the shell when it has finished (zero if there is no error).
  ## The proc does not return until the process has finished.
  ##
  ## To execute a program without having a shell involved, use `osproc.execProcess proc
  ## <osproc.html#execProcess,string,string,openArray[string],StringTableRef,set[ProcessOption]>`_.
  ##
  ## **Examples:**
  ##
  ## .. code-block::
  ##   discard execShellCmd("ls -la")
  result = exitStatusLikeShell(c_system(command))

proc expandFilename*(filename: string): string {.rtl, extern: "nos$1",
  tags: [ReadDirEffect], noWeirdTarget.} =
  ## Returns the full (`absolute`:idx:) path of an existing file `filename`.
  ##
  ## Raises `OSError` in case of an error. Follows symlinks.
  when defined(windows):
    var bufsize = MAX_PATH.int32
    when useWinUnicode:
      var unused: WideCString = nil
      var res = newWideCString("", bufsize)
      while true:
        var L = getFullPathNameW(newWideCString(filename), bufsize, res, unused)
        if L == 0'i32:
          raiseOSError(osLastError(), filename)
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
          raiseOSError(osLastError(), filename)
        elif L > bufsize:
          result = newString(L)
          bufsize = L
        else:
          setLen(result, L)
          break
    # getFullPathName doesn't do case corrections, so we have to use this convoluted
    # way of retrieving the true filename
    for x in walkFiles(result):
      result = x
    if not fileExists(result) and not dirExists(result):
      # consider using: `raiseOSError(osLastError(), result)`
      raise newException(OSError, "file '" & result & "' does not exist")
  else:
    # according to Posix we don't need to allocate space for result pathname.
    # But we need to free return value with free(3).
    var r = realpath(filename, nil)
    if r.isNil:
      raiseOSError(osLastError(), filename)
    else:
      result = $r
      c_free(cast[pointer](r))

proc getCurrentCompilerExe*(): string {.compileTime.} = discard
  ## This is `getAppFilename()`_ at compile time.
  ##
  ## Can be used to retrieve the currently executing
  ## Nim compiler from a Nim or nimscript program, or the nimble binary
  ## inside a nimble program (likewise with other binaries built from
  ## compiler API).

proc createHardlink*(src, dest: string) {.noWeirdTarget.} =
  ## Create a hard link at `dest` which points to the item specified
  ## by `src`.
  ##
  ## .. warning:: Some OS's restrict the creation of hard links to
  ##   root users (administrators).
  ##
  ## See also:
  ## * `createSymlink proc`_
  when defined(windows):
    when useWinUnicode:
      var wSrc = newWideCString(src)
      var wDst = newWideCString(dest)
      if createHardLinkW(wDst, wSrc, nil) == 0:
        raiseOSError(osLastError(), $(src, dest))
    else:
      if createHardLinkA(dest, src, nil) == 0:
        raiseOSError(osLastError(), $(src, dest))
  else:
    if link(src, dest) != 0:
      raiseOSError(osLastError(), $(src, dest))

proc inclFilePermissions*(filename: string,
                          permissions: set[FilePermission]) {.
  rtl, extern: "nos$1", tags: [ReadDirEffect, WriteDirEffect], noWeirdTarget.} =
  ## A convenience proc for:
  ##
  ## .. code-block:: nim
  ##   setFilePermissions(filename, getFilePermissions(filename)+permissions)
  setFilePermissions(filename, getFilePermissions(filename)+permissions)

proc exclFilePermissions*(filename: string,
                          permissions: set[FilePermission]) {.
  rtl, extern: "nos$1", tags: [ReadDirEffect, WriteDirEffect], noWeirdTarget.} =
  ## A convenience proc for:
  ##
  ## .. code-block:: nim
  ##   setFilePermissions(filename, getFilePermissions(filename)-permissions)
  setFilePermissions(filename, getFilePermissions(filename)-permissions)

proc parseCmdLine*(c: string): seq[string] {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Splits a `command line`:idx: into several components.
  ##
  ## **Note**: This proc is only occasionally useful, better use the
  ## `parseopt module <parseopt.html>`_.
  ##
  ## On Windows, it uses the `following parsing rules
  ## <http://msdn.microsoft.com/en-us/library/17w5ykft.aspx>`_:
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
  ##
  ## See also:
  ## * `parseopt module <parseopt.html>`_
  ## * `paramCount proc`_
  ## * `paramStr proc`_
  ## * `commandLineParams proc`_

  result = @[]
  var i = 0
  var a = ""
  while true:
    setLen(a, 0)
    # eat all delimiting whitespace
    while i < c.len and c[i] in {' ', '\t', '\l', '\r'}: inc(i)
    if i >= c.len: break
    when defined(windows):
      # parse a single argument according to the above rules:
      var inQuote = false
      while i < c.len:
        case c[i]
        of '\\':
          var j = i
          while j < c.len and c[j] == '\\': inc(j)
          if j < c.len and c[j] == '"':
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
          elif i < c.len and c[i] == '"':
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
        while i < c.len and c[i] != delim:
          add a, c[i]
          inc(i)
        if i < c.len: inc(i)
      else:
        while i < c.len and c[i] > ' ':
          add(a, c[i])
          inc(i)
    add(result, a)

when defined(nimdoc):
  # Common forward declaration docstring block for parameter retrieval procs.
  proc paramCount*(): int {.tags: [ReadIOEffect].} =
    ## Returns the number of `command line arguments`:idx: given to the
    ## application.
    ##
    ## Unlike `argc`:idx: in C, if your binary was called without parameters this
    ## will return zero.
    ## You can query each individual parameter with `paramStr proc`_
    ## or retrieve all of them in one go with `commandLineParams proc`_.
    ##
    ## **Availability**: When generating a dynamic library (see `--app:lib`) on
    ## Posix this proc is not defined.
    ## Test for availability using `declared() <system.html#declared,untyped>`_.
    ##
    ## See also:
    ## * `parseopt module <parseopt.html>`_
    ## * `parseCmdLine proc`_
    ## * `paramStr proc`_
    ## * `commandLineParams proc`_
    ##
    ## **Examples:**
    ##
    ## .. code-block:: nim
    ##   when declared(paramCount):
    ##     # Use paramCount() here
    ##   else:
    ##     # Do something else!

  proc paramStr*(i: int): string {.tags: [ReadIOEffect].} =
    ## Returns the `i`-th `command line argument`:idx: given to the application.
    ##
    ## `i` should be in the range `1..paramCount()`, the `IndexDefect`
    ## exception will be raised for invalid values. Instead of iterating
    ## over `paramCount()`_ with this proc you can
    ## call the convenience `commandLineParams()`_.
    ##
    ## Similarly to `argv`:idx: in C,
    ## it is possible to call `paramStr(0)` but this will return OS specific
    ## contents (usually the name of the invoked executable). You should avoid
    ## this and call `getAppFilename()`_ instead.
    ##
    ## **Availability**: When generating a dynamic library (see `--app:lib`) on
    ## Posix this proc is not defined.
    ## Test for availability using `declared() <system.html#declared,untyped>`_.
    ##
    ## See also:
    ## * `parseopt module <parseopt.html>`_
    ## * `parseCmdLine proc`_
    ## * `paramCount proc`_
    ## * `commandLineParams proc`_
    ## * `getAppFilename proc`_
    ##
    ## **Examples:**
    ##
    ## .. code-block:: nim
    ##   when declared(paramStr):
    ##     # Use paramStr() here
    ##   else:
    ##     # Do something else!

elif defined(nimscript): discard
elif defined(nodejs):
  type Argv = object of JsRoot
  let argv {.importjs: "process.argv".} : Argv
  proc len(argv: Argv): int {.importjs: "#.length".}
  proc `[]`(argv: Argv, i: int): cstring {.importjs: "#[#]".}

  proc paramCount*(): int {.tags: [ReadDirEffect].} =
    result = argv.len - 2

  proc paramStr*(i: int): string {.tags: [ReadIOEffect].} =
    let i = i + 1
    if i < argv.len and i >= 0:
      result = $argv[i]
    else:
      raise newException(IndexDefect, formatErrorIndexBound(i - 1, argv.len - 2))
elif defined(windows):
  # Since we support GUI applications with Nim, we sometimes generate
  # a WinMain entry proc. But a WinMain proc has no access to the parsed
  # command line arguments. The way to get them differs. Thus we parse them
  # ourselves. This has the additional benefit that the program's behaviour
  # is always the same -- independent of the used C compiler.
  var
    ownArgv {.threadvar.}: seq[string]
    ownParsedArgv {.threadvar.}: bool

  proc paramCount*(): int {.rtl, extern: "nos$1", tags: [ReadIOEffect].} =
    # Docstring in nimdoc block.
    if not ownParsedArgv:
      ownArgv = parseCmdLine($getCommandLine())
      ownParsedArgv = true
    result = ownArgv.len-1

  proc paramStr*(i: int): string {.rtl, extern: "nos$1",
    tags: [ReadIOEffect].} =
    # Docstring in nimdoc block.
    if not ownParsedArgv:
      ownArgv = parseCmdLine($getCommandLine())
      ownParsedArgv = true
    if i < ownArgv.len and i >= 0:
      result = ownArgv[i]
    else:
      raise newException(IndexDefect, formatErrorIndexBound(i, ownArgv.len-1))

elif defined(genode):
  proc paramStr*(i: int): string =
    raise newException(OSError, "paramStr is not implemented on Genode")

  proc paramCount*(): int =
    raise newException(OSError, "paramCount is not implemented on Genode")
elif weirdTarget or (defined(posix) and appType == "lib"):
  proc paramStr*(i: int): string {.tags: [ReadIOEffect].} =
    raise newException(OSError, "paramStr is not implemented on current platform")

  proc paramCount*(): int {.tags: [ReadIOEffect].} =
    raise newException(OSError, "paramCount is not implemented on current platform")
elif not defined(createNimRtl) and
  not(defined(posix) and appType == "lib"):
  # On Posix, there is no portable way to get the command line from a DLL.
  var
    cmdCount {.importc: "cmdCount".}: cint
    cmdLine {.importc: "cmdLine".}: cstringArray

  proc paramStr*(i: int): string {.tags: [ReadIOEffect].} =
    # Docstring in nimdoc block.
    if i < cmdCount and i >= 0:
      result = $cmdLine[i]
    else:
      raise newException(IndexDefect, formatErrorIndexBound(i, cmdCount-1))

  proc paramCount*(): int {.tags: [ReadIOEffect].} =
    # Docstring in nimdoc block.
    result = cmdCount-1

when declared(paramCount) or defined(nimdoc):
  proc commandLineParams*(): seq[string] =
    ## Convenience proc which returns the command line parameters.
    ##
    ## This returns **only** the parameters. If you want to get the application
    ## executable filename, call `getAppFilename()`_.
    ##
    ## **Availability**: On Posix there is no portable way to get the command
    ## line from a DLL and thus the proc isn't defined in this environment. You
    ## can test for its availability with `declared()
    ## <system.html#declared,untyped>`_.
    ##
    ## See also:
    ## * `parseopt module <parseopt.html>`_
    ## * `parseCmdLine proc`_
    ## * `paramCount proc`_
    ## * `paramStr proc`_
    ## * `getAppFilename proc`_
    ##
    ## **Examples:**
    ##
    ## .. code-block:: nim
    ##   when declared(commandLineParams):
    ##     # Use commandLineParams() here
    ##   else:
    ##     # Do something else!
    result = @[]
    for i in 1..paramCount():
      result.add(paramStr(i))
else:
  proc commandLineParams*(): seq[string] {.error:
  "commandLineParams() unsupported by dynamic libraries".} =
    discard

when not weirdTarget and (defined(freebsd) or defined(dragonfly) or defined(netbsd)):
  proc sysctl(name: ptr cint, namelen: cuint, oldp: pointer, oldplen: ptr csize_t,
              newp: pointer, newplen: csize_t): cint
       {.importc: "sysctl",header: """#include <sys/types.h>
                                      #include <sys/sysctl.h>""".}
  const
    CTL_KERN = 1
    KERN_PROC = 14
    MAX_PATH = 1024

  when defined(freebsd):
    const KERN_PROC_PATHNAME = 12
  elif defined(netbsd):
    const KERN_PROC_ARGS = 48
    const KERN_PROC_PATHNAME = 5
  else:
    const KERN_PROC_PATHNAME = 9

  proc getApplFreebsd(): string =
    var pathLength = csize_t(0)

    when defined(netbsd):
      var req = [CTL_KERN.cint, KERN_PROC_ARGS.cint, -1.cint, KERN_PROC_PATHNAME.cint]
    else:
      var req = [CTL_KERN.cint, KERN_PROC.cint, KERN_PROC_PATHNAME.cint, -1.cint]

    # first call to get the required length
    var res = sysctl(addr req[0], 4, nil, addr pathLength, nil, 0)

    if res < 0:
      return ""

    result.setLen(pathLength)
    res = sysctl(addr req[0], 4, addr result[0], addr pathLength, nil, 0)

    if res < 0:
      return ""

    let realLen = len(cstring(result))
    setLen(result, realLen)

when not weirdTarget and (defined(linux) or defined(solaris) or defined(bsd) or defined(aix)):
  proc getApplAux(procPath: string): string =
    result = newString(maxSymlinkLen)
    var len = readlink(procPath, result.cstring, maxSymlinkLen)
    if len > maxSymlinkLen:
      result = newString(len+1)
      len = readlink(procPath, result.cstring, len)
    setLen(result, len)

when not weirdTarget and defined(openbsd):
  proc getApplOpenBsd(): string =
    # similar to getApplHeuristic, but checks current working directory
    when declared(paramStr):
      result = ""

      # POSIX guaranties that this contains the executable
      # as it has been executed by the calling process
      let exePath = paramStr(0)

      if len(exePath) == 0:
        return ""

      if exePath[0] == DirSep:
        # path is absolute
        result = exePath
      else:
        # not an absolute path, check if it's relative to the current working directory
        for i in 1..<len(exePath):
          if exePath[i] == DirSep:
            result = joinPath(getCurrentDir(), exePath)
            break

      if len(result) > 0:
        return expandFilename(result)

      # search in path
      for p in split(getEnv("PATH"), {PathSep}):
        var x = joinPath(p, exePath)
        if fileExists(x):
          return expandFilename(x)
    else:
      result = ""

when not (defined(windows) or defined(macosx) or weirdTarget):
  proc getApplHeuristic(): string =
    when declared(paramStr):
      result = paramStr(0)
      # POSIX guaranties that this contains the executable
      # as it has been executed by the calling process
      if len(result) > 0 and result[0] != DirSep: # not an absolute path?
        # iterate over any path in the $PATH environment variable
        for p in split(getEnv("PATH"), {PathSep}):
          var x = joinPath(p, result)
          if fileExists(x): return x
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

when defined(haiku):
  const
    PATH_MAX = 1024
    B_FIND_PATH_IMAGE_PATH = 1000

  proc find_path(codePointer: pointer, baseDirectory: cint, subPath: cstring,
                 pathBuffer: cstring, bufferSize: csize_t): int32
                {.importc, header: "<FindDirectory.h>".}

  proc getApplHaiku(): string =
    result = newString(PATH_MAX)

    if find_path(nil, B_FIND_PATH_IMAGE_PATH, nil, result, PATH_MAX) == 0:
      let realLen = len(cstring(result))
      setLen(result, realLen)
    else:
      result = ""

proc getAppFilename*(): string {.rtl, extern: "nos$1", tags: [ReadIOEffect], noWeirdTarget.} =
  ## Returns the filename of the application's executable.
  ## This proc will resolve symlinks.
  ##
  ## See also:
  ## * `getAppDir proc`_
  ## * `getCurrentCompilerExe proc`_

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
    var size = cuint32(0)
    getExecPath1(nil, size)
    result = newString(int(size))
    if getExecPath2(result.cstring, size):
      result = "" # error!
    if result.len > 0:
      result = result.expandFilename
  else:
    when defined(linux) or defined(aix):
      result = getApplAux("/proc/self/exe")
    elif defined(solaris):
      result = getApplAux("/proc/" & $getpid() & "/path/a.out")
    elif defined(genode):
      raiseOSError(OSErrorCode(-1), "POSIX command line not supported")
    elif defined(freebsd) or defined(dragonfly) or defined(netbsd):
      result = getApplFreebsd()
    elif defined(haiku):
      result = getApplHaiku()
    elif defined(openbsd):
      result = getApplOpenBsd()

    # little heuristic that may work on other POSIX-like systems:
    if result.len == 0:
      result = getApplHeuristic()

proc getAppDir*(): string {.rtl, extern: "nos$1", tags: [ReadIOEffect], noWeirdTarget.} =
  ## Returns the directory of the application's executable.
  ##
  ## See also:
  ## * `getAppFilename proc`_
  result = splitFile(getAppFilename()).dir

proc sleep*(milsecs: int) {.rtl, extern: "nos$1", tags: [TimeEffect], noWeirdTarget.} =
  ## Sleeps `milsecs` milliseconds.
  when defined(windows):
    winlean.sleep(int32(milsecs))
  else:
    var a, b: Timespec
    a.tv_sec = posix.Time(milsecs div 1000)
    a.tv_nsec = (milsecs mod 1000) * 1000 * 1000
    discard posix.nanosleep(a, b)

proc getFileSize*(file: string): BiggestInt {.rtl, extern: "nos$1",
  tags: [ReadIOEffect], noWeirdTarget.} =
  ## Returns the file size of `file` (in bytes). ``OSError`` is
  ## raised in case of an error.
  when defined(windows):
    var a: WIN32_FIND_DATA
    var resA = findFirstFile(file, a)
    if resA == -1: raiseOSError(osLastError(), file)
    result = rdFileSize(a)
    findClose(resA)
  else:
    var rawInfo: Stat
    if stat(file, rawInfo) < 0'i32:
      raiseOSError(osLastError(), file)
    rawInfo.st_size

when defined(windows) or weirdTarget:
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
    ##
    ## See also:
    ## * `getFileInfo(handle) proc`_
    ## * `getFileInfo(file) proc`_
    ## * `getFileInfo(path, followSymlink) proc`_
    id*: tuple[device: DeviceId, file: FileId] ## Device and file id.
    kind*: PathComponent              ## Kind of file object - directory, symlink, etc.
    size*: BiggestInt                 ## Size of file.
    permissions*: set[FilePermission] ## File permissions
    linkCount*: BiggestInt            ## Number of hard links the file object has.
    lastAccessTime*: times.Time       ## Time file was last accessed.
    lastWriteTime*: times.Time        ## Time file was last modified/written to.
    creationTime*: times.Time         ## Time file was created. Not supported on all systems!
    blockSize*: int                   ## Preferred I/O block size for this object.
                                      ## In some filesystems, this may vary from file to file.

template rawToFormalFileInfo(rawInfo, path, formalInfo): untyped =
  ## Transforms the native file info structure into the one nim uses.
  ## 'rawInfo' is either a 'BY_HANDLE_FILE_INFORMATION' structure on Windows,
  ## or a 'Stat' structure on posix
  when defined(windows):
    template merge(a, b): untyped =
      int64(
        (uint64(cast[uint32](a))) or
        (uint64(cast[uint32](b)) shl 32)
       )
    formalInfo.id.device = rawInfo.dwVolumeSerialNumber
    formalInfo.id.file = merge(rawInfo.nFileIndexLow, rawInfo.nFileIndexHigh)
    formalInfo.size = merge(rawInfo.nFileSizeLow, rawInfo.nFileSizeHigh)
    formalInfo.linkCount = rawInfo.nNumberOfLinks
    formalInfo.lastAccessTime = fromWinTime(rdFileTime(rawInfo.ftLastAccessTime))
    formalInfo.lastWriteTime = fromWinTime(rdFileTime(rawInfo.ftLastWriteTime))
    formalInfo.creationTime = fromWinTime(rdFileTime(rawInfo.ftCreationTime))
    formalInfo.blockSize = 8192 # xxx use Windows API instead of hardcoding

    # Retrieve basic permissions
    if (rawInfo.dwFileAttributes and FILE_ATTRIBUTE_READONLY) != 0'i32:
      formalInfo.permissions = {fpUserExec, fpUserRead, fpGroupExec,
                                fpGroupRead, fpOthersExec, fpOthersRead}
    else:
      formalInfo.permissions = {fpUserExec..fpOthersRead}

    # Retrieve basic file kind
    if (rawInfo.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) != 0'i32:
      formalInfo.kind = pcDir
    else:
      formalInfo.kind = pcFile
    if (rawInfo.dwFileAttributes and FILE_ATTRIBUTE_REPARSE_POINT) != 0'i32:
      formalInfo.kind = succ(formalInfo.kind)

  else:
    template checkAndIncludeMode(rawMode, formalMode: untyped) =
      if (rawInfo.st_mode and rawMode.Mode) != 0.Mode:
        formalInfo.permissions.incl(formalMode)
    formalInfo.id = (rawInfo.st_dev, rawInfo.st_ino)
    formalInfo.size = rawInfo.st_size
    formalInfo.linkCount = rawInfo.st_nlink.BiggestInt
    formalInfo.lastAccessTime = rawInfo.st_atim.toTime
    formalInfo.lastWriteTime = rawInfo.st_mtim.toTime
    formalInfo.creationTime = rawInfo.st_ctim.toTime
    formalInfo.blockSize = rawInfo.st_blksize

    formalInfo.permissions = {}
    checkAndIncludeMode(S_IRUSR, fpUserRead)
    checkAndIncludeMode(S_IWUSR, fpUserWrite)
    checkAndIncludeMode(S_IXUSR, fpUserExec)

    checkAndIncludeMode(S_IRGRP, fpGroupRead)
    checkAndIncludeMode(S_IWGRP, fpGroupWrite)
    checkAndIncludeMode(S_IXGRP, fpGroupExec)

    checkAndIncludeMode(S_IROTH, fpOthersRead)
    checkAndIncludeMode(S_IWOTH, fpOthersWrite)
    checkAndIncludeMode(S_IXOTH, fpOthersExec)

    formalInfo.kind =
      if S_ISDIR(rawInfo.st_mode):
        pcDir
      elif S_ISLNK(rawInfo.st_mode):
        assert(path != "") # symlinks can't occur for file handles
        getSymlinkFileKind(path)
      else:
        pcFile

when defined(js):
  when not declared(FileHandle):
    type FileHandle = distinct int32
  when not declared(File):
    type File = object

proc getFileInfo*(handle: FileHandle): FileInfo {.noWeirdTarget.} =
  ## Retrieves file information for the file object represented by the given
  ## handle.
  ##
  ## If the information cannot be retrieved, such as when the file handle
  ## is invalid, `OSError` is raised.
  ##
  ## See also:
  ## * `getFileInfo(file) proc`_
  ## * `getFileInfo(path, followSymlink) proc`_

  # Done: ID, Kind, Size, Permissions, Link Count
  when defined(windows):
    var rawInfo: BY_HANDLE_FILE_INFORMATION
    # We have to use the super special '_get_osfhandle' call (wrapped above)
    # To transform the C file descriptor to a native file handle.
    var realHandle = get_osfhandle(handle)
    if getFileInformationByHandle(realHandle, addr rawInfo) == 0:
      raiseOSError(osLastError(), $handle)
    rawToFormalFileInfo(rawInfo, "", result)
  else:
    var rawInfo: Stat
    if fstat(handle, rawInfo) < 0'i32:
      raiseOSError(osLastError(), $handle)
    rawToFormalFileInfo(rawInfo, "", result)

proc getFileInfo*(file: File): FileInfo {.noWeirdTarget.} =
  ## Retrieves file information for the file object.
  ##
  ## See also:
  ## * `getFileInfo(handle) proc`_
  ## * `getFileInfo(path, followSymlink) proc`_
  if file.isNil:
    raise newException(IOError, "File is nil")
  result = getFileInfo(file.getFileHandle())

proc getFileInfo*(path: string, followSymlink = true): FileInfo {.noWeirdTarget.} =
  ## Retrieves file information for the file object pointed to by `path`.
  ##
  ## Due to intrinsic differences between operating systems, the information
  ## contained by the returned `FileInfo object`_ will be slightly
  ## different across platforms, and in some cases, incomplete or inaccurate.
  ##
  ## When `followSymlink` is true (default), symlinks are followed and the
  ## information retrieved is information related to the symlink's target.
  ## Otherwise, information on the symlink itself is retrieved.
  ##
  ## If the information cannot be retrieved, such as when the path doesn't
  ## exist, or when permission restrictions prevent the program from retrieving
  ## file information, `OSError` is raised.
  ##
  ## See also:
  ## * `getFileInfo(handle) proc`_
  ## * `getFileInfo(file) proc`_
  when defined(windows):
    var
      handle = openHandle(path, followSymlink)
      rawInfo: BY_HANDLE_FILE_INFORMATION
    if handle == INVALID_HANDLE_VALUE:
      raiseOSError(osLastError(), path)
    if getFileInformationByHandle(handle, addr rawInfo) == 0:
      raiseOSError(osLastError(), path)
    rawToFormalFileInfo(rawInfo, path, result)
    discard closeHandle(handle)
  else:
    var rawInfo: Stat
    if followSymlink:
      if stat(path, rawInfo) < 0'i32:
        raiseOSError(osLastError(), path)
    else:
      if lstat(path, rawInfo) < 0'i32:
        raiseOSError(osLastError(), path)
    rawToFormalFileInfo(rawInfo, path, result)

proc sameFileContent*(path1, path2: string): bool {.rtl, extern: "nos$1",
  tags: [ReadIOEffect], noWeirdTarget.} =
  ## Returns true if both pathname arguments refer to files with identical
  ## binary content.
  ##
  ## See also:
  ## * `sameFile proc`_
  var
    a, b: File
  if not open(a, path1): return false
  if not open(b, path2):
    close(a)
    return false
  let bufSize = getFileInfo(a).blockSize
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

proc isHidden*(path: string): bool {.noWeirdTarget.} =
  ## Determines whether ``path`` is hidden or not, using `this
  ## reference <https://en.wikipedia.org/wiki/Hidden_file_and_hidden_directory>`_.
  ##
  ## On Windows: returns true if it exists and its "hidden" attribute is set.
  ##
  ## On posix: returns true if ``lastPathPart(path)`` starts with ``.`` and is
  ## not ``.`` or ``..``.
  ##
  ## **Note**: paths are not normalized to determine `isHidden`.
  runnableExamples:
    when defined(posix):
      assert ".foo".isHidden
      assert not ".foo/bar".isHidden
      assert not ".".isHidden
      assert not "..".isHidden
      assert not "".isHidden
      assert ".foo/".isHidden

  when defined(windows):
    when useWinUnicode:
      wrapUnary(attributes, getFileAttributesW, path)
    else:
      var attributes = getFileAttributesA(path)
    if attributes != -1'i32:
      result = (attributes and FILE_ATTRIBUTE_HIDDEN) != 0'i32
  else:
    let fileName = lastPathPart(path)
    result = len(fileName) >= 2 and fileName[0] == '.' and fileName != ".."

proc getCurrentProcessId*(): int {.noWeirdTarget.} =
  ## Return current process ID.
  ##
  ## See also:
  ## * `osproc.processID(p: Process) <osproc.html#processID,Process>`_
  when defined(windows):
    proc GetCurrentProcessId(): DWORD {.stdcall, dynlib: "kernel32",
                                        importc: "GetCurrentProcessId".}
    result = GetCurrentProcessId().int
  else:
    result = getpid()

proc setLastModificationTime*(file: string, t: times.Time) {.noWeirdTarget.} =
  ## Sets the `file`'s last modification time. `OSError` is raised in case of
  ## an error.
  when defined(posix):
    let unixt = posix.Time(t.toUnix)
    let micro = convert(Nanoseconds, Microseconds, t.nanosecond)
    var timevals = [Timeval(tv_sec: unixt, tv_usec: micro),
      Timeval(tv_sec: unixt, tv_usec: micro)] # [last access, last modification]
    if utimes(file, timevals.addr) != 0: raiseOSError(osLastError(), file)
  else:
    let h = openHandle(path = file, writeAccess = true)
    if h == INVALID_HANDLE_VALUE: raiseOSError(osLastError(), file)
    var ft = t.toWinTime.toFILETIME
    let res = setFileTime(h, nil, nil, ft.addr)
    discard h.closeHandle
    if res == 0'i32: raiseOSError(osLastError(), file)


func isValidFilename*(filename: string, maxLen = 259.Positive): bool {.since: (1, 1).} =
  ## Returns `true` if `filename` is valid for crossplatform use.
  ##
  ## This is useful if you want to copy or save files across Windows, Linux, Mac, etc.
  ## It uses `invalidFilenameChars`, `invalidFilenames` and `maxLen` to verify the specified `filename`.
  ##
  ## See also:
  ##
  ## * https://docs.microsoft.com/en-us/dotnet/api/system.io.pathtoolongexception
  ## * https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file
  ## * https://msdn.microsoft.com/en-us/library/windows/desktop/aa365247%28v=vs.85%29.aspx
  ##
  ## .. warning:: This only checks filenames, not whole paths
  ##    (because basically you can mount anything as a path on Linux).
  runnableExamples:
    assert not isValidFilename(" foo")     # Leading white space
    assert not isValidFilename("foo ")     # Trailing white space
    assert not isValidFilename("foo.")     # Ends with dot
    assert not isValidFilename("con.txt")  # "CON" is invalid (Windows)
    assert not isValidFilename("OwO:UwU")  # ":" is invalid (Mac)
    assert not isValidFilename("aux.bat")  # "AUX" is invalid (Windows)
    assert not isValidFilename("")         # Empty string
    assert not isValidFilename("foo/")     # Filename is empty

  result = true
  let f = filename.splitFile()
  if unlikely(f.name.len + f.ext.len > maxLen or f.name.len == 0 or
    f.name[0] == ' ' or f.name[^1] == ' ' or f.name[^1] == '.' or
    find(f.name, invalidFilenameChars) != -1): return false
  for invalid in invalidFilenames:
    if cmpIgnoreCase(f.name, invalid) == 0: return false


# deprecated declarations
when not defined(nimscript):
  when not defined(js): # `noNimJs` doesn't work with templates, this should improve.
    template existsFile*(args: varargs[untyped]): untyped {.deprecated: "use fileExists".} =
      fileExists(args)
    template existsDir*(args: varargs[untyped]): untyped {.deprecated: "use dirExists".} =
      dirExists(args)
  # {.deprecated: [existsFile: fileExists].} # pending bug #14819; this would avoid above mentioned issue
