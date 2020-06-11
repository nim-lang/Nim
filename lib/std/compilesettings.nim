#
#
#           The Nim Compiler
#        (c) Copyright 2020 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module allows querying the compiler about
## diverse configuration settings.

# Note: Only add new enum values at the end to ensure binary compatibility with
# other Nim compiler versions!

type
  SingleValueSetting* {.pure.} = enum ## \
                      ## settings resulting in a single string value
    arguments,        ## experimental: the arguments passed after '-r'
    outFile,          ## experimental: the output file
    outDir,           ## the output directory
    nimcacheDir,      ## the location of the 'nimcache' directory
    projectName,      ## the project's name that is being compiled
    projectPath,      ## experimental: some path to the project that is being compiled
    projectFull,      ## the full path to the project that is being compiled
    command,          ## experimental: the command (e.g. 'c', 'cpp', 'doc') passed to
                      ## the Nim compiler
    commandLine,      ## experimental: the command line passed to Nim
    linkOptions,      ## additional options passed to the linker
    compileOptions,   ## additional options passed to the C/C++ compiler
    ccompilerPath     ## the path to the C/C++ compiler
    backend           ## the backend (eg: c|cpp|objc|js); both `nim doc --backend:js`
                      ## and `nim js` would imply backend=js

  MultipleValueSetting* {.pure.} = enum ## \
                      ## settings resulting in a seq of string values
    nimblePaths,      ## the nimble path(s)
    searchPaths,      ## the search path for modules
    lazyPaths,        ## experimental: even more paths
    commandArgs,      ## the arguments passed to the Nim compiler
    cincludes,        ## the #include paths passed to the C/C++ compiler
    clibs             ## libraries passed to the C/C++ compiler

proc querySetting*(setting: SingleValueSetting): string {.
  compileTime, noSideEffect.} = discard
  ## Can be used to get a string compile-time option. Example:
  ##
  ## .. code-block:: Nim
  ##   const nimcache = querySetting(SingleValueSetting.nimcacheDir)

proc querySettingSeq*(setting: MultipleValueSetting): seq[string] {.
  compileTime, noSideEffect.} = discard
  ## Can be used to get a multi-string compile-time option. Example:
  ##
  ## .. code-block:: Nim
  ##   const nimblePaths = compileSettingSeq(MultipleValueSetting.nimblePaths)

type NimVersionType* = object
  major*, minor*, patch*: int
  # `NimVersion` is already taken by `system.NimVersion`.
  # More type-safe than (int,int,int) since procs based on tuples would apply to
  # unrelated tuples, eg `proc `$`(a: (int,int,int))` would not be a great idea.

proc nimVersionCTImpl(): (int,int,int) {.compileTime.} = discard

const ver = nimVersionCTImpl()

const nimVersionCT* = NimVersionType(major: ver[0], minor: ver[1], patch: ver[2])
  ## return the stdlib version nim was compiled with.

const nimVersion* = NimVersionType(major: NimMajor, minor: NimMinor, patch: NimPatch)
  ## return the stdlib version.

template toTuple*(a: NimVersionType): untyped =
  (major: a.major, minor: a.minor, patch: a.patch)

#[
A bit hacky but allows using this before most of system.nim is defined
the only dependency is on NimMajor, NimMinor, NimPatch, `int`
]#

proc `<`(x, y: int): bool {.magic: "LtI", noSideEffect.}

proc `>=`(a, b: tuple[major: int, minor: int, patch: int]): bool =
  if b.major < a.major: return true
  if a.major < b.major: return false

  if b.minor < a.minor: return true
  if a.minor < b.minor: return false

  if b.patch < a.patch: return true
  if a.patch < b.patch: return false
  return true

proc `>=`*(a: NimVersionType, b: tuple[major: int, minor: int, patch: int]): bool =
  ## specialization so it can be used before `<=*[T: tuple]`
  ## is defined in system.nim, for low level modules (eg: iterators.nim).
  ## For other comparisons, use `a.toTuple` after `include system/comparisons`.
  runnableExamples:
    when nimVersionCT >= (1,3,5): discard
    doAssert nimVersionCT >= (1,3,5)
    doAssert nimVersionCT.toTuple < (99, 0, 0)
    doAssert nimVersionCT.toTuple != (99, 0, 0)
  a.toTuple >= b

template `$`*(a: NimVersionType): string =
  ## returns `major.minor.patch`
  $a.major & "." & $a.minor & "." & $a.patch
