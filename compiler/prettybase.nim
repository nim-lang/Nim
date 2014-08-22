#
#
#           The Nim Compiler
#        (c) Copyright 2014 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import ast, msgs, strutils

type
  TSourceFile* = object
    lines*: seq[string]
    dirty*: bool
    fullpath*: string

var
  gSourceFiles*: seq[TSourceFile] = @[]

proc loadFile*(info: TLineInfo) =
  let i = info.fileIndex
  if i >= gSourceFiles.len:
    gSourceFiles.setLen(i+1)
  if gSourceFiles[i].lines.isNil:
    gSourceFiles[i].lines = @[]
    let path = info.toFullPath
    gSourceFiles[i].fullpath = path
    # we want to die here for EIO:
    for line in lines(path):
      gSourceFiles[i].lines.add(line)

const
  Letters* = {'a'..'z', 'A'..'Z', '0'..'9', '\x80'..'\xFF', '_'}

proc identLen*(line: string, start: int): int =
  while start+result < line.len and line[start+result] in Letters:
    inc result

proc differ*(line: string, a, b: int, x: string): bool =
  let y = line[a..b]
  result = cmpIgnoreStyle(y, x) == 0 and y != x

proc replaceDeprecated*(info: TlineInfo; oldSym, newSym: PSym) =
  loadFile(info)

  let line = gSourceFiles[info.fileIndex].lines[info.line-1]
  var first = min(info.col.int, line.len)
  if first < 0: return
  #inc first, skipIgnoreCase(line, "proc ", first)
  while first > 0 and line[first-1] in Letters: dec first
  if first < 0: return
  if line[first] == '`': inc first
  
  let last = first+identLen(line, first)-1
  if cmpIgnoreStyle(line[first..last], oldSym.name.s) == 0:
    var x = line.substr(0, first-1) & newSym.name.s & line.substr(last+1)    
    system.shallowCopy(gSourceFiles[info.fileIndex].lines[info.line-1], x)
    gSourceFiles[info.fileIndex].dirty = true
