when defined(nimHasCompileSetting):
  proc compileSetting*(option: string): string {.
    magic: "CompileSetting", noSideEffect.}
  ## Can be used to get a string compile-time option. Example:
  ##
  ## .. code-block:: Nim
  ##   const nimcache = compileSetting("nimcachedir")

  proc compileSettingSeq*(option: string): seq[string] {.
    magic: "CompileSettingSeq", noSideEffect.}
  ## Can be used to get a multi-string compile-time option. Example:
  ##
  ## .. code-block:: Nim
  ##   const nimblePaths = compileSettingSeq("nimblePaths")

