## Handles parsing of the input to nimsuggest
import compiler/options
import compiler/modulegraphs
import compiler/pathutils

import strutils, os ,parseopt, parseutils  

import types
const seps* = {':', ';', ' ', '\t'}


proc parseQuoted(cmd: string; outp: var string; start: int): int =
  var i = start
  i += skipWhitespace(cmd, i)
  if i < cmd.len and cmd[i] == '"':
    i += parseUntil(cmd, outp, '"', i+1)+2
  else:
    i += parseUntil(cmd, outp, seps, i)
  result = i
  

proc parseCommandLine*(cmdLine:string,projectFull:string):CommandData=
  ## Parses an input line to nimsuggest and returns a CommandData object with the content

  var cmdDat=CommandData()

  #We parse the input line in chunks using
  #parseIdent to move us forward by one token at a time
  var opc = ""
  var i = parseIdent(cmdLine, opc, 0)
# TODO: Repl this with a call to parseCommand
  let cmdString=opc.normalize
  let ideCmd=parseIdeCmd cmdString
  cmdDat.ideCmd=ideCmd
  if ideCmd==ideNone:
    cmdDat.ideCmdString=cmdString
    return cmdDat

  var dirtyFile=""
  var file=""
  i += skipWhitespace(cmdLine, i)
  if i < cmdLine.len and cmdLine[i] in {'0'..'9'}:
   file = string projectFull
  else:
    i = parseQuoted(cmdLine, file, i)
    if i < cmdLine.len and cmdLine[i] == ';':
      i = parseQuoted(cmdLine, dirtyFile, i+1)
    i += skipWhile(cmdLine, seps, i)
  cmdDat.line = 0
  cmdDat.col = -1
  i += parseInt(cmdLine, cmdDat.line, i)
  i += skipWhile(cmdLine, seps, i)
  i += parseInt(cmdLine, cmdDat.col, i)
  cmdDat.tag = substr(cmdLine, i)
  
  cmdDat.dirtyFile = AbsoluteFile dirtyFile
  cmdDat.file = AbsoluteFile file

  return cmdDat

