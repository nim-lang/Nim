#
#
#           The Nim Compiler
#        (c) Copyright 2020 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

proc compileSetting*(option: string): string {.
  compiletime, noSideEffect.} = discard
## Can be used to get a string compile-time option. Example:
##
## .. code-block:: Nim
##   const nimcache = compileSetting("nimcachedir")

proc compileSettingSeq*(option: string): seq[string] {.
  compiletime, noSideEffect.} = discard
## Can be used to get a multi-string compile-time option. Example:
##
## .. code-block:: Nim
##   const nimblePaths = compileSettingSeq("nimblePaths")
