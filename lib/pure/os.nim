#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
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

include "system/ansi_c"

type
  FReadEnv* = object of FReadIO   ## effect that denotes a read
                                  ## from an environment variable
  FWriteEnv* = object of FWriteIO ## effect that denotes a write
                                  ## to an environment variable

  FReadDir* = object of FReadIO   ## effect that denotes a write operation to
                                  ## the directory structure
  FWriteDir* = object of FWriteIO ## effect that denotes a write operation to
                                  ## the directory structure

  TOSErrorCode* = distinct int32 ## Specifies an OS Error Code.

const
  doslike = defined(windows) or defined(OS2) or defined(DOS)
    # DOS-like filesystem

when defined(Nimdoc): # only for proper documentation:
  const
    CurDir* = '.'
      ## The constant string used by the operating system to refer to the
      ## current directory.
      ##
      ## For example: '.' for POSIX or ':' for the classic Macintosh.

    ParDir* = ".."
      ## The constant string used by the operating system to refer to the
      ## parent directory.
      ##
      ## For example: ".." for POSIX or "::" for the classic Macintosh.

    DirSep* = '/'
      ## The character used by the operating system to separate pathname
      ## components, for example, '/' for POSIX or ':' for the classic
      ## Macintosh.

    AltSep* = '/'
      ## An alternative character used by the operating system to separate
      ## pathname components, or the same as `DirSep` if only one separator
      ## character exists. This is set to '/' on Windows systems where `DirSep`
      ## is a backslash.

    PathSep* = ':'
      ## The character conventionally used by the operating system to separate
      ## search patch components (as in PATH), such as ':' for POSIX or ';' for
      ## Windows.

    FileSystemCaseSensitive* = True
      ## True if the file system is case sensitive, false otherwise. Used by
      ## `cmpPaths` to compare filenames properly.

    ExeExt* = ""
      ## The file extension of native executables. For example:
      ## "" for POSIX, "exe" on Windows.

    ScriptExt* = ""
      ## The file extension of a script file. For example: "" for POSIX,
      ## "bat" on Windows.

    DynlibFormat* = "lib$1.so"
      ## The format string to turn a filename into a `DLL`:idx: file (also
      ## called `shared object`:idx: on some operating systems).

elif defined(macos):
  const
    CurDir* = ':'
    ParDir* = "::"
    DirSep* = ':'
    AltSep* = Dirsep
    PathSep* = ','
    FileSystemCaseSensitive* = false
    ExeExt* = ""
    ScriptExt* = ""
    DynlibFormat* = "$1.dylib"

  #  MacOS paths
  #  ===========
  #  MacOS directory separator is a colon ":" which is the only character not
  #  allowed in filenames.
  #
  #  A path containing no colon or which begins with a colon is a partial path.
  #  E.g. ":kalle:petter" ":kalle" "kalle"
  #
  #  All other paths are full (absolute) paths. E.g. "HD:kalle:" "HD:"
  #  When generating paths, one is safe if one ensures that all partial paths
  #  begin with a colon, and all full paths end with a colon.
  #  In full paths the first name (e g HD above) is the name of a mounted
  #  volume.
  #  These names are not unique, because, for instance, two diskettes with the
  #  same names could be inserted. This means that paths on MacOS are not
  #  waterproof. In case of equal names the first volume found will do.
  #  Two colons "::" are the relative path to the parent. Three is to the
  #  grandparent etc.
elif doslike:
  const
    CurDir* = '.'
    ParDir* = ".."
    DirSep* = '\\' # seperator within paths
    AltSep* = '/'
    PathSep* = ';' # seperator between paths
    FileSystemCaseSensitive* = false
    ExeExt* = "exe"
    ScriptExt* = "bat"
    DynlibFormat* = "$1.dll"
elif defined(PalmOS) or defined(MorphOS):
  const
    DirSep* = '/'
    AltSep* = Dirsep
    PathSep* = ';'
    ParDir* = ".."
    FileSystemCaseSensitive* = false
    ExeExt* = ""
    ScriptExt* = ""
    DynlibFormat* = "$1.prc"
elif defined(RISCOS):
  const
    DirSep* = '.'
    AltSep* = '.'
    ParDir* = ".." # is this correct?
    PathSep* = ','
    FileSystemCaseSensitive* = true
    ExeExt* = ""
    ScriptExt* = ""
    DynlibFormat* = "lib$1.so"
else: # UNIX-like operating system
  const
    CurDir* = '.'
    ParDir* = ".."
    DirSep* = '/'
    AltSep* = DirSep
    PathSep* = ':'
    FileSystemCaseSensitive* = true
    ExeExt* = ""
    ScriptExt* = ""
    DynlibFormat* = when defined(macosx): "lib$1.dylib" else: "lib$1.so"

when defined(posix):
  when NoFakeVars:
    const pathMax = 5000 # doesn't matter really. The concept of PATH_MAX
                         # doesn't work anymore on modern OSes.
  else:
    var
      pathMax {.importc: "PATH_MAX", header: "<stdlib.h>".}: cint

const
  ExtSep* = '.'
    ## The character which separates the base filename from the extension;
    ## for example, the '.' in ``os.nim``.

proc osErrorMsg*(): string {.rtl, extern: "nos$1", deprecated.} =
  ## Retrieves the operating system's error flag, ``errno``.
  ## On Windows ``GetLastError`` is checked before ``errno``.
  ## Returns "" if no error occured.
  ##
  ## **Deprecated since version 0.9.4**: use the other ``OSErrorMsg`` proc.

  result = ""
  when defined(Windows):
    var err = getLastError()
    if err != 0'i32:
      when useWinUnicode:
        var msgbuf: WideCString
        if formatMessageW(0x00000100 or 0x00001000 or 0x00000200,
                          nil, err, 0, addr(msgbuf), 0, nil) != 0'i32:
          result = $msgbuf
          if msgbuf != nil: localFree(cast[pointer](msgbuf))
      else:
        var msgbuf: cstring
        if formatMessageA(0x00000100 or 0x00001000 or 0x00000200,
                          nil, err, 0, addr(msgbuf), 0, nil) != 0'i32:
          result = $msgbuf
          if msgbuf != nil: localFree(msgbuf)
  if errno != 0'i32:
    result = $os.strerror(errno)

{.push warning[deprecated]: off.}
proc osError*(msg: string = "") {.noinline, rtl, extern: "nos$1", deprecated.} =
  ## raises an EOS exception with the given message ``msg``.
  ## If ``msg == ""``, the operating system's error flag
  ## (``errno``) is converted to a readable error message. On Windows
  ## ``GetLastError`` is checked before ``errno``.
  ## If no error flag is set, the message ``unknown OS error`` is used.
  ##
  ## **Deprecated since version 0.9.4**: use the other ``OSError`` proc.
  if len(msg) == 0:
    var m = osErrorMsg()
    raise newException(EOS, if m.len > 0: m else: "unknown OS error")
  else:
    raise newException(EOS, msg)
{.pop.}

proc `==`*(err1, err2: TOSErrorCode): bool {.borrow.}
proc `$`*(err: TOSErrorCode): string {.borrow.}

proc osErrorMsg*(errorCode: TOSErrorCode): string =
  ## Converts an OS error code into a human readable string.
  ##
  ## The error code can be retrieved using the ``OSLastError`` proc.
  ##
  ## If conversion fails, or ``errorCode`` is ``0`` then ``""`` will be
  ## returned.
  ##
  ## On Windows, the ``-d:useWinAnsi`` compilation flag can be used to
  ## make this procedure use the non-unicode Win API calls to retrieve the
  ## message.
  result = ""
  when defined(Windows):
    if errorCode != TOSErrorCode(0'i32):
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
    if errorCode != TOSErrorCode(0'i32):
      result = $os.strerror(errorCode.int32)

proc osError*(errorCode: TOSErrorCode) =
  ## Raises an ``EOS`` exception. The ``errorCode`` will determine the
  ## message, ``OSErrorMsg`` will be used to get this message.
  ##
  ## The error code can be retrieved using the ``OSLastError`` proc.
  ##
  ## If the error code is ``0`` or an error message could not be retrieved,
  ## the message ``unknown OS error`` will be used.
  let msg = osErrorMsg(errorCode)
  if msg == "":
    raise newException(EOS, "unknown OS error")
  else:
    raise newException(EOS, msg)

{.push stackTrace:off.}
proc osLastError*(): TOSErrorCode =
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
    result = TOSErrorCode(getLastError())
  else:
    result = TOSErrorCode(errno)
{.pop.}

proc unixToNativePath*(path: string, drive=""): string {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Converts an UNIX-like path to a native one.
  ##
  ## On an UNIX system this does nothing. Else it converts
  ## '/', '.', '..' to the appropriate things.
  ##
  ## On systems with a concept of "drives", `drive` is used to determine
  ## which drive label to use during absolute path conversion.
  ## `drive` defaults to the drive of the current working directory, and is
  ## ignored on systems that do not have a concept of "drives".

  when defined(unix):
    result = path
  else:
    var start: int
    if path[0] == '/':
      # an absolute path
      when doslike:
        if drive != "":
          result = drive & ":" & DirSep
        else:
          result = $DirSep
      elif defined(macos):
        result = "" # must not start with ':'
      else:
        result = $DirSep
      start = 1
    elif path[0] == '.' and path[1] == '/':
      # current directory
      result = $CurDir
      start = 2
    else:
      result = ""
      start = 0

    var i = start
    while i < len(path): # ../../../ --> ::::
      if path[i] == '.' and path[i+1] == '.' and path[i+2] == '/':
        # parent directory
        when defined(macos):
          if result[high(result)] == ':':
            add result, ':'
          else:
            add result, ParDir
        else:
          add result, ParDir & DirSep
        inc(i, 3)
      elif path[i] == '/':
        add result, DirSep
        inc(i)
      else:
        add result, path[i]
        inc(i)

when defined(windows):
  when useWinUnicode:
    # template wrapUnary(varname, winApiProc, arg: expr) {.immediate.} =
    #   var varname = winApiProc(newWideCString(arg))

    # template wrapBinary(varname, winApiProc, arg, arg2: expr) {.immediate.} =
    #   var varname = winApiProc(newWideCString(arg), arg2)
    template getCommandLine(): expr = getCommandLineW()

    template getFilename(f: expr): expr =
      $cast[WideCString](addr(f.cFilename[0]))
  else:
    template getCommandLine(): expr = getCommandLineA()

    template getFilename(f: expr): expr = $f.cFilename

  proc skipFindData(f: TWIN32_FIND_DATA): bool {.inline.} =
    const dot = ord('.')
    result = f.cFileName[0].int == dot and(f.cFileName[1].int == 0 or
             f.cFileName[1].int == dot and f.cFileName[2].int == 0)

proc existsFile*(filename: string): bool {.rtl, extern: "nos$1",
                                          tags: [FReadDir].} =
  ## Returns true if the file exists, false otherwise.
  when defined(windows):
    var a = getFileAttributes(filename)
    if a != -1'i32:
      result = (a and FILE_ATTRIBUTE_DIRECTORY) == 0'i32
  else:
    var res: TStat
    return stat(filename, res) >= 0'i32 and S_ISREG(res.st_mode)

proc existsDir*(dir: string): bool {.rtl, extern: "nos$1", tags: [FReadDir].} =
  ## Returns true iff the directory `dir` exists. If `dir` is a file, false
  ## is returned.
  when defined(windows):
    var a = getFileAttributes(dir)
    if a != -1'i32:
      result = (a and FILE_ATTRIBUTE_DIRECTORY) != 0'i32
  else:
    var res: TStat
    return stat(dir, res) >= 0'i32 and S_ISDIR(res.st_mode)

proc symlinkExists*(link: string): bool {.rtl, extern: "nos$1",
                                          tags: [FReadDir].} =
  ## Returns true iff the symlink `link` exists. Will return true
  ## regardless of whether the link points to a directory or file.
  when defined(windows):
    var a = getFileAttributes(link)
    if a != -1'i32:
      result = (a and FILE_ATTRIBUTE_REPARSE_POINT) != 0'i32
  else:
    var res: TStat
    return lstat(link, res) >= 0'i32 and S_ISLNK(res.st_mode)

proc fileExists*(filename: string): bool {.inline.} =
  ## Synonym for existsFile
  existsFile(filename)

proc dirExists*(dir: string): bool {.inline.} =
  ## Synonym for existsDir
  existsDir(dir)

proc getLastModificationTime*(file: string): TTime {.rtl, extern: "nos$1".} =
  ## Returns the `file`'s last modification time.
  when defined(posix):
    var res: TStat
    if stat(file, res) < 0'i32: osError(osLastError())
    return res.st_mtime
  else:
    var f: TWIN32_FIND_DATA
    var h = findFirstFile(file, f)
    if h == -1'i32: osError(osLastError())
    result = winTimeToUnixTime(rdFileTime(f.ftLastWriteTime))
    findClose(h)

proc getLastAccessTime*(file: string): TTime {.rtl, extern: "nos$1".} =
  ## Returns the `file`'s last read or write access time.
  when defined(posix):
    var res: TStat
    if stat(file, res) < 0'i32: osError(osLastError())
    return res.st_atime
  else:
    var f: TWIN32_FIND_DATA
    var h = findFirstFile(file, f)
    if h == -1'i32: osError(osLastError())
    result = winTimeToUnixTime(rdFileTime(f.ftLastAccessTime))
    findClose(h)

proc getCreationTime*(file: string): TTime {.rtl, extern: "nos$1".} =
  ## Returns the `file`'s creation time.
  when defined(posix):
    var res: TStat
    if stat(file, res) < 0'i32: osError(osLastError())
    return res.st_ctime
  else:
    var f: TWIN32_FIND_DATA
    var h = findFirstFile(file, f)
    if h == -1'i32: osError(osLastError())
    result = winTimeToUnixTime(rdFileTime(f.ftCreationTime))
    findClose(h)

proc fileNewer*(a, b: string): bool {.rtl, extern: "nos$1".} =
  ## Returns true if the file `a` is newer than file `b`, i.e. if `a`'s
  ## modification time is later than `b`'s.
  result = getLastModificationTime(a) - getLastModificationTime(b) > 0

proc getCurrentDir*(): string {.rtl, extern: "nos$1", tags: [].} =
  ## Returns the `current working directory`:idx:.
  const bufsize = 512 # should be enough
  when defined(windows):
    when useWinUnicode:
      var res = newWideCString("", bufsize)
      var L = getCurrentDirectoryW(bufsize, res)
      if L == 0'i32: osError(osLastError())
      result = res$L
    else:
      result = newString(bufsize)
      var L = getCurrentDirectoryA(bufsize, result)
      if L == 0'i32: osError(osLastError())
      setLen(result, L)
  else:
    result = newString(bufsize)
    if getcwd(result, bufsize) != nil:
      setLen(result, c_strlen(result))
    else:
      osError(osLastError())

proc setCurrentDir*(newDir: string) {.inline, tags: [].} =
  ## Sets the `current working directory`:idx:; `EOS` is raised if
  ## `newDir` cannot been set.
  when defined(Windows):
    if setCurrentDirectory(newDir) == 0'i32:
      osError(osLastError())
  else:
    if chdir(newDir) != 0'i32: osError(osLastError())

proc joinPath*(head, tail: string): string {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Joins two directory names to one.
  ##
  ## For example on Unix:
  ##
  ## .. code-block:: nimrod
  ##   joinPath("usr", "lib")
  ##
  ## results in:
  ##
  ## .. code-block:: nimrod
  ##   "usr/lib"
  ##
  ## If head is the empty string, tail is returned. If tail is the empty
  ## string, head is returned with a trailing path separator. If tail starts
  ## with a path separator it will be removed when concatenated to head. Other
  ## path separators not located on boundaries won't be modified. More
  ## examples on Unix:
  ##
  ## .. code-block:: nimrod
  ##   assert joinPath("usr", "") == "usr/"
  ##   assert joinPath("", "lib") == "lib"
  ##   assert joinPath("", "/lib") == "/lib"
  ##   assert joinPath("usr/", "/lib") == "usr/lib"
  if len(head) == 0:
    result = tail
  elif head[len(head)-1] in {DirSep, AltSep}:
    if tail[0] in {DirSep, AltSep}:
      result = head & substr(tail, 1)
    else:
      result = head & tail
  else:
    if tail[0] in {DirSep, AltSep}:
      result = head & tail
    else:
      result = head & DirSep & tail

proc joinPath*(parts: varargs[string]): string {.noSideEffect,
  rtl, extern: "nos$1OpenArray".} =
  ## The same as `joinPath(head, tail)`, but works with any number of directory
  ## parts. You need to pass at least one element or the proc will assert in
  ## debug builds and crash on release builds.
  result = parts[0]
  for i in 1..high(parts):
    result = joinPath(result, parts[i])

proc `/` * (head, tail: string): string {.noSideEffect.} =
  ## The same as ``joinPath(head, tail)``
  ##
  ## Here are some examples for Unix:
  ##
  ## .. code-block:: nimrod
  ##   assert "usr" / "" == "usr/"
  ##   assert "" / "lib" == "lib"
  ##   assert "" / "/lib" == "/lib"
  ##   assert "usr/" / "/lib" == "usr/lib"
  return joinPath(head, tail)

proc splitPath*(path: string): tuple[head, tail: string] {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Splits a directory into (head, tail), so that
  ## ``joinPath(head, tail) == path``.
  ##
  ## Examples:
  ##
  ## .. code-block:: nimrod
  ##   splitPath("usr/local/bin") -> ("usr/local", "bin")
  ##   splitPath("usr/local/bin/") -> ("usr/local/bin", "")
  ##   splitPath("bin") -> ("", "bin")
  ##   splitPath("/bin") -> ("", "bin")
  ##   splitPath("") -> ("", "")
  var sepPos = -1
  for i in countdown(len(path)-1, 0):
    if path[i] in {DirSep, AltSep}:
      sepPos = i
      break
  if sepPos >= 0:
    result.head = substr(path, 0, sepPos-1)
    result.tail = substr(path, sepPos+1)
  else:
    result.head = ""
    result.tail = path

proc parentDirPos(path: string): int =
  var q = 1
  if path[len(path)-1] in {DirSep, AltSep}: q = 2
  for i in countdown(len(path)-q, 0):
    if path[i] in {DirSep, AltSep}: return i
  result = -1

proc parentDir*(path: string): string {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Returns the parent directory of `path`.
  ##
  ## This is often the same as the ``head`` result of ``splitPath``.
  ## If there is no parent, "" is returned.
  ## | Example: ``parentDir("/usr/local/bin") == "/usr/local"``.
  ## | Example: ``parentDir("/usr/local/bin/") == "/usr/local"``.
  let sepPos = parentDirPos(path)
  if sepPos >= 0:
    result = substr(path, 0, sepPos-1)
  else:
    result = ""

proc isRootDir*(path: string): bool {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Checks whether a given `path` is a root directory
  result = parentDirPos(path) < 0

iterator parentDirs*(path: string, fromRoot=false, inclusive=true): string =
  ## Walks over all parent directories of a given `path`
  ##
  ## If `fromRoot` is set, the traversal will start from the file system root
  ## diretory. If `inclusive` is set, the original argument will be included
  ## in the traversal.
  ##
  ## Relative paths won't be expanded by this proc. Instead, it will traverse
  ## only the directories appearing in the relative path.
  if not fromRoot:
    var current = path
    if inclusive: yield path
    while true:
      if current.isRootDir: break
      current = current.parentDir
      yield current
  else:
    for i in countup(0, path.len - 2): # ignore the last /
      # deal with non-normalized paths such as /foo//bar//baz
      if path[i] in {DirSep, AltSep} and
          (i == 0 or path[i-1] notin {DirSep, AltSep}):
        yield path.substr(0, i)

    if inclusive: yield path

proc `/../` * (head, tail: string): string {.noSideEffect.} =
  ## The same as ``parentDir(head) / tail`` unless there is no parent directory.
  ## Then ``head / tail`` is performed instead.
  let sepPos = parentDirPos(head)
  if sepPos >= 0:
    result = substr(head, 0, sepPos-1) / tail
  else:
    result = head / tail

proc normExt(ext: string): string =
  if ext == "" or ext[0] == ExtSep: result = ext # no copy needed here
  else: result = ExtSep & ext

proc searchExtPos(s: string): int =
  # BUGFIX: do not search until 0! .DS_Store is no file extension!
  result = -1
  for i in countdown(len(s)-1, 1):
    if s[i] == ExtSep:
      result = i
      break
    elif s[i] in {DirSep, AltSep}:
      break # do not skip over path

proc splitFile*(path: string): tuple[dir, name, ext: string] {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Splits a filename into (dir, filename, extension).
  ## `dir` does not end in `DirSep`.
  ## `extension` includes the leading dot.
  ##
  ## Example:
  ##
  ## .. code-block:: nimrod
  ##   var (dir, name, ext) = splitFile("usr/local/nimrodc.html")
  ##   assert dir == "usr/local"
  ##   assert name == "nimrodc"
  ##   assert ext == ".html"
  ##
  ## If `path` has no extension, `ext` is the empty string.
  ## If `path` has no directory component, `dir` is the empty string.
  ## If `path` has no filename component, `name` and `ext` are empty strings.
  if path.len == 0 or path[path.len-1] in {DirSep, AltSep}:
    result = (path, "", "")
  else:
    var sepPos = -1
    var dotPos = path.len
    for i in countdown(len(path)-1, 0):
      if path[i] == ExtSep:
        if dotPos == path.len and i > 0 and
            path[i-1] notin {DirSep, AltSep}: dotPos = i
      elif path[i] in {DirSep, AltSep}:
        sepPos = i
        break
    result.dir = substr(path, 0, sepPos-1)
    result.name = substr(path, sepPos+1, dotPos-1)
    result.ext = substr(path, dotPos)

proc extractFilename*(path: string): string {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Extracts the filename of a given `path`. This is the same as
  ## ``name & ext`` from ``splitFile(path)``.
  if path.len == 0 or path[path.len-1] in {DirSep, AltSep}:
    result = ""
  else:
    result = splitPath(path).tail

proc expandFilename*(filename: string): string {.rtl, extern: "nos$1",
  tags: [FReadDir].} =
  ## Returns the full path of `filename`, raises EOS in case of an error.
  when defined(windows):
    const bufsize = 3072'i32
    when useWinUnicode:
      var unused: WideCString
      var res = newWideCString("", bufsize div 2)
      var L = getFullPathNameW(newWideCString(filename), bufsize, res, unused)
      if L <= 0'i32 or L >= bufsize:
        osError(osLastError())
      result = res$L
    else:
      var unused: cstring
      result = newString(bufsize)
      var L = getFullPathNameA(filename, bufsize, result, unused)
      if L <= 0'i32 or L >= bufsize: osError(osLastError())
      setLen(result, L)
  else:
    # careful, realpath needs to take an allocated buffer according to Posix:
    result = newString(pathMax)
    var r = realpath(filename, result)
    if r.isNil: osError(osLastError())
    setLen(result, c_strlen(result))

proc changeFileExt*(filename, ext: string): string {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Changes the file extension to `ext`.
  ##
  ## If the `filename` has no extension, `ext` will be added.
  ## If `ext` == "" then any extension is removed.
  ## `Ext` should be given without the leading '.', because some
  ## filesystems may use a different character. (Although I know
  ## of none such beast.)
  var extPos = searchExtPos(filename)
  if extPos < 0: result = filename & normExt(ext)
  else: result = substr(filename, 0, extPos-1) & normExt(ext)

proc addFileExt*(filename, ext: string): string {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Adds the file extension `ext` to `filename`, unless
  ## `filename` already has an extension.
  ##
  ## `Ext` should be given without the leading '.', because some
  ## filesystems may use a different character.
  ## (Although I know of none such beast.)
  var extPos = searchExtPos(filename)
  if extPos < 0: result = filename & normExt(ext)
  else: result = filename

proc cmpPaths*(pathA, pathB: string): int {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Compares two paths.
  ##
  ## On a case-sensitive filesystem this is done
  ## case-sensitively otherwise case-insensitively. Returns:
  ##
  ## | 0 iff pathA == pathB
  ## | < 0 iff pathA < pathB
  ## | > 0 iff pathA > pathB
  if FileSystemCaseSensitive:
    result = cmp(pathA, pathB)
  else:
    result = cmpIgnoreCase(pathA, pathB)

proc isAbsolute*(path: string): bool {.rtl, noSideEffect, extern: "nos$1".} =
  ## Checks whether a given `path` is absolute.
  ##
  ## On Windows, network paths are considered absolute too.
  when doslike:
    var len = len(path)
    result = (len > 1 and path[0] in {'/', '\\'}) or
             (len > 2 and path[0] in Letters and path[1] == ':')
  elif defined(macos):
    result = path.len > 0 and path[0] != ':'
  elif defined(RISCOS):
    result = path[0] == '$'
  elif defined(posix):
    result = path[0] == '/'

proc sameFile*(path1, path2: string): bool {.rtl, extern: "nos$1",
  tags: [FReadDir].} =
  ## Returns True if both pathname arguments refer to the same physical
  ## file or directory. Raises an exception if any of the files does not
  ## exist or information about it can not be obtained.
  ##
  ## This proc will return true if given two alternative hard-linked or
  ## sym-linked paths to the same file or directory.
  when defined(Windows):
    var success = true

    template openHandle(path: expr): expr =
      createFile(path, 0'i32, FILE_SHARE_DELETE or FILE_SHARE_READ or
        FILE_SHARE_WRITE, nil, OPEN_EXISTING,
        FILE_FLAG_BACKUP_SEMANTICS or FILE_ATTRIBUTE_NORMAL, 0)
    var f1 = openHandle(path1)
    var f2 = openHandle(path2)

    var lastErr: TOSErrorCode
    if f1 != INVALID_HANDLE_VALUE and f2 != INVALID_HANDLE_VALUE:
      var fi1, fi2: TBY_HANDLE_FILE_INFORMATION

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

    if not success: osError(lastErr)
  else:
    var a, b: TStat
    if stat(path1, a) < 0'i32 or stat(path2, b) < 0'i32:
      osError(osLastError())
    else:
      result = a.st_dev == b.st_dev and a.st_ino == b.st_ino

proc sameFileContent*(path1, path2: string): bool {.rtl, extern: "nos$1",
  tags: [FReadIO].} =
  ## Returns True if both pathname arguments refer to files with identical
  ## binary content.
  const
    bufSize = 8192 # 8K buffer
  var
    a, b: TFile
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
  TFilePermission* = enum  ## file access permission; modelled after UNIX
    fpUserExec,            ## execute access for the file owner
    fpUserWrite,           ## write access for the file owner
    fpUserRead,            ## read access for the file owner
    fpGroupExec,           ## execute access for the group
    fpGroupWrite,          ## write access for the group
    fpGroupRead,           ## read access for the group
    fpOthersExec,          ## execute access for others
    fpOthersWrite,         ## write access for others
    fpOthersRead           ## read access for others

proc getFilePermissions*(filename: string): set[TFilePermission] {.
  rtl, extern: "nos$1", tags: [FReadDir].} =
  ## retrieves file permissions for `filename`. `OSError` is raised in case of
  ## an error. On Windows, only the ``readonly`` flag is checked, every other
  ## permission is available in any case.
  when defined(posix):
    var a: TStat
    if stat(filename, a) < 0'i32: osError(osLastError())
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
    var res = getFileAttributes(filename)
    if res == -1'i32: osError(osLastError())
    if (res and FILE_ATTRIBUTE_READONLY) != 0'i32:
      result = {fpUserExec, fpUserRead, fpGroupExec, fpGroupRead, 
                fpOthersExec, fpOthersRead}
    else:
      result = {fpUserExec..fpOthersRead}
  
proc setFilePermissions*(filename: string, permissions: set[TFilePermission]) {.
  rtl, extern: "nos$1", tags: [FWriteDir].} =
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
    
    if chmod(filename, p) != 0: osError(osLastError())
  else:
    var res = getFileAttributes(filename)
    if res == -1'i32: osError(osLastError())
    if fpUserWrite in permissions: 
      res = res and not FILE_ATTRIBUTE_READONLY
    else:
      res = res or FILE_ATTRIBUTE_READONLY
    var res2 = setFileAttributes(filename, res)
    if res2 == - 1'i32: osError(osLastError())

proc copyFile*(source, dest: string) {.rtl, extern: "nos$1",
  tags: [FReadIO, FWriteIO].} =
  ## Copies a file from `source` to `dest`.
  ##
  ## If this fails, `EOS` is raised. On the Windows platform this proc will
  ## copy the source file's attributes into dest. On other platforms you need
  ## to use getFilePermissions and setFilePermissions to copy them by hand (or
  ## use the convenience copyFileWithPermissions() proc), otherwise `dest` will
  ## inherit the default permissions of a newly created file for the user. If
  ## `dest` already exists, the file attributes will be preserved and the
  ## content overwritten.
  when defined(Windows):
    if copyFile(source, dest, 0'i32) == 0'i32: osError(osLastError())
  else:
    # generic version of copyFile which works for any platform:
    const bufSize = 8000 # better for memory manager
    var d, s: TFile
    if not open(s, source): osError(osLastError())
    if not open(d, dest, fmWrite):
      close(s)
      osError(osLastError())
    var buf = alloc(bufSize)
    while true:
      var bytesread = readBuffer(s, buf, bufSize)
      if bytesread > 0:
        var byteswritten = writeBuffer(d, buf, bytesread)
        if bytesread != byteswritten:
          dealloc(buf)
          close(s)
          close(d)
          osError(osLastError())
      if bytesread != bufSize: break
    dealloc(buf)
    close(s)
    close(d)

proc moveFile*(source, dest: string) {.rtl, extern: "nos$1",
  tags: [FReadIO, FWriteIO].} =
  ## Moves a file from `source` to `dest`. If this fails, `EOS` is raised.
  if c_rename(source, dest) != 0'i32:
    raise newException(EOS, $strerror(errno))

when not defined(ENOENT) and not defined(Windows):
  when NoFakeVars:
    const ENOENT = cint(2) # 2 on most systems including Solaris
  else:
    var ENOENT {.importc, header: "<errno.h>".}: cint

proc removeFile*(file: string) {.rtl, extern: "nos$1", tags: [FWriteDir].} =
  ## Removes the `file`. If this fails, `EOS` is raised. This does not fail
  ## if the file never existed in the first place.
  ## On Windows, ignores the read-only attribute.
  when defined(Windows):
    if deleteFile(file) == 0:
      if getLastError() == ERROR_ACCESS_DENIED: 
        if setFileAttributes(file, FILE_ATTRIBUTE_NORMAL) == 0:
          osError(osLastError())
        if deleteFile(file) == 0:
          osError(osLastError())
  else:
    if c_remove(file) != 0'i32 and errno != ENOENT:
      raise newException(EOS, $strerror(errno))

proc execShellCmd*(command: string): int {.rtl, extern: "nos$1",
  tags: [FExecIO].} =
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
        if e == nil: return # an error occured
        while true:
          var eend = strEnd(e)
          add(environment, $e)
          e = cast[WideCString](cast[TAddress](eend)+2)
          if eend[1].int == 0: break
        discard freeEnvironmentStringsW(env)
      else:
        var
          env = getEnvironmentStringsA()
          e = env
        if e == nil: return # an error occured
        while true:
          var eend = strEnd(e)
          add(environment, $e)
          e = cast[cstring](cast[TAddress](eend)+1)
          if eend[1] == '\0': break
        discard freeEnvironmentStringsA(env)
      envComputed = true

else:
  const
    useNSGetEnviron = defined(macosx) and
      (defined(createNimRtl) or defined(useNimRtl))
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

proc getEnv*(key: string): TaintedString {.tags: [FReadEnv].} =
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

proc existsEnv*(key: string): bool {.tags: [FReadEnv].} =
  ## Checks whether the environment variable named `key` exists.
  ## Returns true if it exists, false otherwise.
  if c_getenv(key) != nil: return true
  else: return findEnvVar(key) >= 0

proc putEnv*(key, val: string) {.tags: [FWriteEnv].} =
  ## Sets the value of the `environment variable`:idx: named `key` to `val`.
  ## If an error occurs, `EInvalidEnvVar` is raised.

  # Note: by storing the string in the environment sequence,
  # we gurantee that we don't free the memory before the program
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
      osError(osLastError())
  else:
    if setEnvironmentVariable(key, val) == 0'i32: osError(osLastError())

iterator envPairs*(): tuple[key, value: TaintedString] {.tags: [FReadEnv].} =
  ## Iterate over all `environments variables`:idx:. In the first component
  ## of the tuple is the name of the current variable stored, in the second
  ## its value.
  getEnvVarsC()
  for i in 0..high(environment):
    var p = find(environment[i], '=')
    yield (TaintedString(substr(environment[i], 0, p-1)),
           TaintedString(substr(environment[i], p+1)))

iterator walkFiles*(pattern: string): string {.tags: [FReadDir].} =
  ## Iterate over all the files that match the `pattern`. On POSIX this uses
  ## the `glob`:idx: call.
  ##
  ## `pattern` is OS dependent, but at least the "\*.ext"
  ## notation is supported.
  when defined(windows):
    var
      f: TWIN32_FIND_DATA
      res: int
    res = findFirstFile(pattern, f)
    if res != -1:
      while true:
        if not skipFindData(f):
          yield splitFile(pattern).dir / extractFilename(getFilename(f))
        if findNextFile(res, f) == 0'i32: break
      findClose(res)
  else: # here we use glob
    var
      f: TGlob
      res: int
    f.gl_offs = 0
    f.gl_pathc = 0
    f.gl_pathv = nil
    res = glob(pattern, 0, nil, addr(f))
    if res == 0:
      for i in 0.. f.gl_pathc - 1:
        assert(f.gl_pathv[i] != nil)
        yield $f.gl_pathv[i]
    globfree(addr(f))

type
  TPathComponent* = enum  ## Enumeration specifying a path component.
    pcFile,               ## path refers to a file
    pcLinkToFile,         ## path refers to a symbolic link to a file
    pcDir,                ## path refers to a directory
    pcLinkToDir           ## path refers to a symbolic link to a directory

iterator walkDir*(dir: string): tuple[kind: TPathComponent, path: string] {.
  tags: [FReadDir].} =
  ## walks over the directory `dir` and yields for each directory or file in
  ## `dir`. The component type and full path for each item is returned.
  ## Walking is not recursive.
  ## Example: This directory structure::
  ##   dirA / dirB / fileB1.txt
  ##        / dirC
  ##        / fileA1.txt
  ##        / fileA2.txt
  ##
  ## and this code:
  ##
  ## .. code-block:: Nimrod
  ##     for kind, path in walkDir("dirA"):
  ##       echo(path)
  ##
  ## produces this output (but not necessarily in this order!)::
  ##   dirA/dirB
  ##   dirA/dirC
  ##   dirA/fileA1.txt
  ##   dirA/fileA2.txt
  when defined(windows):
    var f: TWIN32_FIND_DATA
    var h = findFirstFile(dir / "*", f)
    if h != -1:
      while true:
        var k = pcFile
        if not skipFindData(f):
          if (f.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) != 0'i32:
            k = pcDir
          if (f.dwFileAttributes and FILE_ATTRIBUTE_REPARSE_POINT) != 0'i32:
            k = succ(k)
          yield (k, dir / extractFilename(getFilename(f)))
        if findNextFile(h, f) == 0'i32: break
      findClose(h)
  else:
    var d = opendir(dir)
    if d != nil:
      while true:
        var x = readdir(d)
        if x == nil: break
        var y = $x.d_name
        if y != "." and y != "..":
          var s: TStat
          y = dir / y
          if lstat(y, s) < 0'i32: break
          var k = pcFile
          if S_ISDIR(s.st_mode): k = pcDir
          if S_ISLNK(s.st_mode): k = succ(k)
          yield (k, y)
      discard closedir(d)

iterator walkDirRec*(dir: string, filter={pcFile, pcDir}): string {.
  tags: [FReadDir].} =
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
    var res = removeDirectory(dir)
    let lastError = osLastError()
    if res == 0'i32 and lastError.int32 != 3'i32 and
        lastError.int32 != 18'i32 and lastError.int32 != 2'i32:
      osError(lastError)
  else:
    if rmdir(dir) != 0'i32 and errno != ENOENT: osError(osLastError())

proc removeDir*(dir: string) {.rtl, extern: "nos$1", tags: [
  FWriteDir, FReadDir].} =
  ## Removes the directory `dir` including all subdirectories and files
  ## in `dir` (recursively).
  ##
  ## If this fails, `EOS` is raised. This does not fail if the directory never
  ## existed in the first place.
  for kind, path in walkDir(dir):
    case kind
    of pcFile, pcLinkToFile, pcLinkToDir: removeFile(path)
    of pcDir: removeDir(path)
  rawRemoveDir(dir)

proc rawCreateDir(dir: string) =
  when defined(solaris):
    if mkdir(dir, 0o711) != 0'i32 and errno != EEXIST and errno != ENOSYS:
      osError(osLastError())
  elif defined(unix):
    if mkdir(dir, 0o711) != 0'i32 and errno != EEXIST:
      osError(osLastError())
  else:
    var res = createDirectory(dir)
    if res == 0'i32 and getLastError() != 183'i32:
      osError(osLastError())

proc createDir*(dir: string) {.rtl, extern: "nos$1", tags: [FWriteDir].} =
  ## Creates the `directory`:idx: `dir`.
  ##
  ## The directory may contain several subdirectories that do not exist yet.
  ## The full path is created. If this fails, `EOS` is raised. It does **not**
  ## fail if the path already exists because for most usages this does not
  ## indicate an error.
  var omitNext = false
  when defined(doslike):
    omitNext = isAbsolute(dir)
  for i in 1.. dir.len-1:
    if dir[i] in {DirSep, AltSep}:
      if omitNext:
        omitNext = false
      else:
        rawCreateDir(substr(dir, 0, i-1))
  rawCreateDir(dir)

proc copyDir*(source, dest: string) {.rtl, extern: "nos$1",
  tags: [FWriteIO, FReadIO].} =
  ## Copies a directory from `source` to `dest`. If this fails, `EOS` is raised.
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
  ## by `src`. On most operating systems, will fail if a lonk
  ##
  ## **Warning**:
  ## Some OS's (such as Microsoft Windows) restrict the creation 
  ## of symlinks to root users (administrators).
  when defined(Windows):
    let flag = dirExists(src).int32
    if createSymbolicLink(dest, src, flag) == 0 or getLastError() != 0:
      osError(osLastError())
  else:
    if symlink(src, dest) != 0:
      osError(osLastError())

proc createHardlink*(src, dest: string) =
  ## Create a hard link at `dest` which points to the item specified
  ## by `src`.
  ##
  ## **Warning**: Most OS's restrict the creation of hard links to 
  ## root users (administrators) .
  when defined(Windows):
    if createHardLink(dest, src, nil) == 0:
      osError(osLastError())
  else:
    if link(src, dest) != 0:
      osError(osLastError())

proc parseCmdLine*(c: string): seq[string] {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Splits a command line into several components;
  ## This proc is only occassionally useful, better use the `parseopt` module.
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
    while c[i] == ' ' or c[i] == '\t': inc(i)
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
  ## This is a wrapper proc around copyFile, getFilePermissions and
  ## setFilePermissions on non Windows platform. On windows this proc is just a
  ## wrapper for copyFile since that proc already copies attributes.
  ##
  ## On non windows systems permissions are copied after the file itself has
  ## been copied, which won't happen atomically and could lead to a race
  ## condition. If ignorePermissionErrors is true, errors while reading/setting
  ## file attributes will be ignored, otherwise will raise `OSError`.
  copyFile(source, dest)
  when not defined(Windows):
    try:
      setFilePermissions(dest, getFilePermissions(source))
    except:
      if not ignorePermissionErrors:
        raise

proc inclFilePermissions*(filename: string,
                          permissions: set[TFilePermission]) {.
  rtl, extern: "nos$1", tags: [FReadDir, FWriteDir].} =
  ## a convenience procedure for:
  ##
  ## .. code-block:: nimrod
  ##   setFilePermissions(filename, getFilePermissions(filename)+permissions)
  setFilePermissions(filename, getFilePermissions(filename)+permissions)

proc exclFilePermissions*(filename: string,
                          permissions: set[TFilePermission]) {.
  rtl, extern: "nos$1", tags: [FReadDir, FWriteDir].} =
  ## a convenience procedure for:
  ##
  ## .. code-block:: nimrod
  ##   setFilePermissions(filename, getFilePermissions(filename)-permissions)
  setFilePermissions(filename, getFilePermissions(filename)-permissions)

proc getHomeDir*(): string {.rtl, extern: "nos$1", tags: [FReadEnv].} =
  ## Returns the home directory of the current user.
  ##
  ## This proc is wrapped by the expandTilde proc for the convenience of
  ## processing paths coming from user configuration files.
  when defined(windows): return string(getEnv("USERPROFILE")) & "\\"
  else: return string(getEnv("HOME")) & "/"

proc getConfigDir*(): string {.rtl, extern: "nos$1", tags: [FReadEnv].} =
  ## Returns the config directory of the current user for applications.
  when defined(windows): return string(getEnv("APPDATA")) & "\\"
  else: return string(getEnv("HOME")) & "/.config/"

proc getTempDir*(): string {.rtl, extern: "nos$1", tags: [FReadEnv].} =
  ## Returns the temporary directory of the current user for applications to
  ## save temporary files in.
  when defined(windows): return string(getEnv("TEMP")) & "\\"
  else: return "/tmp/"

when defined(windows):
  # Since we support GUI applications with Nimrod, we sometimes generate
  # a WinMain entry proc. But a WinMain proc has no access to the parsed
  # command line arguments. The way to get them differs. Thus we parse them
  # ourselves. This has the additional benefit that the program's behaviour
  # is always the same -- independent of the used C compiler.
  var
    ownArgv: seq[string]

  proc paramCount*(): int {.rtl, extern: "nos$1", tags: [FReadIO].} =
    ## Returns the number of `command line arguments`:idx: given to the
    ## application.
    if isNil(ownArgv): ownArgv = parseCmdLine($getCommandLine())
    result = ownArgv.len-1

  proc paramStr*(i: int): TaintedString {.rtl, extern: "nos$1",
    tags: [FReadIO].} =
    ## Returns the `i`-th `command line argument`:idx: given to the
    ## application.
    ##
    ## `i` should be in the range `1..paramCount()`, else
    ## the `EOutOfIndex` exception is raised.
    if isNil(ownArgv): ownArgv = parseCmdLine($getCommandLine())
    return TaintedString(ownArgv[i])

elif not defined(createNimRtl):
  # On Posix, there is no portable way to get the command line from a DLL.
  var
    cmdCount {.importc: "cmdCount".}: cint
    cmdLine {.importc: "cmdLine".}: cstringArray

  proc paramStr*(i: int): TaintedString {.tags: [FReadIO].} =
    if i < cmdCount and i >= 0: return TaintedString($cmdLine[i])
    raise newException(EInvalidIndex, "invalid index")

  proc paramCount*(): int {.tags: [FReadIO].} = return cmdCount-1

when defined(paramCount):
  proc commandLineParams*(): seq[TaintedString] =
    result = @[]
    for i in 1..paramCount():
      result.add(paramStr(i))

when defined(linux) or defined(solaris) or defined(bsd) or defined(aix):
  proc getApplAux(procPath: string): string =
    result = newString(256)
    var len = readlink(procPath, result, 256)
    if len > 256:
      result = newString(len+1)
      len = readlink(procPath, result, len)
    setLen(result, len)

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

proc getAppFilename*(): string {.rtl, extern: "nos$1", tags: [FReadIO].} =
  ## Returns the filename of the application's executable.
  ##
  ## This procedure will resolve symlinks.
  ##
  ## **Note**: This does not work reliably on BSD.

  # Linux: /proc/<pid>/exe
  # Solaris:
  # /proc/<pid>/object/a.out (filename only)
  # /proc/<pid>/path/a.out (complete pathname)
  # *BSD (and maybe Darwin too):
  # /proc/<pid>/file
  when defined(windows):
    when useWinUnicode:
      var buf = cast[WideCString](alloc(256*2))
      var len = getModuleFileNameW(0, buf, 256)
      result = buf$len
    else:
      result = newString(256)
      var len = getModuleFileNameA(0, result, 256)
      setlen(result, int(len))
  elif defined(linux) or defined(aix):
    result = getApplAux("/proc/self/exe")
  elif defined(solaris):
    result = getApplAux("/proc/" & $getpid() & "/path/a.out")
  elif defined(freebsd):
    result = getApplAux("/proc/" & $getpid() & "/file")
  elif defined(macosx):
    var size: cuint32
    getExecPath1(nil, size)
    result = newString(int(size))
    if getExecPath2(result, size):
      result = "" # error!
    if result.len > 0:
      result = result.expandFilename
  else:
    # little heuristic that may work on other POSIX-like systems:
    result = string(getEnv("_"))
    if len(result) == 0:
      result = string(paramStr(0))
      # POSIX guaranties that this contains the executable
      # as it has been executed by the calling process
      if len(result) > 0 and result[0] != DirSep: # not an absolute path?
        # iterate over any path in the $PATH environment variable
        for p in split(string(getEnv("PATH")), {PathSep}):
          var x = joinPath(p, result)
          if existsFile(x): return x

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

proc getAppDir*(): string {.rtl, extern: "nos$1", tags: [FReadIO].} =
  ## Returns the directory of the application's executable.
  ## **Note**: This does not work reliably on BSD.
  result = splitFile(getAppFilename()).dir

proc sleep*(milsecs: int) {.rtl, extern: "nos$1", tags: [FTime].} =
  ## sleeps `milsecs` milliseconds.
  when defined(windows):
    winlean.sleep(int32(milsecs))
  else:
    var a, b: Ttimespec
    a.tv_sec = TTime(milsecs div 1000)
    a.tv_nsec = (milsecs mod 1000) * 1000 * 1000
    discard posix.nanosleep(a, b)

proc getFileSize*(file: string): BiggestInt {.rtl, extern: "nos$1",
  tags: [FReadIO].} =
  ## returns the file size of `file`. Can raise ``EOS``.
  when defined(windows):
    var a: TWIN32_FIND_DATA
    var resA = findFirstFile(file, a)
    if resA == -1: osError(osLastError())
    result = rdFileSize(a)
    findClose(resA)
  else:
    var f: TFile
    if open(f, file):
      result = getFileSize(f)
      close(f)
    else: osError(osLastError())

proc findExe*(exe: string): string {.tags: [FReadDir, FReadEnv].} =
  ## Searches for `exe` in the current working directory and then
  ## in directories listed in the ``PATH`` environment variable.
  ## Returns "" if the `exe` cannot be found. On DOS-like platforms, `exe`
  ## is added an ``.exe`` file extension if it has no extension.
  result = addFileExt(exe, os.ExeExt)
  if existsFile(result): return
  var path = string(os.getEnv("PATH"))
  for candidate in split(path, PathSep):
    var x = candidate / result
    if existsFile(x): return x
  result = ""

proc expandTilde*(path: string): string =
  ## Expands a path starting with ``~/`` to a full path.
  ##
  ## If `path` starts with the tilde character and is followed by `/` or `\\`
  ## this proc will return the reminder of the path appended to the result of
  ## the getHomeDir() proc, otherwise the input path will be returned without
  ## modification.
  ##
  ## The behaviour of this proc is the same on the Windows platform despite not
  ## having this convention. Example:
  ##
  ## .. code-block:: nimrod
  ##   let configFile = expandTilde("~" / "appname.cfg")
  ##   echo configFile
  ##   # --> C:\Users\amber\appname.cfg

  if len(path) > 1 and path[0] == '~' and (path[1] == '/' or path[1] == '\\'):
    result = getHomeDir() / path[2..len(path)-1]
  else:
    result = path

{.pop.}
