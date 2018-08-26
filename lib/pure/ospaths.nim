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

proc countWhile(s: string, pred: proc(a: char): bool, countdown = false): int =
  ## returns the number of elements in ``s`` that satisfy ``pred`` predicate
  ## without interruption, starting from beginning (when ``countdown`` is false)
  ## or end (when ``countdown`` is true)
  # see https://github.com/nim-lang/Nim/pull/8673
  if countdown:
    for i in countdown(s.len-1, 0):
      if not pred(s[i]): return s.len - i - 1
  else:
    for i in 0..<s.len:
      if not pred(s[i]): return i
  return s.len

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

proc rootPrefixLength(path: string) : int =
  ## Returns the length of the prefix that makes ``path`` absolute, or 0
  ## if ``path`` is relative.
  if len(path) == 0: return 0

  when doslikeFileSystem:
    if path[0] in {DirSep, AltSep}:
      return countWhile(path, proc(a: char): bool = a in {DirSep, AltSep})
    if len(path) > 1 and path[0] in {'a'..'z', 'A'..'Z'} and path[1] == ':':
      # eg: C:\\bar
      return 2 + countWhile(path[2..^1], proc(a: char): bool = a in {DirSep, AltSep})
  elif defined(macos):
    # according to https://perldoc.perl.org/File/Spec/Mac.html `:a` is a relative path
    if path[0] == ':':
      result = 0
    else:
      result = countWhile(path, proc(a: char): bool = a != ':')
  elif defined(RISCOS):
    result = if path[0] == '$': 1 else: 0
  elif defined(posix):
    result = countWhile(path, proc(a: char): bool = a == '/')

proc rootPrefix(path: string) : string =
  ## returns the prefix that makes ``path`` absolute, or ""
  ## if ``path`` is relative.
  let n = path.rootPrefixLength
  result = path[0..<n]

proc isAbsolute*(path: string): bool {.rtl, noSideEffect, extern: "nos$1".} =
  ## Returns whether ``path`` is absolute.
  ##
  ## On Windows, network paths are considered absolute too.
  runnableExamples:
    doAssert: not "".isAbsolute
    doAssert: not "foo".isAbsolute
    when defined(posix):
      doAssert "/".isAbsolute
    when defined(Windows):
      doAssert "C:\\foo".isAbsolute

  return rootPrefixLength(path) > 0

const absOverridesDefault = false

proc joinPath*(head, tail: string, absOverrides = absOverridesDefault): string {.
  noSideEffect, rtl, extern: "nos$1".} =
  ## Concatenates paths ``head`` and ``tail``.
  ##
  ## If ``tail`` is absolute and ``absOverrides`` is true, or ``head`` is empty,
  ## returns ``tail``. If ``tail`` is empty returns ``head``. Else, returns the
  ## concatenation with normalized separator between ``head`` and ``tail``.
  runnableExamples:
    when defined(posix):
      doAssert joinPath("usr", "lib") == "usr/lib"
      doAssert joinPath("usr", "") == "usr/"
      doAssert joinPath("", "lib") == "lib"
      doAssert joinPath("usr/", "/lib", absOverrides = true) == "/lib"
      doAssert joinPath("usr///", "//lib") == "usr/lib" ## `//` gets compressed
      doAssert joinPath("//", "lib") == "/lib" ## ditto
    when defined(Windows):
      ## Note: network paths are removed in this example:
      doAssert joinPath(r"E:\foo", r"D:\bar") == r"E:\foo\bar"
      doAssert joinPath("", r"D:\bar") == r"D:\bar"
      doAssert joinPath(r"/foo", r"\bar") == r"/foo\bar"
      doAssert joinPath(r"\foo", r"\bar", absOverrides = true) == r"\bar"

  if absOverrides and tail.isAbsolute:
    return tail

  if len(head) == 0:
    result = tail
  else:
    var tail2 = tail[rootPrefixLength(tail)..^1]
    result = normalizePathEnd(head, trailingSep = true) & tail2

proc joinPath*(parts: varargs[string], absOverrides: bool): string {.noSideEffect,
  rtl, extern: "nos$1varargs".} =
  if parts.len == 0:
    result = ""
  else:
    result = parts[0]
    for i in 1..high(parts):
      result = joinPath(result, parts[i], absOverrides)

proc joinPath*(parts: varargs[string]): string {.noSideEffect,
  rtl, extern: "nos$1varargs2".} =
  ## The same as `joinPath(head, tail, absOverrides)`, but works with any number
  ## of directory parts.
  runnableExamples:
    doAssert joinPath() == ""
    doAssert joinPath("foo") == "foo"
    when defined(posix):
      doAssert joinPath("foo", "/bar", "/baz", "tail", absOverrides = true) == "/baz/tail"
      doAssert joinPath("foo//", "/bar", "/baz", "tail/", absOverrides = false) == "foo/bar/baz/tail/"
  joinPath(parts, absOverridesDefault)

proc `/` * (head, tail: string): string {.noSideEffect.} =
  ## The same as ``joinPath(head, tail)``.
  runnableExamples:
    doAssert "" / "lib" == "lib"
    when defined(posix):
      doAssert "usr" / "" == "usr/"
      doAssert "" / "/lib" == "/lib"
      doAssert "usr/" / "/lib" == "usr/lib"
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
  # TODO: here and elsewhere, use countWhile
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
  ## This is often the same as the ``head`` result of ``splitPath``.
  ## If there is no parent, "" is returned.
  ## | Example: ``parentDir("/usr/local/bin") == "/usr/local"``.
  ## | Example: ``parentDir("/usr/local/bin/") == "/usr/local"``.
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
  ## ``name & ext`` from ``splitFile(path)``.
  if path.len == 0 or path[path.len-1] in {DirSep, AltSep}:
    result = ""
  else:
    result = splitPath(path).tail


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

when isMainModule:
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

  block rootPrefixLengthTest:
    doAssert "foo".rootPrefixLength == 0
    doAssert "/foo".rootPrefixLength == 1
    doAssert "//foo".rootPrefixLength == 2
    when doslikeFileSystem:
      doAssert r"\foo".rootPrefixLength == 1
      doAssert r"/foo".rootPrefixLength == 1
      doAssert r"C:".rootPrefixLength == 2
      doAssert r"C:\foo".rootPrefixLength == 3
      doAssert r"//foo".rootPrefixLength == 2
      doAssert r"C:\\foo".rootPrefixLength == 4

  block rootPrefixTest:
    doAssert "foo".rootPrefix == ""
    doAssert "//foo".rootPrefix == "//"
    when doslikeFileSystem:
      doAssert r"/\foo".rootPrefix == r"/\"
      doAssert r"C:\\foo".rootPrefix == r"C:\\"

  import sugar
  block countWhileTest:
    doAssert countWhile("abc", a=>a == '/') == 0
    doAssert countWhile("//abc", a=>a == '/') == 2
    doAssert countWhile("//", a=>a == '/') == 2
    doAssert countWhile("", a=>a == '/') == 0

    doAssert countWhile("abc", a=>a == '/', countdown = true) == 0
    doAssert countWhile("abc//", a=>a == '/', countdown = true) == 2
    doAssert countWhile("//", a=>a == '/', countdown = true) == 2
    doAssert countWhile("", a=>a == '/', countdown = true) == 0

    doAssert countWhile("abcDEF", isLowerAscii) == 3

