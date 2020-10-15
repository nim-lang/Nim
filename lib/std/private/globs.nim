##[
unstable API, internal use only for now.
]##

#[
this module should be renamed to reflect its scope, eg to osutils.
]#

import std/[os,strutils,globs]

# {.deprecated: [walkDirRecFilter: glob].}
# export glob

proc nativeToUnixPath*(path: string): string =
  # pending https://github.com/nim-lang/Nim/pull/13265
  doAssert not path.isAbsolute # not implemented here; absolute files need more care for the drive
  when DirSep == '\\':
    result = replace(path, '\\', '/')
  else: result = path
