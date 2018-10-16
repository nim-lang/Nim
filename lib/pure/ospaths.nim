#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Forwarded by the ``os`` module but a module in its own right for NimScript
# support.

include "system/inclrtl"

import strutils

type
  ReadEnvEffect* = object of ReadIOEffect   ## effect that denotes a read
                                            ## from an environment variable
  WriteEnvEffect* = object of WriteIOEffect ## effect that denotes a write
                                            ## to an environment variable

  ReadDirEffect* = object of ReadIOEffect   ## effect that denotes a read
                                            ## operation from the directory
                                            ## structure
  WriteDirEffect* = object of WriteIOEffect ## effect that denotes a write
                                            ## operation to
                                            ## the directory structure

  OSErrorCode* = distinct int32 ## Specifies an OS Error Code.

const
  doslikeFileSystem* = defined(windows) or defined(OS2) or defined(DOS)

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
      ## character exists. This is set to '/' on Windows systems
      ## where `DirSep` is a backslash.

    PathSep* = ':'
      ## The character conventionally used by the operating system to separate
      ## search patch components (as in PATH), such as ':' for POSIX
      ## or ';' for Windows.

    FileSystemCaseSensitive* = true
      ## true if the file system is case sensitive, false otherwise. Used by
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
  #  A path containing no colon or which begins with a colon is a partial
  #  path.
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
elif doslikeFileSystem:
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
    FileSystemCaseSensitive* = when defined(macosx): false else: true
    ExeExt* = ""
    ScriptExt* = ""
    DynlibFormat* = when defined(macosx): "lib$1.dylib" else: "lib$1.so"

const
  ExtSep* = '.'
    ## The character which separates the base filename from the extension;
    ## for example, the '.' in ``os.nim``.

proc normalizePathEnd(path: var string, trailingSep = false) =
  ## ensures ``path`` has exactly 0 or 1 trailing `DirSep`, depending on
  ## ``trailingSep``, and taking care of edge cases: it preservers whether
  ## a path is absolute or relative, and makes sure trailing sep is `DirSep`,
  ## not `AltSep`.
  if path.len == 0: return
  var i = path.len
  while i >= 1 and path[i-1] in {DirSep, AltSep}: dec(i)
  if trailingSep:
    # foo// => foo
    path.setLen(i)
    # foo => foo/
    path.add DirSep
  elif i>0:
    # foo// => foo
    path.setLen(i)
  else:
    # // => / (empty case was already taken care of)
    path = $DirSep

proc normalizePathEnd(path: string, trailingSep = false): string =
  result = path
  result.normalizePathEnd(trailingSep)

proc joinPath*(head, tail: string): string {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Joins two directory names to one.
  ##
  ## For example on Unix:
  ##
  ## .. code-block:: nim
  ##   joinPath("usr", "lib")
  ##
  ## results in:
  ##
  ## .. code-block:: nim
  ##   "usr/lib"
  ##
  ## If head is the empty string, tail is returned. If tail is the empty
  ## string, head is returned with a trailing path separator. If tail starts
  ## with a path separator it will be removed when concatenated to head. Other
  ## path separators not located on boundaries won't be modified. More
  ## examples on Unix:
  ##
  ## .. code-block:: nim
  ##   assert joinPath("usr", "") == "usr/"
  ##   assert joinPath("", "lib") == "lib"
  ##   assert joinPath("", "/lib") == "/lib"
  ##   assert joinPath("usr/", "/lib") == "usr/lib"
  if len(head) == 0:
    result = tail
  elif head[len(head)-1] in {DirSep, AltSep}:
    if tail.len > 0 and tail[0] in {DirSep, AltSep}:
      result = head & substr(tail, 1)
    else:
      result = head & tail
  else:
    if tail.len > 0 and tail[0] in {DirSep, AltSep}:
      result = head & tail
    else:
      result = head & DirSep & tail

proc joinPath*(parts: varargs[string]): string {.noSideEffect,
  rtl, extern: "nos$1OpenArray".} =
  ## The same as `joinPath(head, tail)`, but works with any number of
  ## directory parts. You need to pass at least one element or the proc
  ## will assert in debug builds and crash on release builds.
  result = parts[0]
  for i in 1..high(parts):
    result = joinPath(result, parts[i])

proc `/` * (head, tail: string): string {.noSideEffect.} =
  ## The same as ``joinPath(head, tail)``
  ##
  ## Here are some examples for Unix:
  ##
  ## .. code-block:: nim
  ##   assert "usr" / "" == "usr/"
  ##   assert "" / "lib" == "lib"
  ##   assert "" / "/lib" == "/lib"
  ##   assert "usr/" / "/lib" == "usr/lib"
  return joinPath(head, tail)

proc splitPath*(path: string): tuple[head, tail: string] {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Splits a directory into (head, tail), so that
  ## ``head / tail == path`` (except for edge cases like "/usr").
  ##
  ## Examples:
  ##
  ## .. code-block:: nim
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
  if len(path) >= 1 and path[len(path)-1] in {DirSep, AltSep}: q = 2
  for i in countdown(len(path)-q, 0):
    if path[i] in {DirSep, AltSep}: return i
  result = -1

proc parentDir*(path: string): string {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Returns the parent directory of `path`.
  ##
  ## This is the same as ``splitPath(path).head`` when ``path`` doesn't end
  ## in a dir separator.
  ## The remainder can be obtained with ``lastPathPart(path)``
  runnableExamples:
    doAssert parentDir("") == ""
    when defined(posix):
      doAssert parentDir("/usr/local/bin") == "/usr/local"
      doAssert parentDir("foo/bar/") == "foo"

  let sepPos = parentDirPos(path)
  if sepPos >= 0:
    result = substr(path, 0, sepPos-1)
  else:
    result = ""

proc tailDir*(path: string): string {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Returns the tail part of `path`..
  ##
  ## | Example: ``tailDir("/usr/local/bin") == "local/bin"``.
  ## | Example: ``tailDir("usr/local/bin/") == "local/bin"``.
  ## | Example: ``tailDir("bin") == ""``.
  var q = 1
  if len(path) >= 1 and path[len(path)-1] in {DirSep, AltSep}: q = 2
  for i in 0..len(path)-q:
    if path[i] in {DirSep, AltSep}:
      return substr(path, i+1)
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

proc `/../`*(head, tail: string): string {.noSideEffect.} =
  ## The same as ``parentDir(head) / tail`` unless there is no parent
  ## directory. Then ``head / tail`` is performed instead.
  let sepPos = parentDirPos(head)
  if sepPos >= 0:
    result = substr(head, 0, sepPos-1) / tail
  else:
    result = head / tail

proc normExt(ext: string): string =
  if ext == "" or ext[0] == ExtSep: result = ext # no copy needed here
  else: result = ExtSep & ext

proc searchExtPos*(path: string): int =
  ## Returns index of the '.' char in `path` if it signifies the beginning
  ## of extension. Returns -1 otherwise.
  # BUGFIX: do not search until 0! .DS_Store is no file extension!
  result = -1
  for i in countdown(len(path)-1, 1):
    if path[i] == ExtSep:
      result = i
      break
    elif path[i] in {DirSep, AltSep}:
      break # do not skip over path

proc splitFile*(path: string): tuple[dir, name, ext: string] {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Splits a filename into (dir, filename, extension).
  ## `dir` does not end in `DirSep`.
  ## `extension` includes the leading dot.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##   var (dir, name, ext) = splitFile("usr/local/nimc.html")
  ##   assert dir == "usr/local"
  ##   assert name == "nimc"
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
  ## ``name & ext`` from ``splitFile(path)``. See also ``lastPathPart``.
  runnableExamples:
    when defined(posix):
      doAssert extractFilename("foo/bar/") == ""
      doAssert extractFilename("foo/bar") == "bar"
  if path.len == 0 or path[path.len-1] in {DirSep, AltSep}:
    result = ""
  else:
    result = splitPath(path).tail

proc lastPathPart*(path: string): string {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## like ``extractFilename``, but ignores trailing dir separator; aka: `baseName`:idx:
  ## in some other languages.
  runnableExamples:
    when defined(posix):
      doAssert lastPathPart("foo/bar/") == "bar"
  let path = path.normalizePathEnd(trailingSep = false)
  result = extractFilename(path)

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
  runnableExamples:
    when defined(macosx):
      doAssert cmpPaths("foo", "Foo") == 0
    elif defined(posix):
      doAssert cmpPaths("foo", "Foo") > 0
  if FileSystemCaseSensitive:
    result = cmp(pathA, pathB)
  else:
    when defined(nimscript):
      result = cmpic(pathA, pathB)
    elif defined(nimdoc): discard
    else:
      result = cmpIgnoreCase(pathA, pathB)

proc isAbsolute*(path: string): bool {.rtl, noSideEffect, extern: "nos$1".} =
  ## Checks whether a given `path` is absolute.
  ##
  ## On Windows, network paths are considered absolute too.
  runnableExamples:
    doAssert(not "".isAbsolute)
    doAssert(not ".".isAbsolute)
    when defined(posix):
      doAssert "/".isAbsolute
      doAssert(not "a/".isAbsolute)

  if len(path) == 0: return false

  when doslikeFileSystem:
    var len = len(path)
    result = (path[0] in {'/', '\\'}) or
              (len > 1 and path[0] in {'a'..'z', 'A'..'Z'} and path[1] == ':')
  elif defined(macos):
    # according to https://perldoc.perl.org/File/Spec/Mac.html `:a` is a relative path
    result = path[0] != ':'
  elif defined(RISCOS):
    result = path[0] == '$'
  elif defined(posix):
    result = path[0] == '/'

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
    if path.len == 0:
        return ""

    var start: int
    if path[0] == '/':
      # an absolute path
      when doslikeFileSystem:
        if drive != "":
          result = drive & ":" & DirSep
        else:
          result = $DirSep
      elif defined(macos):
        result = "" # must not start with ':'
      else:
        result = $DirSep
      start = 1
    elif path[0] == '.' and (path.len == 1 or path[1] == '/'):
      # current directory
      result = $CurDir
      start = when doslikeFileSystem: 1 else: 2
    else:
      result = ""
      start = 0

    var i = start
    while i < len(path): # ../../../ --> ::::
      if i+2 < path.len and path[i] == '.' and path[i+1] == '.' and path[i+2] == '/':
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

include "includes/oserr"
when not defined(nimscript):
  include "includes/osenv"

proc getHomeDir*(): string {.rtl, extern: "nos$1",
  tags: [ReadEnvEffect, ReadIOEffect].} =
  ## Returns the home directory of the current user.
  ##
  ## This proc is wrapped by the expandTilde proc for the convenience of
  ## processing paths coming from user configuration files.
  when defined(windows): return string(getEnv("USERPROFILE")) & "\\"
  else: return string(getEnv("HOME")) & "/"

proc getConfigDir*(): string {.rtl, extern: "nos$1",
  tags: [ReadEnvEffect, ReadIOEffect].} =
  ## Returns the config directory of the current user for applications.
  ##
  ## On non-Windows OSs, this proc conforms to the XDG Base Directory
  ## spec. Thus, this proc returns the value of the XDG_CONFIG_HOME environment
  ## variable if it is set, and returns the default configuration directory,
  ## "~/.config/", otherwise.
  ##
  ## An OS-dependent trailing slash is always present at the end of the
  ## returned string; `\` on Windows and `/` on all other OSs.
  when defined(windows):
    result = getEnv("APPDATA").string
  else:
    result = getEnv("XDG_CONFIG_HOME", getEnv("HOME").string / ".config").string
  result.normalizePathEnd(trailingSep = true)

proc getTempDir*(): string {.rtl, extern: "nos$1",
  tags: [ReadEnvEffect, ReadIOEffect].} =
  ## Returns the temporary directory of the current user for applications to
  ## save temporary files in.
  ##
  ## **Please do not use this**: On Android, it currently
  ## returns ``getHomeDir()``, and on other Unix based systems it can cause
  ## security problems too. That said, you can override this implementation
  ## by adding ``-d:tempDir=mytempname`` to your compiler invokation.
  when defined(tempDir):
    const tempDir {.strdefine.}: string = nil
    return tempDir
  elif defined(windows): return string(getEnv("TEMP")) & "\\"
  elif defined(android): return getHomeDir()
  else: return "/tmp/"

proc expandTilde*(path: string): string {.
  tags: [ReadEnvEffect, ReadIOEffect].} =
  ## Expands ``~`` or a path starting with ``~/`` to a full path, replacing
  ## ``~`` with ``getHomeDir()`` (otherwise returns ``path`` unmodified).
  ##
  ## Windows: this is still supported despite Windows platform not having this
  ## convention; also, both ``~/`` and ``~\`` are handled.
  runnableExamples:
    doAssert expandTilde("~" / "appname.cfg") == getHomeDir() / "appname.cfg"
  if len(path) == 0 or path[0] != '~':
    result = path
  elif len(path) == 1:
    result = getHomeDir()
  elif (path[1] in {DirSep, AltSep}):
    result = getHomeDir() / path.substr(2)
  else:
    # TODO: handle `~bob` and `~bob/` which means home of bob
    result = path

# TODO: consider whether quoteShellPosix, quoteShellWindows, quoteShell, quoteShellCommand
# belong in `strutils` instead; they are not specific to paths
proc quoteShellWindows*(s: string): string {.noSideEffect, rtl, extern: "nosp$1".} =
  ## Quote s, so it can be safely passed to Windows API.
  ## Based on Python's subprocess.list2cmdline
  ## See http://msdn.microsoft.com/en-us/library/17w5ykft.aspx
  let needQuote = {' ', '\t'} in s or s.len == 0

  result = ""
  var backslashBuff = ""
  if needQuote:
    result.add("\"")

  for c in s:
    if c == '\\':
      backslashBuff.add(c)
    elif c == '\"':
      result.add(backslashBuff)
      result.add(backslashBuff)
      backslashBuff.setLen(0)
      result.add("\\\"")
    else:
      if backslashBuff.len != 0:
        result.add(backslashBuff)
        backslashBuff.setLen(0)
      result.add(c)

  if needQuote:
    result.add("\"")

proc quoteShellPosix*(s: string): string {.noSideEffect, rtl, extern: "nosp$1".} =
  ## Quote ``s``, so it can be safely passed to POSIX shell.
  ## Based on Python's pipes.quote
  const safeUnixChars = {'%', '+', '-', '.', '/', '_', ':', '=', '@',
                         '0'..'9', 'A'..'Z', 'a'..'z'}
  if s.len == 0:
    return "''"

  let safe = s.allCharsInSet(safeUnixChars)

  if safe:
    return s
  else:
    return "'" & s.replace("'", "'\"'\"'") & "'"

when defined(windows) or defined(posix) or defined(nintendoswitch):
  proc quoteShell*(s: string): string {.noSideEffect, rtl, extern: "nosp$1".} =
    ## Quote ``s``, so it can be safely passed to shell.
    when defined(windows):
      return quoteShellWindows(s)
    else:
      return quoteShellPosix(s)

  proc quoteShellCommand*(args: openArray[string]): string =
    ## Concatenates and quotes shell arguments `args`
    runnableExamples:
      when defined(posix):
        assert quoteShellCommand(["aaa", "", "c d"]) == "aaa '' 'c d'"
      when defined(windows):
        assert quoteShellCommand(["aaa", "", "c d"]) == "aaa \"\" \"c d\""
    # can't use `map` pending https://github.com/nim-lang/Nim/issues/8303
    for i in 0..<args.len:
      if i > 0: result.add " "
      result.add quoteShell(args[i])

proc isSep(c: char): bool {.noSideEffect.} = c in {DirSep, AltSep}

proc cmpCharInPath(a, b: char): bool {.noSideEffect.} =
  when FileSystemCaseSensitive:
    let r = a == b:
  else:
    let r = toLowerAscii(a) == toLowerAscii(b)
  return if r: true else: (a.isSep and b.isSep)

proc sameDrive(a, b: string): bool {.noSideEffect.} =
  when doslikeFileSystem:
    not (a.len > 1 and a[1] == ':' and isAlphaAscii(a[0]) and b.len > 1 and b[1] == ':' and a[0] != b[0])
  else:
    true

proc countDir(path: string; start, last: Natural): int {.noSideEffect.} =
  if start >= last:
    return 0

  result = 0
  if not path[start].isSep:
    inc(result)
  for i in (start+1)..<last:
    if path[i-1].isSep and not path[i].isSep:
      inc(result)

proc skipDirSep(path: string; start, last: Natural = 0): int {.noSideEffect.} =
  var p = start
  while p < last and path[p].isSep:
    inc(p)
  return p

proc rSkipDirSep(path: string; start, last: Natural = 0): int {.noSideEffect.} =
  var p = start
  while p > last and path[p].isSep:
    dec(p)
  return p

proc countParDir(path: string; start, last: Natural): (int, int) {.noSideEffect.} =
  var p = start
  var c = 0
  while p < last:
    if p <= last - ParDir.len and continuesWith(path, ParDir, p):
      p += ParDir.len
      inc(c)
      p = skipDirSep(path, p, last)
    else:
      break
  return (c, p)

proc getRelativePathFromAbsolute(path, baseDir: string): string {.
  noSideEffect.} =
  ## Convert 'path' to a relative path from baseDir.
  ##
  ## Both 'path' and 'baseDir' must be absolute paths.
  ## On DOS like filesystem, when a drive of 'path' is different from 'baseDir',
  ## this proc just return the 'path' as is because no way to calculate the relative path.
  ## This proc never read filesystem.
  ## 'baseDir' is always assumed to be a directory even if that path is actually a file.
  ##

  assert(isAbsolute(path) and isAbsolute(baseDir))

  if baseDir.len == 0:
    return path

  if not sameDrive(path, baseDir):
    return path

  let alast = path.len
  let blast = rSkipDirSep(baseDir, baseDir.len - 1, 0) + 1

  var pos = 0
  let m = min(alast, blast)
  while pos < m:
    if not cmpCharInPath(path[pos], baseDir[pos]):
      break
    inc(pos)

  if (pos == blast and (alast == blast or path[blast].isSep)) or (pos == alast and (blast > alast and baseDir[pos].isSep)):
    inc(pos)
  else:
    while pos != 0 and not path[pos-1].isSep:
      dec(pos)

  let numUp = countDir(baseDir, pos, blast)

  if numUp == 0 and pos >= alast:
    return $CurDir

  result = if numUp > 0: ParDir & (DirSep & ParDir).repeat(numUp-1) else: ""
  if pos < path.len:
    return result / path.substr(pos)

proc isInRootDir(path: string; last: Natural): bool {.noSideEffect.} =
  if last == 0 and path[0].isSep:
    return true
  when doslikeFileSystem:
    if last < 3 and path.len > 1 and
       path[0] in {'a'..'z', 'A'..'Z'} and path[1] == ':':
      return true
  return false

proc getRelativePathFromRelative(path, baseDir, curDir: string): string {.
  noSideEffect.} =
  ## Convert 'path' to a path relative to baseDir.
  ##
  ## Both 'path' and 'baseDir' must be relative paths from 'curDir'.
  ## This proc never read filesystem.
  ## 'baseDir' is always assumed to be a directory even if that path is actually a file.

  proc skipCurDir(path: string): int {.noSideEffect.} =
    var p = 0
    let l = path.len
    while p < l:
      if p <= l - ParDir.len and continuesWith(path, ParDir, p):
        break
      if path[p] != CurDir:
        break
      inc(p)
      p = skipDirSep(path, p, l)
    return p

  assert(not (isAbsolute(path) or isAbsolute(baseDir)))

  if baseDir.len == 0:
    return path

  let alast = path.len
  let blast = rSkipDirSep(baseDir, baseDir.len - 1, 0) + 1

  let
    astart = skipCurDir(path)
    bstart = skipCurDir(baseDir)

  var
    apos = astart
    bpos = bstart

  while apos < alast and bpos < blast:
    if not cmpCharInPath(path[apos], baseDir[bpos]):
      break;
    inc(apos)
    inc(bpos)

  if (bpos == blast and (apos == alast or path[apos].isSep)) or
     (apos == alast and (bpos == blast or baseDir[bpos].isSep)):
    inc(apos)
  else:
    while apos != astart and not path[apos-1].isSep:
      dec(apos)
      dec(bpos)

  var numPar: int
  (numPar, bpos) = countParDir(baseDir, bpos, blast)

  let numUp = countDir(baseDir, bpos, blast)

  if numPar == 0 and numUp == 0 and apos >= alast:
    return $CurDir

  result = if numUp > 0: ParDir & (DirSep & ParDir).repeat(numUp-1) else: ""

  if numPar > 0:
    if curDir.len == 0:
      raise newException(ValueError, "parameter `curDir` is required to calculate relative path from given paths")
    var cpos = curDir.len-1
    for i in countDown(numPar-1, 0):
      cpos = rSkipDirSep(curDir, cpos)
      if isInRootDir(curDir, cpos) or curDir[cpos] == CurDir:
        raise newException(ValueError, "Cannot calculate relative path from given paths")
      while cpos > 0 and not curDir[cpos].isSep:
        dec(cpos)
    if curDir[cpos].isSep:
      inc(cpos)
    result = result / curDir.substr(cpos)

  if apos < path.len:
    return result / path.substr(apos)

proc relativePath*(path, baseDir: string; curDir: string = ""): string {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Convert `path` to a path relative to baseDir.
  ##
  ## `path` and `baseDir` must be absolute paths or relative paths from `curDir`.
  ## When one of `path` and `baseDir` is relative and other one is absolute, `curDir` must be absolute.
  ##
  ## On DOS like filesystem, when a drive of `path` is different from `baseDir`,
  ## this proc just return the `path` as is because no way to calculate the relative path.
  ##
  ## This proc never read filesystem.
  ## `baseDir` is always assumed to be a directory even if that path is actually a file.
  runnableExamples:
    doAssert relativePath("/home/abc".unixToNativePath, "/".unixToNativePath) == "home/abc".unixToNativePath
    doAssert relativePath("/home/abc".unixToNativePath, "/home/abc/x".unixToNativePath) == "..".unixToNativePath
    doAssert relativePath("/home/abc/xyz".unixToNativePath, "/home/abc/x".unixToNativePath) == "../xyz".unixToNativePath
    doAssert relativePath("home/xyz/d".unixToNativePath, "home/xyz".unixToNativePath, "".unixToNativePath) == "d".unixToNativePath
    doAssert relativePath("abc".unixToNativePath, "xyz".unixToNativePath, "".unixToNativePath) == "../abc".unixToNativePath
    doAssert relativePath(".".unixToNativePath, "..".unixToNativePath, "/abc".unixToNativePath) == "abc".unixToNativePath
    doAssert relativePath("xyz/d".unixToNativePath, "/home/xyz".unixToNativePath, "/home".unixToNativePath) == "d".unixToNativePath
    doAssert relativePath("/home/xyz/d".unixToNativePath, "xyz".unixToNativePath, "/home".unixToNativePath) == "d".unixToNativePath
    doAssert relativePath("../d".unixToNativePath, "/usr".unixToNativePath, "/home/xyz".unixToNativePath) == "../home/d".unixToNativePath

  proc parentDirPos(path: string; start: Natural): int {.noSideEffect.} =
    let q = rSkipDirSep(path, start)
    if isInRootDir(path, q):
      return -1
    for i in countdown(q, 0):
      if path[i].isSep: return i
    return -1

  proc nParentDirPos(path: string; n: Natural): int {.noSideEffect.} =
    var p = path.len-1
    for i in 0..<n:
      p = parentDirPos(path, p)
      if p < 0:
        return p
    return p

  proc mergePath(head, tail: string): string {.noSideEffect.} =
    var
      numPar: int
      p: int
    (numPar, p) = countParDir(tail, 0, tail.len)
    if numPar == 0:
      return head / tail
    let q = nParentDirPos(head, numPar)
    if q < 0:
      raise newException(ValueError, "Cannot calculate relative path from given paths")
    return head.substr(0, q) / tail.substr(p)

  let
    isAbsp = isAbsolute(path)
    isAbsb = isAbsolute(baseDir)
  if isAbsp and isAbsb:
    return getRelativePathFromAbsolute(path, baseDir)
  elif not (isAbsp or isAbsb):
    return getRelativePathFromRelative(path, baseDir, curDir)

  if not isAbsolute(curDir):
    raise newException(ValueError, "Cannot calculate relative path from given paths")

  if isAbsp:
    return getRelativePathFromAbsolute(path, mergePath(curDir, baseDir))
  else:
    return getRelativePathFromAbsolute(mergePath(curDir, path), baseDir)

when isMainModule:
  assert quoteShellWindows("aaa") == "aaa"
  assert quoteShellWindows("aaa\"") == "aaa\\\""
  assert quoteShellWindows("") == "\"\""

  assert quoteShellPosix("aaa") == "aaa"
  assert quoteShellPosix("aaa a") == "'aaa a'"
  assert quoteShellPosix("") == "''"
  assert quoteShellPosix("a'a") == "'a'\"'\"'a'"

  when defined(posix):
    assert quoteShell("") == "''"

  block normalizePathEndTest:
    # handle edge cases correctly: shouldn't affect whether path is
    # absolute/relative
    doAssert "".normalizePathEnd(true) == ""
    doAssert "".normalizePathEnd(false) == ""
    doAssert "/".normalizePathEnd(true) == $DirSep
    doAssert "/".normalizePathEnd(false) == $DirSep

    when defined(posix):
      doAssert "//".normalizePathEnd(false) == "/"
      doAssert "foo.bar//".normalizePathEnd == "foo.bar"
      doAssert "bar//".normalizePathEnd(trailingSep = true) == "bar/"
    when defined(Windows):
      doAssert r"C:\foo\\".normalizePathEnd == r"C:\foo"
      doAssert r"C:\foo".normalizePathEnd(trailingSep = true) == r"C:\foo\"
      # this one is controversial: we could argue for returning `D:\` instead,
      # but this is simplest.
      doAssert r"D:\".normalizePathEnd == r"D:"
      doAssert r"E:/".normalizePathEnd(trailingSep = true) == r"E:\"
      doAssert "/".normalizePathEnd == r"\"
