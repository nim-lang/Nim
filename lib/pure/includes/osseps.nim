# Include file that implements 'DirSep' and friends. Do not import this when
# you also import ``os.nim``!

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
