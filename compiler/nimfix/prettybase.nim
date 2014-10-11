#
#
#           The Nim Compiler
#        (c) Copyright 2014 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import ast, msgs, strutils, idents, lexbase, streams
from os import splitFile

type
  TSourceFile* = object
    lines*: seq[string]
    dirty*, isNimfixFile*: bool
    fullpath*, newline*: string
    fileIdx*: int32

var
  gSourceFiles*: seq[TSourceFile] = @[]

proc loadFile*(info: TLineInfo) =
  let i = info.fileIndex
  if i >= gSourceFiles.len:
    gSourceFiles.setLen(i+1)
  if gSourceFiles[i].lines.isNil:
    gSourceFiles[i].fileIdx = info.fileIndex
    gSourceFiles[i].lines = @[]
    let path = info.toFullPath
    gSourceFiles[i].fullpath = path
    gSourceFiles[i].isNimfixFile = path.splitFile.ext == ".nimfix"
    # we want to die here for IOError:
    for line in lines(path):
      gSourceFiles[i].lines.add(line)
    # extract line ending of the file:
    var lex: TBaseLexer
    open(lex, newFileStream(path, fmRead))
    var pos = lex.bufpos
    while true:
      case lex.buf[pos]
      of '\c': 
        gSourceFiles[i].newline = "\c\L"
        break
      of '\L', '\0':
        gSourceFiles[i].newline = "\L"
        break
      else: discard
      inc pos
    close(lex)

const
  Letters* = {'a'..'z', 'A'..'Z', '0'..'9', '\x80'..'\xFF', '_'}

proc identLen*(line: string, start: int): int =
  while start+result < line.len and line[start+result] in Letters:
    inc result

proc differ*(line: string, a, b: int, x: string): bool =
  let y = line[a..b]
  result = cmpIgnoreStyle(y, x) == 0 and y != x

proc replaceDeprecated*(info: TLineInfo; oldSym, newSym: PIdent) =
  loadFile(info)

  let line = gSourceFiles[info.fileIndex].lines[info.line-1]
  var first = min(info.col.int, line.len)
  if first < 0: return
  #inc first, skipIgnoreCase(line, "proc ", first)
  while first > 0 and line[first-1] in Letters: dec first
  if first < 0: return
  if line[first] == '`': inc first
  
  let last = first+identLen(line, first)-1
  if cmpIgnoreStyle(line[first..last], oldSym.s) == 0:
    var x = line.substr(0, first-1) & newSym.s & line.substr(last+1)
    system.shallowCopy(gSourceFiles[info.fileIndex].lines[info.line-1], x)
    gSourceFiles[info.fileIndex].dirty = true
    #if newSym.s == "File": writeStackTrace()

proc replaceDeprecated*(info: TLineInfo; oldSym, newSym: PSym) =
  replaceDeprecated(info, oldSym.name, newSym.name)

proc replaceComment*(info: TLineInfo) =
  loadFile(info)

  let line = gSourceFiles[info.fileIndex].lines[info.line-1]
  var first = info.col.int
  if line[first] != '#': inc first

  var x = line.substr(0, first-1) & "discard " & line.substr(first+1).escape
  system.shallowCopy(gSourceFiles[info.fileIndex].lines[info.line-1], x)
  gSourceFiles[info.fileIndex].dirty = true
