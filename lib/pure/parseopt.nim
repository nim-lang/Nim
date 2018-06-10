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
## Supported syntax with default empty ``shortNoVal``/``longNoVal``:
##
## 1. short options - ``-abcd``, where a, b, c, d are names
## 2. long option - ``--foo:bar``, ``--foo=bar`` or ``--foo``
## 3. argument - everything else
##
## When ``shortNoVal``/``longNoVal`` are non-empty then the ':' and '=' above
## are still accepted, but become optional.  Note that these option key sets
## must be updated along with the set of option keys taking no value, but
## keys which do take values need no special updates as their set evolves.
##
## When option values begin with ':' or '=' they need to be doubled up (as in
## ``--delim::``) or alternated (as in ``--delim=:``).
##
## The common ``--`` non-option argument delimiter appears as an empty string
## long option key.  ``OptParser.cmd``, ``OptParser.pos``, and
## ``os.parseCmdLine`` may be used to complete parsing in that case.

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
    cmd*: string              #  cmd,pos exported so caller can catch "--" as..
    pos*: int                 # ..empty key or subcmd cmdArg & handle specially
    inShortState: bool
    shortNoVal: set[char]
    longNoVal: seq[string]
    kind*: CmdLineKind        ## the dected command line token
    key*, val*: TaintedString ## key and value pair; ``key`` is the option
                              ## or the argument, ``value`` is not "" if
                              ## the option was given a value

proc parseWord(s: string, i: int, w: var string,
               delim: set[char] = {'\x09', ' '}): int =
  result = i
  if result < s.len and s[result] == '\"':
    inc(result)
    while result < s.len and s[result] != '\"':
      add(w, s[result])
      inc(result)
    if result < s.len and s[result] == '\"': inc(result)
  else:
    while result < s.len and s[result] notin delim:
      add(w, s[result])
      inc(result)

when declared(os.paramCount):
  proc quote(s: string): string =
    if find(s, {' ', '\t'}) >= 0 and s.len > 0 and s[0] != '"':
      if s[0] == '-':
        result = newStringOfCap(s.len)
        var i = parseWord(s, 0, result, {' ', '\x09', ':', '='})
        if i < s.len and s[i] in {':','='}:
          result.add s[i]
          inc i
        result.add '"'
        while i < s.len:
          result.add s[i]
          inc i
        result.add '"'
      else:
        result = '"' & s & '"'
    else:
      result = s

  # we cannot provide this for NimRtl creation on Posix, because we can't
  # access the command line arguments then!

  proc initOptParser*(cmdline = "", shortNoVal: set[char]={},
                      longNoVal: seq[string] = @[]): OptParser =
    ## inits the option parser. If ``cmdline == ""``, the real command line
    ## (as provided by the ``OS`` module) is taken.  If ``shortNoVal`` is
    ## provided command users do not need to delimit short option keys and
    ## values with a ':' or '='.  If ``longNoVal`` is provided command users do
    ## not need to delimit long option keys and values with a ':' or '='
    ## (though they still need at least a space).  In both cases, ':' or '='
    ## may still be used if desired.  They just become optional.
    result.pos = 0
    result.inShortState = false
    result.shortNoVal = shortNoVal
    result.longNoVal = longNoVal
    if cmdline != "":
      result.cmd = cmdline
    else:
      result.cmd = ""
      for i in countup(1, paramCount()):
        result.cmd.add quote(paramStr(i).string)
        result.cmd.add ' '
    result.kind = cmdEnd
    result.key = TaintedString""
    result.val = TaintedString""

  proc initOptParser*(cmdline: seq[TaintedString], shortNoVal: set[char]={},
                      longNoVal: seq[string] = @[]): OptParser =
    ## inits the option parser. If ``cmdline.len == 0``, the real command line
    ## (as provided by the ``OS`` module) is taken. ``shortNoVal`` and
    ## ``longNoVal`` behavior is the same as for ``initOptParser(string,...)``.
    result.pos = 0
    result.inShortState = false
    result.shortNoVal = shortNoVal
    result.longNoVal = longNoVal
    result.cmd = ""
    if cmdline.len != 0:
      for i in 0..<cmdline.len:
        result.cmd.add quote(cmdline[i].string)
        result.cmd.add ' '
    else:
      for i in countup(1, paramCount()):
        result.cmd.add quote(paramStr(i).string)
        result.cmd.add ' '
    result.kind = cmdEnd
    result.key = TaintedString""
    result.val = TaintedString""

proc handleShortOption(p: var OptParser) =
  var i = p.pos
  p.kind = cmdShortOption
  add(p.key.string, p.cmd[i])
  inc(i)
  p.inShortState = true
  while i < p.cmd.len and p.cmd[i] in {'\x09', ' '}:
    inc(i)
    p.inShortState = false
  if i < p.cmd.len and p.cmd[i] in {':', '='} or
      card(p.shortNoVal) > 0 and p.key.string[0] notin p.shortNoVal:
    if i < p.cmd.len and p.cmd[i] in {':', '='}:
      inc(i)
    p.inShortState = false
    while i < p.cmd.len and p.cmd[i] in {'\x09', ' '}: inc(i)
    i = parseWord(p.cmd, i, p.val.string)
  if i >= p.cmd.len: p.inShortState = false
  p.pos = i

proc next*(p: var OptParser) {.rtl, extern: "npo$1".} =
  ## parses the first or next option; ``p.kind`` describes what token has been
  ## parsed. ``p.key`` and ``p.val`` are set accordingly.
  var i = p.pos
  while i < p.cmd.len and p.cmd[i] in {'\x09', ' '}: inc(i)
  p.pos = i
  setLen(p.key.string, 0)
  setLen(p.val.string, 0)
  if p.inShortState:
    handleShortOption(p)
    return
  if i >= p.cmd.len:
    p.kind = cmdEnd
    return
  if p.cmd[i] == '-':
    inc(i)
    if i < p.cmd.len and p.cmd[i] == '-':
      p.kind = cmdLongOption
      inc(i)
      i = parseWord(p.cmd, i, p.key.string, {' ', '\x09', ':', '='})
      while i < p.cmd.len and p.cmd[i] in {'\x09', ' '}: inc(i)
      if i < p.cmd.len and p.cmd[i] in {':', '='} or
          len(p.longNoVal) > 0 and p.key.string notin p.longNoVal:
        if i < p.cmd.len and p.cmd[i] in {':', '='}:
          inc(i)
        while i < p.cmd.len and p.cmd[i] in {'\x09', ' '}: inc(i)
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

iterator getopt*(p: var OptParser): tuple[kind: CmdLineKind, key, val: TaintedString] =
  ## This is an convenience iterator for iterating over the given OptParser object.
  ## Example:
  ##
  ## .. code-block:: nim
  ##   var p = initOptParser("--left --debug:3 -l -r:2")
  ##   for kind, key, val in p.getopt():
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
  p.pos = 0
  while true:
    next(p)
    if p.kind == cmdEnd: break
    yield (p.kind, p.key, p.val)

when declared(initOptParser):
  iterator getopt*(cmdline: seq[TaintedString] = commandLineParams(),
                   shortNoVal: set[char]={}, longNoVal: seq[string] = @[]):
             tuple[kind: CmdLineKind, key, val: TaintedString] =
    ## This is an convenience iterator for iterating over command line arguments.
    ## This creates a new OptParser.  See the above ``getopt(var OptParser)``
    ## example for using default empty ``NoVal`` parameters.  This example is
    ## for the same option keys as that example but here option key-value
    ## separators become optional for command users:
    ##
    ## .. code-block:: nim
    ##   for kind, key, val in getopt(shortNoVal = { 'l' },
    ##                                longNoVal = @[ "left" ]):
    ##     case kind
    ##     of cmdArgument:
    ##       filename = key
    ##     of cmdLongOption, cmdShortOption:
    ##       case key
    ##       of "help", "h": writeHelp()
    ##       of "version", "v": writeVersion()
    ##     of cmdEnd: assert(false) # cannot happen
    ##   if filename == "":
    ##     writeHelp()
    ##
    var p = initOptParser(cmdline, shortNoVal=shortNoVal, longNoVal=longNoVal)
    while true:
      next(p)
      if p.kind == cmdEnd: break
      yield (p.kind, p.key, p.val)

{.pop.}
