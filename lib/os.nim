#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2006 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Basic operating system facilities like retrieving environment variables,
## reading command line arguments, working with directories, running shell
## commands, etc. This module is -- like any other basic library --
## platform independant.

{.push debugger:off.}

import
  strutils, times

# copied from excpt.nim, because I don't want to make this template public
template newException(exceptn, message: expr): expr = 
  block: # open a new scope
    var
      e: ref exceptn
    new(e)
    e.msg = message
    e

when defined(windows) or defined(OS2) or defined(DOS):
  {.define: doslike.} # DOS-like filesystem

when defined(Nimdoc): # only for proper documentation:
  const
    CurDir* = '.'
      ## The constant string used by the operating system to refer to the
      ## current directory.
      ##
      ## For example: '.' for POSIX or ':' for the classic Macintosh.

    ParDir* = ".."
      ## The constant string used by the operating system to refer to the parent
      ## directory.
      ##
      ## For example: ".." for POSIX or "::" for the classic Macintosh.

    DirSep* = '/'
      ## The character used by the operating system to separate pathname
      ## components, for example, '/' for POSIX or ':' for the classic
      ## Macintosh.
      ##
      ## Note that knowing this is not sufficient to be able to parse or
      ## concatenate pathnames -- use `splitPath` and `joinPath` instead --
      ## but it is occasionally useful.

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

elif defined(macos):
  const
    curdir* = ':'
    pardir* = "::"
    dirsep* = ':'
    altsep* = dirsep
    pathsep* = ','
    FileSystemCaseSensitive* = false

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
  #  same names could be inserted. This means that paths on MacOS is not
  #  waterproof. In case of equal names the first volume found will do.
  #  Two colons "::" are the relative path to the parent. Three is to the
  #  grandparent etc.
elif defined(doslike):
  const
    curdir* = '.'
    pardir* = ".."
    dirsep* = '\\' # seperator within paths
    altsep* = '/'
    pathSep* = ';' # seperator between paths
    FileSystemCaseSensitive* = false
elif defined(PalmOS) or defined(MorphOS):
  const
    dirsep* = '/'
    altsep* = dirsep
    PathSep* = ';'
    pardir* = ".."
    FileSystemCaseSensitive* = false
elif defined(RISCOS):
  const
    dirsep* = '.'
    altsep* = '.'
    pardir* = ".." # is this correct?
    pathSep* = ','
    FileSystemCaseSensitive* = true
else: # UNIX-like operating system
  const
    curdir* = '.'
    pardir* = ".."
    dirsep* = '/'
    altsep* = dirsep
    pathSep* = ':'
    FileSystemCaseSensitive* = true

const
  ExtSep* = '.'
    ## The character which separates the base filename from the extension;
    ## for example, the '.' in ``os.nim``.

proc getApplicationDir*(): string {.noSideEffect.}
  ## Gets the directory of the application's executable.

proc getApplicationFilename*(): string {.noSideEffect.}
  ## Gets the filename of the application's executable.

proc getCurrentDir*(): string {.noSideEffect.}
  ## Gets the current working directory.

proc setCurrentDir*(newDir: string) {.inline.}
  ## Sets the current working directory; `EOS` is raised if
  ## `newDir` cannot been set.

proc getHomeDir*(): string {.noSideEffect.}
  ## Gets the home directory of the current user.

proc getConfigDir*(): string {.noSideEffect.}
  ## Gets the config directory of the current user for applications.

proc expandFilename*(filename: string): string
  ## Returns the full path of `filename`, "" on error.

proc ExistsFile*(filename: string): bool
  ## Returns true if the file exists, false otherwise.

proc JoinPath*(head, tail: string): string {.noSideEffect.}
  ## Joins two directory names to one.
  ##
  ## For example on Unix::
  ##
  ##   JoinPath("usr", "lib")
  ##
  ## results in::
  ##
  ##   "usr/lib"
  ##
  ## If head is the empty string, tail is returned.
  ## If tail is the empty string, head is returned.

proc `/` * (head, tail: string): string {.noSideEffect.} =
  ## The same as ``joinPath(head, tail)``
  return joinPath(head, tail)

proc JoinPath*(parts: openarray[string]): string {.noSideEffect.}
  ## The same as `JoinPath(head, tail)`, but works with any number
  ## of directory parts.

proc SplitPath*(path: string, head, tail: var string) {.noSideEffect.}
  ## Splits a directory into (head, tail), so that
  ## ``JoinPath(head, tail) == path``.
  ##
  ## Example: After ``SplitPath("usr/local/bin", head, tail)``,
  ## `head` is "usr/local" and `tail` is "bin".
  ## Example: After ``SplitPath("usr/local/bin/", head, tail)``,
  ## `head` is "usr/local/bin" and `tail` is "".

proc parentDir*(path: string): string {.noSideEffect.}
  ## Returns the parent directory of `path`.
  ##
  ## This is often the same as the ``head`` result of ``splitPath``.
  ## If there is no parent, ``path`` is returned.
  ## Example: ``parentDir("/usr/local/bin") == "/usr/local"``.
  ## Example: ``parentDir("/usr/local/bin/") == "/usr/local"``.

proc `/../` * (head, tail: string): string {.noSideEffect.} =
  ## The same as ``parentDir(head) / tail``
  return parentDir(head) / tail

proc UnixToNativePath*(path: string): string {.noSideEffect.}
  ## Converts an UNIX-like path to a native one.
  ##
  ## On an UNIX system this does nothing. Else it converts
  ## '/', '.', '..' to the appropriate things.

proc SplitFilename*(filename: string, name, extension: var string) {.
  noSideEffect.}
  ## Splits a filename into (name, extension), so that
  ## ``name & extension == filename``.
  ##
  ## Example: After ``SplitFilename("usr/local/nimrodc.html", name, ext)``,
  ## `name` is "usr/local/nimrodc" and `ext` is ".html".
  ## It the file has no extension, extention is the empty string.

proc extractDir*(path: string): string {.noSideEffect.}
  ## Extracts the directory of a given path. This is the `head`
  ## result of `splitPath`.

proc extractFilename*(path: string): string {.noSideEffect.}
  ## Extracts the filename of a given `path`. This the the `tail`
  ## result of `splitPath`.
  # XXX: this is not true: /usr/lib/ --> filename should be empty!

proc cmpPaths*(pathA, pathB: string): int {.noSideEffect.}
  ## Compares two paths.
  ##
  ## On a case-sensitive filesystem this is done
  ## case-sensitively otherwise case-insensitively. Returns:
  ##
  ## | 0 iff pathA == pathB
  ## | < 0 iff pathA < pathB
  ## | > 0 iff pathA > pathB

proc AppendFileExt*(filename, ext: string): string {.noSideEffect.}
  ## Appends the file extension `ext` to the `filename`, even if
  ## the `filename` already has an extension.
  ##
  ## `Ext` should be given without the leading '.', because some
  ## filesystems may use a different character.
  ## (Although I know of none such beast.)

proc ChangeFileExt*(filename, ext: string): string {.noSideEffect.}
  ## Changes the file extension to `ext`.
  ##
  ## If the `filename` has no extension, `ext` will be added.
  ## If `ext` == "" then the filename will get no extension.
  ## `Ext` should be given without the leading '.', because some
  ## filesystems may use a different character. (Although I know
  ## of none such beast.)

# procs dealing with processes:
proc executeProcess*(command: string): int
  ## Executes a process.
  ##
  ## Command has the form 'program args' where args are the command
  ## line arguments given to program. The proc returns the error code
  ## of the process when it has finished. The proc does not return
  ## until the process has finished.

proc executeShellCommand*(command: string): int
  ## Executes a shell command.
  ##
  ## The syntax of the command is unspecified and depends on the used
  ## shell. The proc returns the error code of the shell when it has finished.

# procs operating on a high level for files:
proc copyFile*(dest, source: string)
  ## Copies a file from `dest` to `source`. If this fails,
  ## `EOS` is raised.

proc moveFile*(dest, source: string)
  ## Moves a file from `dest` to `source`. If this fails, `EOS` is raised.

proc removeFile*(file: string)
  ## Removes the `file`. If this fails, `EOS` is raised.

proc removeDir*(dir: string)
  ## Removes the directory `dir` including all subdirectories or files
  ## in `dir` (recursively). If this fails, `EOS` is raised.

proc createDir*(dir: string)
  ## Creates the directory `dir`.
  ##
  ## The directory may contain several
  ## subdirectories that do not exist yet. The full path is created. If this
  ## fails, `EOS` is raised. It does NOT fail if the path already exists
  ## because for most usages this does not indicate an error.

proc existsDir*(dir: string): bool
  ## Returns true iff the directory `dir` exists. If `dir` is a file, false
  ## is returned.

proc getLastModificationTime*(file: string): TTime
  ## Gets the time of the `file`'s last modification.

# procs dealing with environment variables:
proc putEnv*(key, val: string)
  ## Sets the value of the environment variable named `key` to `val`.
  ## If an error occurs, `EInvalidEnvVar` is raised.

proc getEnv*(key: string): string
  ## Gets the value of the environment variable named `key`.
  ##
  ## If the variable does not exist, "" is returned. To distinguish
  ## whether a variable exists or it's value is just "", call
  ## `existsEnv(key)`.

proc existsEnv*(key: string): bool
  ## Checks whether the environment variable named `key` exists.
  ## Returns true if it exists, false otherwise.

# procs dealing with command line arguments:
proc paramCount*(): int
  ## Returns the number of command line arguments given to the
  ## application.

proc paramStr*(i: int): string
  ## Returns the `i`-th command line arguments given to the
  ## application.
  ##
  ## `i` should be in the range `1..paramCount()`, else
  ## the `EOutOfIndex` exception is raised.

# implementation

proc UnixToNativePath(path: string): string =
  when defined(unix):
    result = path
  else:
    var start: int
    if path[0] == '/':
      # an absolute path
      when defined(doslike):
        result = r"C:\"
      elif defined(macos):
        result = "" # must not start with ':'
      else:
        result = $dirSep
      start = 1
    elif path[0] == '.' and path[1] == '/':
      # current directory
      result = $curdir
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
            add result, pardir
        else:
          add result, pardir & dirSep
        inc(i, 3)
      elif path[i] == '/':
        add result, dirSep
        inc(i)
      else:
        add result, $path[i]
        inc(i)

# interface to C library:

type
  TStat {.importc: "struct stat".} = record
    st_dev: int16
    st_ino: int16
    st_mode: int16
    st_nlink: int16
    st_uid: int16
    st_gid: int16
    st_rdev: int32
    st_size: int32
    st_atime: TTime
    st_mtime: TTime
    st_ctime: TTime

var
  errno {.importc: "errno", header: "<errno.h>".}: cint
  EEXIST {.importc: "EEXIST", header: "<errno.h>".}: cint

when defined(unix):
  const dirHeader = "<sys/stat.h>"
elif defined(windows):
  const dirHeader = "<direct.h>"
else:
  {.error: "os library not ported to your OS. Please help!".}


proc chdir(path: CString): cint {.importc: "chdir", header: dirHeader.}

when defined(unix):
  proc mkdir(dir: CString, theAccess: cint): cint {.
    importc: "mkdir", header: dirHeader.}
  proc realpath(name, resolved: CString): CString {.
    importc: "realpath", header: "<stdlib.h>".}
  proc getcwd(buf: CString, buflen: cint): CString {.
    importc: "getcwd", header: "<unistd.h>".}
elif defined(windows):
  proc mkdir(dir: CString): cint {.
    importc: "mkdir", header: dirHeader.}
  proc fullpath(buffer, file: CString, size: int): CString {.
    importc: "_fullpath", header: "<stdlib.h>".}
  proc getcwd(buf: CString, buflen: cint): CString {.
    importc: "getcwd", header: "<direct.h>".}

  proc CreateDirectory(pathName: cstring, security: Pointer): cint {.
    importc: "CreateDirectory", header: "<windows.h>".}
  proc GetLastError(): cint {.importc, header: "<windows.h>".}
else:
  {.error: "os library not ported to your OS. Please help!".}


proc rmdir(dir: CString): cint {.importc: "rmdir", header: "<time.h>".}
  # rmdir is of course in ``dirHeader``, but we check here to include
  # time.h which is needed for stat(). stat() needs time.h and
  # sys/stat.h; we workaround a C library issue here.

proc free(c: cstring) {.importc: "free", nodecl.}
  # some C procs return a buffer that has to be freed with free(),
  # so we define it here
proc strlen(str: CString): int {.importc: "strlen", nodecl.}

proc stat(f: CString, res: var TStat): cint {.
  importc: "stat", header: "<sys/stat.h>".}

proc sameFile*(path1, path2: string): bool =
  ## Returns True if both pathname arguments refer to the same file or
  ## directory (as indicated by device number and i-node number).
  ## Raises an exception if an os.stat() call on either pathname fails.
  var
    a, b: TStat
  if stat(path1, a) < 0 or stat(path2, b) < 0:
    raise newException(EOS, "stat() call failed")
  return int(a.st_dev) == b.st_dev and int(a.st_ino) == b.st_ino

when defined(windows):
  proc getModuleFilename(handle: int32, buf: CString, size: int32): int32 {.
    importc: "GetModuleFileName", header: "<windows.h>".}

proc getLastModificationTime(file: string): TTime =
  var
    res: TStat
  discard stat(file, res)
  return res.st_mtime

proc setCurrentDir(newDir: string) =
  if chdir(newDir) != 0:
    raise newException(EOS, "cannot change the working directory to '$1'" % 
      newDir)

when defined(linux) or defined(solaris) or defined(bsd):
  proc readlink(link, buf: cstring, size: int): int {.
    header: "<unistd.h>", cdecl.}
  
  proc getApplAux(procPath: string): string =
    result = newString(256)
    var len = readlink(procPath, result, 256)
    if len > 256:
      result = newString(len+1)
      len = readlink(procPath, result, len)
    setlen(result, len)

when defined(solaris) or defined(bsd):
  proc getpid(): int {.importc, header: "<unistd.h>", cdecl.}

proc getApplicationFilename(): string =
  # Linux: /proc/<pid>/exe
  # Solaris:
  # /proc/<pid>/object/a.out (filename only)
  # /proc/<pid>/path/a.out (complete pathname)
  # *BSD (and maybe Darwing too):
  # /proc/<pid>/file
  when defined(windows):
    result = newString(256)
    var len = getModuleFileName(0, result, 256)
    setlen(result, int(len))
  elif defined(linux):
    result = getApplAux("/proc/self/exe")
  elif defined(solaris):
    result = getApplAux("/proc/" & $getpid() & "/path/a.out")
  elif defined(bsd):
    result = getApplAux("/proc/" & $getpid() & "file")
  else:
    # little heuristic that may work on other POSIX-like systems:
    result = getEnv("_")
    if len(result) == 0:
      result = ParamStr(0) # POSIX guaranties that this contains the executable
                           # as it has been executed by the calling process
      if len(result) > 0 and result[0] != DirSep: # not an absolute path?
        # iterate over any path in the $PATH environment variable
        for p in split(getEnv("PATH"), {PathSep}):
          var x = joinPath(p, result)
          if ExistsFile(x): return x

{.push warnings: off.}
proc getApplicationDir(): string =
  var tail: string
  splitPath(getApplicationFilename(), result, tail)
{.pop.}

proc getCurrentDir(): string =
  const
    bufsize = 512 # should be enough
  result = newString(bufsize)
  if getcwd(result, bufsize) != nil:
    setlen(result, strlen(result))
  else:
    raise newException(EOS, "getcwd failed")

proc JoinPath(head, tail: string): string =
  if len(head) == 0:
    result = tail
  elif head[len(head)-1] in {DirSep, AltSep}:
    if tail[0] in {DirSep, AltSep}:
      result = head & copy(tail, 1)
    else:
      result = head & tail
  else:
    if tail[0] in {DirSep, AltSep}:
      result = head & tail
    else:
      result = head & DirSep & tail

proc JoinPath(parts: openarray[string]): string =
  result = parts[0]
  for i in 1..high(parts):
    result = JoinPath(result, parts[i])

proc parentDir(path: string): string =
  var
    sepPos = -1
    q = 1
  if path[len(path)-1] in {dirsep, altsep}:
    q = 2
  for i in countdown(len(path)-q, 0):
    if path[i] in {dirsep, altsep}:
      sepPos = i
      break
  if sepPos >= 0:
    result = copy(path, 0, sepPos-1)
  else:
    result = path

proc SplitPath(path: string, head, tail: var string) =
  var
    sepPos = -1
  for i in countdown(len(path)-1, 0):
    if path[i] in {dirsep, altsep}:
      sepPos = i
      break
  if sepPos >= 0:
    head = copy(path, 0, sepPos-1)
    tail = copy(path, sepPos+1)
  else:
    head = ""
    tail = path # make a string copy here

# helper:
proc searchExtPos(s: string): int =
  result = -1
  for i in countdown(len(s)-1, 0):
    if s[i] == extsep:
      result = i
      break
    elif s[i] in {dirsep, altsep}:
      break # do not skip over path

proc SplitFilename(filename: string, name, extension: var string) =
  var
    extPos = searchExtPos(filename)
  if extPos >= 0:
    name = copy(filename, 0, extPos-1)
    extension = copy(filename, extPos)
  else:
    name = filename # make a string copy here
    extension = ""

proc normExt(ext: string): string =
  if ext == "" or ext[0] == extSep: result = ext # no copy needed here
  else: result = extSep & ext

proc ChangeFileExt(filename, ext: string): string =
  var
    extPos = searchExtPos(filename)
  if extPos < 0: result = filename & normExt(ext)
  else: result = copy(filename, 0, extPos-1) & normExt(ext)

proc AppendFileExt(filename, ext: string): string =
  var
    extPos = searchExtPos(filename)
  if extPos < 0: result = filename & normExt(ext)
  else: result = filename #make a string copy here

# some more C things:

proc csystem(cmd: CString): cint {.importc: "system", noDecl.}
  # is in <stdlib.h>!

when defined(wcc):
  # everywhere it is in <stdlib.h>, except for Watcom C ...
  proc cputenv(env: CString): cint {.importc: "putenv", header: "<process.h>".}

else: # is in <stdlib.h>
  proc cputenv(env: CString): cint {.importc: "putenv", noDecl.} 

proc cgetenv(env: CString): CString {.importc: "getenv", noDecl.}

#long  _findfirst(char *, struct _finddata_t *);
#int  _findnext(long, struct _finddata_t *);
#int  _findclose(long);
when defined(windows):
  type
    TFindData {.importc: "struct _finddata_t".} = record
      attrib {.importc: "attrib".}: cint
      time_create {.importc: "time_create".}: cint
      time_access {.importc: "time_access".}: cint
      time_write {.importc: "time_write".}: cint
      size {.importc: "size".}: cint
      name {.importc: "name".}: array[0..259, char]

  proc findfirst(pathname: CString, f: ptr TFindData): cint {.
    importc: "_findfirst", header: "<io.h>".}
  proc findnext(handle: cint, f: ptr TFindData): cint {.
    importc: "_findnext", header: "<io.h>".}
  proc findclose(handle: cint) {.importc: "_findclose", header: "<io.h>".}
else:
  type
    TFindData {.importc: "glob_t".} = record
      gl_pathc: int     # count of paths matched by pattern
      gl_pathv: ptr array[0..1000_000, CString] # list of matched path names
      gl_offs: int      # slots to reserve at beginning of gl_pathv
    PFindData = ptr TFindData

  proc glob(pattern: cstring, flags: cint, errfunc: pointer,
            pglob: PFindData): cint {.
    importc: "glob", header: "<glob.h>".}

  proc globfree(pglob: PFindData) {.
    importc: "globfree", header: "<glob.h>".}

proc cremove(filename: CString): cint {.importc: "remove", noDecl.}
proc crename(oldname, newname: CString): cint {.importc: "rename", noDecl.}

when defined(Windows):
  proc cCopyFile(lpExistingFileName, lpNewFileName: CString,
                 bFailIfExists: cint): cint {.
    importc: "CopyFile", header: "<windows.h>".}
  #  cMoveFile(lpExistingFileName, lpNewFileName: CString): int
  #    {.importc: "MoveFile", noDecl, header: "<winbase.h>".}
  #  cRemoveFile(filename: CString, cmo: int)
  #    {.importc: "DeleteFile", noDecl, header: "<winbase.h>".}
else:
  # generic version of cCopyFile which works for any platform:
  proc cCopyFile(lpExistingFileName, lpNewFileName: CString,
            bFailIfExists: cint): cint =
    const
      bufSize = 8192 # 8K buffer
    var
      dest, src: TFile
    if not openFile(src, $lpExistingFilename): return -1
    if not openFile(dest, $lpNewFilename, fmWrite):
      closeFile(src)
      return -1
    var
      buf: Pointer = alloc(bufsize)
      bytesread, byteswritten: int
    while True:
      bytesread = readBuffer(src, buf, bufsize)
      byteswritten = writeBuffer(dest, buf, bytesread)
      if bytesread != bufSize: break
    if byteswritten == bytesread: result = 0
    else: result = -1
    dealloc(buf)
    closeFile(src)
    closeFile(dest)


proc moveFile(dest, source: string) =
  if crename(source, dest) != 0:
    raise newException(EOS, "cannot move file from '$1' to '$2'" %
      [source, dest])

proc copyFile(dest, source: string) =
  if cCopyFile(source, dest, 0) != 0:
    raise newException(EOS, "cannot copy file from '$1' to '$2'" %
      [source, dest])

proc removeFile(file: string) =
  if cremove(file) != 0:
    raise newException(EOS, "cannot remove file '$1'" % file)

proc removeDir(dir: string) =
  if rmdir(dir) != 0:
    raise newException(EOS, "cannot remove directory '$1'" % dir)

proc createDir(dir: string) =
  when defined(unix):
    if mkdir(dir, 0o711) != 0 and int(errno) != EEXIST:
      raise newException(EOS, "cannot create directory '$1'" % dir)
  else:
    if CreateDirectory(dir, nil) == 0 and GetLastError() != 183:
      raise newException(EOS, "cannot create directory '$1'" % dir)

proc existsDir(dir: string): bool =
  var safe = getCurrentDir()
  # just try to set the current dir to dir; if it works, it must exist:
  result = chdir(dir) == 0
  if result:
    setCurrentDir(safe) # set back to the old working directory

proc executeProcess(command: string): int =
  return csystem(command) # XXX: do this without shell

proc executeShellCommand(command: string): int =
  return csystem(command)

var
  envComputed: bool = false
  environment {.noStatic.}: seq[string] = []

when defined(windows):
  # because we support Windows GUI applications, things get really
  # messy here...
  proc GetEnvironmentStrings(): Pointer {.
    importc: "GetEnvironmentStrings", header: "<windows.h>".}
  proc FreeEnvironmentStrings(env: Pointer) {.
    importc: "FreeEnvironmentStrings", header: "<windows.h>".}
  proc strEnd(cstr: CString, c = 0): CString {.importc: "strchr", nodecl.}

  proc getEnvVarsC() {.noStatic.} =
    if not envComputed:
      var
        env = cast[CString](getEnvironmentStrings())
        e = env
      if e == nil: return # an error occured
      while True:
        var eend = strEnd(e)
        add environment, $e
        e = cast[CString](cast[TAddress](eend)+1)
        if eend[1] == '\0': break
      envComputed = true
      FreeEnvironmentStrings(env)

else:
  var
    gEnv {.importc: "gEnv".}: ptr array [0..10_000, CString]

  proc getEnvVarsC() {.noStatic.} =
    # retrieves the variables of char** env of C's main proc
    if not envComputed:
      var
        i: int = 0
      while True:
        if gEnv[i] == nil: break
        add environment, $gEnv[i]
        inc(i)
      envComputed = true

proc findEnvVar(key: string): int =
  getEnvVarsC()
  var temp = key & '='
  for i in 0..high(environment):
    if findSubStr(temp, environment[i]) == 0: return i
  return -1

proc getEnv(key: string): string =
  var i = findEnvVar(key)
  if i >= 0: 
    return copy(environment[i], findSubStr("=", environment[i])+1)
  else: 
    var env = cgetenv(key)
    if env == nil: return ""
    result = $env

proc existsEnv(key: string): bool =
  if cgetenv(key) != nil: return true
  else: return findEnvVar(key) >= 0

iterator iterOverEnvironment*(): tuple[string, string] =
  ## Iterate over all environments varialbes. In the first component of the
  ## tuple is the name of the current variable stored, in the second its value.
  getEnvVarsC()
  for i in 0..high(environment):
    var p = findSubStr("=", environment[i])
    yield (copy(environment[i], 0, p-1), copy(environment[i], p+1))

proc putEnv(key, val: string) =
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
  if cputenv(environment[indx]) != 0:
    raise newException(EOS, "attempt to set an invalid environment variable")

iterator walkFiles*(pattern: string): string =
  ## Iterate over all the files that match the `pattern`.
  ##
  ## `pattern` is OS dependant, but at least the "\*.ext"
  ## notation is supported.
  when defined(windows):
    var
      f: TFindData
      res: int
    res = findfirst(pattern, addr(f))
    if res != -1:
      while true:
        yield $f.name
        if int(findnext(res, addr(f))) == -1: break
      findclose(res)
  else: # here we use glob
    var
      f: TFindData
      res: int
    f.gl_offs = 0
    f.gl_pathc = 0
    f.gl_pathv = nil
    res = glob(pattern, 0, nil, addr(f))
    if res != 0: raise newException(EOS, "walkFiles() failed")
    for i in 0.. f.gl_pathc - 1:
      assert(f.gl_pathv[i] != nil)
      yield $f.gl_pathv[i]
    globfree(addr(f))

{.push warnings:off.}
proc ExistsFile(filename: string): bool =
  var
    res: TStat
  return stat(filename, res) >= 0
{.pop.}

proc cmpPaths(pathA, pathB: string): int =
  if FileSystemCaseSensitive:
    result = cmp(pathA, pathB)
  else:
    result = cmpIgnoreCase(pathA, pathB)

proc extractDir(path: string): string =
  var
    tail: string
  splitPath(path, result, tail)

proc extractFilename(path: string): string =
  var
    head: string
  splitPath(path, head, result)

proc expandFilename(filename: string): string =
  # returns the full path of 'filename'; "" on error
  var
    res: CString
  when defined(unix):
    res = realpath(filename, nil)
  else:
    res = fullpath(nil, filename, 0)
  if res == nil:
    result = "" # an error occured
  else:
    result = $res
    free(res)

when defined(windows):
  proc GetHomeDir(): string = return getEnv("USERPROFILE") & "\\"
  proc GetConfigDir(): string = return getEnv("APPDATA") & "\\"

  # Since we support GUI applications with Nimrod, we sometimes generate
  # a WinMain entry proc. But a WinMain proc has no access to the parsed
  # command line arguments. The way to get them differs. Thus we parse them
  # ourselves. This has the additional benefit that the program's behaviour
  # is always the same -- independent of the used C compiler.
  proc GetCommandLine(): CString {.
    importc: "GetCommandLine", header: "<windows.h>".}

  var
    ownArgc: int = -1
    ownArgv: seq[string] = []

  proc parseCmdLine() =
    if ownArgc != -1: return # already processed
    var
      i = 0
      j = 0
      c = getCommandLine()
    ownArgc = 0
    while c[i] != '\0':
      var a = ""
      while c[i] >= '\1' and c[i] <= ' ': inc(i) # skip whitespace
      case c[i]
      of '\'', '\"':
        var delim = c[i]
        inc(i) # skip ' or "
        while c[i] != '\0' and c[i] != delim:
          add a, c[i]
          inc(i)
        if c[i] != '\0': inc(i)
      else:
        while c[i] > ' ':
          add a, c[i]
          inc(i)
      add ownArgv, a
      inc(ownArgc)

  proc paramStr(i: int): string =
    parseCmdLine()
    if i < ownArgc and i >= 0:
      return ownArgv[i]
    raise newException(EInvalidIndex, "invalid index")

  proc paramCount(): int =
    parseCmdLine()
    result = ownArgc-1

else:
  proc GetHomeDir(): string = return getEnv("HOME") & "/"
  proc GetConfigDir(): string = return getEnv("HOME") & "/"

  var
    cmdCount {.importc: "cmdCount".}: int
    cmdLine {.importc: "cmdLine".}: cstringArray

  proc paramStr(i: int): string =
    if i < cmdCount and i >= 0: return $cmdLine[i]
    raise newException(EInvalidIndex, "invalid index")

  proc paramCount(): int = return cmdCount-1

{.pop.}
