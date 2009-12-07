#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2008 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# A command line parser; the Nimrod version of this file
# will become part of the standard library.

import 
  os, strutils

type 
  TCmdLineKind* = enum 
    cmdEnd,                   # end of command line reached
    cmdArgument,              # argument detected
    cmdLongoption,            # a long option ``--option`` detected
    cmdShortOption            # a short option ``-c`` detected
  TOptParser* = object of TObject
    cmd*: string
    pos*: int
    inShortState*: bool
    kind*: TCmdLineKind
    key*, val*: string


proc init*(cmdline: string = ""): TOptParser
proc next*(p: var TOptParser)
proc getRestOfCommandLine*(p: TOptParser): string
# implementation

proc init(cmdline: string = ""): TOptParser = 
  result.pos = 0
  result.inShortState = false
  if cmdline != "": 
    result.cmd = cmdline
  else: 
    result.cmd = ""
    for i in countup(1, ParamCount()): 
      result.cmd = result.cmd & quoteIfContainsWhite(paramStr(i)) & ' '
  result.kind = cmdEnd
  result.key = ""
  result.val = ""

proc parseWord(s: string, i: int, w: var string, 
               delim: TCharSet = {'\x09', ' ', '\0'}): int = 
  result = i
  if s[result] == '\"': 
    inc(result)
    while not (s[result] in {'\0', '\"'}): 
      add(w, s[result])
      inc(result)
    if s[result] == '\"': inc(result)
  else: 
    while not (s[result] in delim): 
      add(w, s[result])
      inc(result)

proc handleShortOption(p: var TOptParser) = 
  var i: int
  i = p.pos
  p.kind = cmdShortOption
  add(p.key, p.cmd[i])
  inc(i)
  p.inShortState = true
  while p.cmd[i] in {'\x09', ' '}: 
    inc(i)
    p.inShortState = false
  if p.cmd[i] in {':', '='}: 
    inc(i)
    p.inShortState = false
    while p.cmd[i] in {'\x09', ' '}: inc(i)
    i = parseWord(p.cmd, i, p.val)
  if p.cmd[i] == '\0': p.inShortState = false
  p.pos = i

proc next(p: var TOptParser) = 
  var i: int
  i = p.pos
  while p.cmd[i] in {'\x09', ' '}: inc(i)
  p.pos = i
  setlen(p.key, 0)
  setlen(p.val, 0)
  if p.inShortState: 
    handleShortOption(p)
    return 
  case p.cmd[i]
  of '\0': 
    p.kind = cmdEnd
  of '-': 
    inc(i)
    if p.cmd[i] == '-': 
      p.kind = cmdLongOption
      inc(i)
      i = parseWord(p.cmd, i, p.key, {'\0', ' ', '\x09', ':', '='})
      while p.cmd[i] in {'\x09', ' '}: inc(i)
      if p.cmd[i] in {':', '='}: 
        inc(i)
        while p.cmd[i] in {'\x09', ' '}: inc(i)
        p.pos = parseWord(p.cmd, i, p.val)
      else: 
        p.pos = i
    else: 
      p.pos = i
      handleShortOption(p)
  else: 
    p.kind = cmdArgument
    p.pos = parseWord(p.cmd, i, p.key)

proc getRestOfCommandLine(p: TOptParser): string = 
  result = strip(copy(p.cmd, p.pos + 0, len(p.cmd) - 1)) # always -1, because Pascal version uses a trailing zero here
  