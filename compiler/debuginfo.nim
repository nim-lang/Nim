#
#
#           The Nim Compiler
#        (c) Copyright 2016 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## The compiler can generate debuginfo to help debuggers in translating back from C/C++/JS code
## to Nim. The data structure has been designed to produce something useful with Nim's marshal
## module.

type
  FilenameHash* = uint32
  FilenameMapping* = object
    package*, file*: string
    mangled*: FilenameHash
  EnumDesc* = object
    size*: int
    owner*: FilenameHash
    id*: int
    name*: string
    values*: seq[(string, int)]
  DebugInfo* = object
    version*: int
    files*: seq[FilenameMapping]
    enums*: seq[EnumDesc]
    conflicts*: bool

{.experimental.}

using
  self: var DebugInfo
  package, file: string

{.this: self.}

proc sdbmHash(hash: FilenameHash, c: char): FilenameHash {.inline.} =
  return FilenameHash(c) + (hash shl 6) + (hash shl 16) - hash

proc sdbmHash(package, file): FilenameHash =
  template `&=`(x, c) = x = sdbmHash(x, c)
  result = 0
  for i in 0..<package.len:
    result &= package[i]
  result &= '.'
  for i in 0..<file.len:
    result &= file[i]

proc register*(self; package, file): FilenameHash =
  result = sdbmHash(package, file)
  for f in files:
    if f.mangled == result:
      if f.package == package and f.file == file: return
      conflicts = true
      break
  files.add(FilenameMapping(package: package, file: file, mangled: result))

proc hasEnum*(self: DebugInfo; ename: string; id: int; owner: FilenameHash): bool =
  for en in enums:
    if en.owner == owner and en.name == ename and en.id == id: return true

proc registerEnum*(self; ed: EnumDesc) =
  enums.add ed

proc init*(self) =
  version = 1
  files = @[]
  enums = @[]

var gDebugInfo*: DebugInfo
debuginfo.init gDebugInfo

import marshal, streams

proc writeDebugInfo*(self; file) =
  let s = newFileStream(file, fmWrite)
  store(s, self)
  s.close

proc writeDebugInfo*(file) = writeDebugInfo(gDebugInfo, file)

proc loadDebugInfo*(self; file) =
  let s = newFileStream(file, fmRead)
  load(s, self)
  s.close

proc loadDebugInfo*(file) = loadDebugInfo(gDebugInfo, file)
