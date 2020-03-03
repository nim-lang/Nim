#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import strutils except Letters
import ".." / [ast, msgs, lineinfos, idents, options, linter]

proc replaceDeprecated*(conf: ConfigRef; info: TLineInfo; oldSym, newSym: PIdent) =
  let line = sourceLine(conf, info)
  var first = min(info.col.int, line.len)
  if first < 0: return
  #inc first, skipIgnoreCase(line, "proc ", first)
  while first > 0 and line[first-1] in Letters: dec first
  if first < 0: return
  if line[first] == '`': inc first

  let last = first+identLen(line, first)-1
  if cmpIgnoreStyle(line[first..last], oldSym.s) == 0:
    var x = line.substr(0, first-1) & newSym.s & line.substr(last+1)
    system.shallowCopy(conf.m.fileInfos[info.fileIndex.int32].lines[info.line.int-1], x)
    conf.m.fileInfos[info.fileIndex.int32].dirty = true
    #if newSym.s == "File": writeStackTrace()

proc replaceDeprecated*(conf: ConfigRef; info: TLineInfo; oldSym, newSym: PSym) =
  replaceDeprecated(conf, info, oldSym.name, newSym.name)

proc replaceComment*(conf: ConfigRef; info: TLineInfo) =
  let line = sourceLine(conf, info)
  var first = info.col.int
  if line[first] != '#': inc first

  var x = line.substr(0, first-1) & "discard " & line.substr(first+1).escape
  system.shallowCopy(conf.m.fileInfos[info.fileIndex.int32].lines[info.line.int-1], x)
  conf.m.fileInfos[info.fileIndex.int32].dirty = true
