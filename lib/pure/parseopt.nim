#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module provides the standard Nim command line parser.
## It supports one convenience iterator over all command line options and some
## lower-level features.
##
## Supported syntax:
##
## 1. short options - ``-abcd``, where a, b, c, d are names
## 2. long option - ``--foo:bar``, ``--foo=bar`` or ``--foo``
## 3. argument - everything else

{.push debugger: off.}

include "system/inclrtl"

import 
  os, strutils

type 
  CmdLineKind* = enum         ## the detected command line token
    cmdEnd,                   ## end of command line reached
    cmdArgument,              ## argument detected
    cmdLongOption,            ## a long option ``--option`` detected
    cmdShortOption            ## a short option ``-c`` detected
  OptParser* = 
      object of RootObj ## this object implements the command line parser  
    cmd: string
    pos: int
    inShortState: bool
    kind*: CmdLineKind        ## the dected command line token
    key*, val*: TaintedString ## key and value pair; ``key`` is the option
                              ## or the argument, ``value`` is not "" if
                              ## the option was given a value

{.deprecated: [TCmdLineKind: CmdLineKind, TOptParser: OptParser].}

when declared(os.paramCount):
  # we cannot provide this for NimRtl creation on Posix, because we can't 
  # access the command line arguments then!

  proc initOptParser*(cmdline = ""): OptParser =
    ## inits the option parser. If ``cmdline == ""``, the real command line
    ## (as provided by the ``OS`` module) is taken.
    result.pos = 0
    result.inShortState = false
    if cmdline != "": 
      result.cmd = cmdline
    else: 
      result.cmd = ""
      for i in countup(1, paramCount()): 
        result.cmd = result.cmd & quoteIfContainsWhite(paramStr(i).string) & ' '
    result.kind = cmdEnd
    result.key = TaintedString""
    result.val = TaintedString""

proc parseWord(s: string, i: int, w: var string, 
               delim: set[char] = {'\x09', ' ', '\0'}): int = 
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

proc handleShortOption(p: var OptParser) = 
  var i = p.pos
  p.kind = cmdShortOption
  add(p.key.string, p.cmd[i])
  inc(i)
  p.inShortState = true
  while p.cmd[i] in {'\x09', ' '}: 
    inc(i)
    p.inShortState = false
  if p.cmd[i] in {':', '='}: 
    inc(i)
    p.inShortState = false
    while p.cmd[i] in {'\x09', ' '}: inc(i)
    i = parseWord(p.cmd, i, p.val.string)
  if p.cmd[i] == '\0': p.inShortState = false
  p.pos = i

proc next*(p: var OptParser) {.rtl, extern: "npo$1".} = 
  ## parses the first or next option; ``p.kind`` describes what token has been
  ## parsed. ``p.key`` and ``p.val`` are set accordingly.
  var i = p.pos
  while p.cmd[i] in {'\x09', ' '}: inc(i)
  p.pos = i
  setLen(p.key.string, 0)
  setLen(p.val.string, 0)
  if p.inShortState: 
    handleShortOption(p)
    return 
  case p.cmd[i]
  of '\0': 
    p.kind = cmdEnd
  of '-': 
    inc(i)
    if p.cmd[i] == '-': 
      p.kind = cmdLongoption
      inc(i)
      i = parseWord(p.cmd, i, p.key.string, {'\0', ' ', '\x09', ':', '='})
      while p.cmd[i] in {'\x09', ' '}: inc(i)
      if p.cmd[i] in {':', '='}: 
        inc(i)
        while p.cmd[i] in {'\x09', ' '}: inc(i)
        p.pos = parseWord(p.cmd, i, p.val.string)
      else: 
        p.pos = i
    else: 
      p.pos = i
      handleShortOption(p)
  else:
    p.kind = cmdArgument
    p.pos = parseWord(p.cmd, i, p.key.string)

proc cmdLineRest*(p: OptParser): TaintedString {.rtl, extern: "npo$1".} = 
  ## retrieves the rest of the command line that has not been parsed yet.
  result = strip(substr(p.cmd, p.pos, len(p.cmd) - 1)).TaintedString

when declared(initOptParser):
  iterator getopt*(): tuple[kind: CmdLineKind, key, val: TaintedString] =
    ## This is an convenience iterator for iterating over the command line.
    ## This uses the TOptParser object. Example:
    ##
    ## .. code-block:: nim
    ##   var
    ##     filename = ""
    ##   for kind, key, val in getopt():
    ##     case kind
    ##     of cmdArgument: 
    ##       filename = key
    ##     of cmdLongOption, cmdShortOption:
    ##       case key
    ##       of "help", "h": writeHelp()
    ##       of "version", "v": writeVersion()
    ##     of cmdEnd: assert(false) # cannot happen
    ##   if filename == "":
    ##     # no filename has been given, so we show the help:
    ##     writeHelp()
    var p = initOptParser()
    while true:
      next(p)
      if p.kind == cmdEnd: break
      yield (p.kind, p.key, p.val)

{.pop.}
