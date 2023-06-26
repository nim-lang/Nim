const
  NimMajor* {.intdefine.}: int = 1
    ## is the major number of Nim's version. Example:
    ##
    ## .. code-block:: Nim
    ##   when (NimMajor, NimMinor, NimPatch) >= (1, 3, 1): discard
    # see also std/private/since

  NimMinor* {.intdefine.}: int = 6
    ## is the minor number of Nim's version.
    ## Odd for devel, even for releases.

  NimPatch* {.intdefine.}: int = 14
    ## is the patch number of Nim's version.
    ## Odd for devel, even for releases.
