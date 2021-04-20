# Include file that implements 'DirSep' and friends. Do not import this when
# you also import `os.nim`!

# Improved based on info in 'compiler/platform.nim'

const
  doslikeFileSystem* = defined(windows) or defined(OS2) or defined(DOS)

const
  CurDir* =
    when defined(macos): ':'
    elif defined(genode): '/'
    else: '.'
    ## The constant character used by the operating system to refer to the
    ## current directory.
    ##
    ## For example: `'.'` for POSIX or `':'` for the classic Macintosh.

  ParDir* =
    when defined(macos): "::"
    else: ".."
    ## The constant string used by the operating system to refer to the
    ## parent directory.
    ##
    ## For example: `".."` for POSIX or `"::"` for the classic Macintosh.

  DirSep* =
    when defined(macos): ':'
    elif doslikeFileSystem or defined(vxworks): '\\'
    elif defined(RISCOS): '.'
    else: '/'
    ## The character used by the operating system to separate pathname
    ## components, for example: `'/'` for POSIX, `':'` for the classic
    ## Macintosh, and `'\\'` on Windows.

  AltSep* =
    when doslikeFileSystem: '/'
    else: DirSep
    ## An alternative character used by the operating system to separate
    ## pathname components, or the same as `DirSep <#DirSep>`_ if only one separator
    ## character exists. This is set to `'/'` on Windows systems
    ## where `DirSep <#DirSep>`_ is a backslash (`'\\'`).

  PathSep* =
    when defined(macos) or defined(RISCOS): ','
    elif doslikeFileSystem or defined(vxworks): ';'
    elif defined(PalmOS) or defined(MorphOS): ':' # platform has ':' but osseps has ';'
    else: ':'
    ## The character conventionally used by the operating system to separate
    ## search path components (as in PATH), such as `':'` for POSIX
    ## or `';'` for Windows.

  FileSystemCaseSensitive* =
    when defined(macos) or defined(macosx) or doslikeFileSystem or defined(vxworks) or
         defined(PalmOS) or defined(MorphOS): false
    else: true
    ## True if the file system is case sensitive, false otherwise. Used by
    ## `cmpPaths proc <#cmpPaths,string,string>`_ to compare filenames properly.

  ExeExt* =
    when doslikeFileSystem: "exe"
    elif defined(atari): "tpp"
    elif defined(netware): "nlm"
    elif defined(vxworks): "vxe"
    elif defined(nintendoswitch): "elf"
    else: ""
    ## The file extension of native executables. For example:
    ## `""` for POSIX, `"exe"` on Windows (without a dot).

  ScriptExt* =
    when doslikeFileSystem: "bat"
    else: ""
    ## The file extension of a script file. For example: `""` for POSIX,
    ## `"bat"` on Windows.

  DynlibFormat* =
    when defined(macos): "$1.dylib" # platform has $1Lib
    elif defined(macosx): "lib$1.dylib"
    elif doslikeFileSystem or defined(atari): "$1.dll"
    elif defined(MorphOS): "$1.prc"
    elif defined(PalmOS): "$1.prc" # platform has lib$1.so
    elif defined(genode): "$1.lib.so"
    elif defined(netware): "$1.nlm"
    elif defined(amiga): "$1.Library"
    else: "lib$1.so"
    ## The format string to turn a filename into a `DLL`:idx: file (also
    ## called `shared object`:idx: on some operating systems).

  ExtSep* = '.'
    ## The character which separates the base filename from the extension;
    ## for example, the `'.'` in `os.nim`.

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
