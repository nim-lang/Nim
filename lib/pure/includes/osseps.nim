# Include file that implements 'DirSep' and friends. Do not import this when
# you also import ``os.nim``!

const
  doslikeFileSystem* = defined(windows) or defined(OS2) or defined(DOS)

when defined(macos):
  const
    CurDirImpl = ':'
    ParDirImpl = "::"
    DirSepImpl = ':'
    AltSepImpl = DirSepImpl
    PathSepImpl = ','
    FileSystemCaseSensitiveImpl = false
    ExeExtImpl = ""
    ScriptExtImpl = ""
    DynlibFormatImpl = "$1.dylib"

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
    CurDirImpl = '.'
    ParDirImpl = ".."
    DirSepImpl = '\\' # separator within paths
    AltSepImpl = '/'
    PathSepImpl = ';' # separator between paths
    FileSystemCaseSensitiveImpl = false
    ExeExtImpl = "exe"
    ScriptExtImpl = "bat"
    DynlibFormatImpl = "$1.dll"
elif defined(PalmOS) or defined(MorphOS):
  const
    DirSepImpl = '/'
    AltSepImpl = DirSepImpl
    PathSepImpl = ';'
    ParDirImpl = ".."
    FileSystemCaseSensitiveImpl = false
    ExeExtImpl = ""
    ScriptExtImpl = ""
    DynlibFormatImpl = "$1.prc"
elif defined(RISCOS):
  const
    DirSepImpl = '.'
    AltSepImpl = '.'
    ParDirImpl = ".." # is this correct?
    PathSepImpl = ','
    FileSystemCaseSensitiveImpl = true
    ExeExtImpl = ""
    ScriptExtImpl = ""
    DynlibFormatImpl = "lib$1.so"
else: # UNIX-like operating system
  const
    CurDirImpl = '.'
    ParDirImpl = ".."
    DirSepImpl = '/'
    AltSepImpl = DirSepImpl
    PathSepImpl = ':'
    FileSystemCaseSensitiveImpl = when defined(macosx): false else: true
    ExeExtImpl = ""
    ScriptExtImpl = ""
    DynlibFormatImpl = when defined(macosx): "lib$1.dylib" else: "lib$1.so"

# for proper documentation:
const
  ExtSep* = '.'
    ## The character which separates the base filename from the extension;
    ## for example, the `'.'` in ``os.nim``.

  CurDir* = CurDirImpl
    ## The constant character used by the operating system to refer to the
    ## current directory.
    ##
    ## For example: `'.'` for POSIX or `':'` for the classic Macintosh.

  ParDir* = ParDirImpl
    ## The constant string used by the operating system to refer to the
    ## parent directory.
    ##
    ## For example: `".."` for POSIX or `"::"` for the classic Macintosh.

  DirSep* = DirSepImpl
    ## The character used by the operating system to separate pathname
    ## components, for example: `'/'` for POSIX, `':'` for the classic
    ## Macintosh, and `'\\'` on Windows.

  AltSep* = AltSepImpl
    ## An alternative character used by the operating system to separate
    ## pathname components, or the same as `DirSep <#DirSep>`_ if only one separator
    ## character exists. This is set to `'/'` on Windows systems
    ## where `DirSep <#DirSep>`_ is a backslash (`'\\'`).

  PathSep* = PathSepImpl
    ## The character conventionally used by the operating system to separate
    ## search patch components (as in PATH), such as `':'` for POSIX
    ## or `';'` for Windows.

  FileSystemCaseSensitive* = FileSystemCaseSensitiveImpl
    ## True if the file system is case sensitive, false otherwise. Used by
    ## `cmpPaths proc <#cmpPaths,string,string>`_ to compare filenames properly.

  ExeExt* = ExeExtImpl
    ## The file extension of native executables. For example:
    ## `""` for POSIX, `"exe"` on Windows (without a dot).

  ScriptExt* = ScriptExtImpl
    ## The file extension of a script file. For example: `""` for POSIX,
    ## `"bat"` on Windows.

  DynlibFormat* = DynlibFormatImpl
    ## The format string to turn a filename into a `DLL`:idx: file (also
    ## called `shared object`:idx: on some operating systems).
