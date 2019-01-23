#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

when defined(nimdoc):
  include parseopt_doc

{.push debugger: off.}

include "system/inclrtl"

import
  os, strutils

type
  CmdLineKind* = enum         ## The detected command line token.
    cmdEnd,                   ## End of command line reached
    cmdArgument,              ## An argument such as a filename
    cmdLongOption,            ## A long option such as --option
    cmdShortOption            ## A short option such as -c
  OptParser* =
      object of RootObj ## Implementation of the command line parser.
      ##
      ## To initialize it, use the
      ## `initOptParser proc<#initOptParser,string,set[char],seq[string]>`_.
    pos*: int
    inShortState: bool
    allowWhitespaceAfterColon: bool
    shortNoVal: set[char]
    longNoVal: seq[string]
    cmds: seq[string]
    idx: int
    kind*: CmdLineKind        ## The detected command line token
    key*, val*: TaintedString ## Key and value pair; the key is the option
                              ## or the argument, and the value is not "" if
                              ## the option was given a value

proc parseWord(s: string, i: int, w: var string,
               delim: set[char] = {'\t', ' '}): int =
  result = i
  if result < s.len and s[result] == '\"':
    inc(result)
    while result < s.len:
      if s[result] == '"':
        inc result
        break
      add(w, s[result])
      inc(result)
  else:
    while result < s.len and s[result] notin delim:
      add(w, s[result])
      inc(result)

when declared(os.paramCount):
  # we cannot provide this for NimRtl creation on Posix, because we can't
  # access the command line arguments then!

  proc initOptParser*(cmdline = "", shortNoVal: set[char]={},
                      longNoVal: seq[string] = @[];
                      allowWhitespaceAfterColon = true): OptParser =
    ## Initializes the command line parser.
    ##
    ## If ``cmdline == ""``, the real command line as provided by the
    ## ``os`` module is retrieved instead.
    ##
    ## ``shortNoVal`` and ``longNoVal`` are used to specify which options
    ## do not take values. See the `documentation about these
    ## parameters<#shortnoval-and-longnoval>`_ for more information on
    ## how this affects parsing.
    ##
    ## See also:
    ## * `getopt iterator<#getopt.i,OptParser>`_
    runnableExamples:
      var p = initOptParser()
      p = initOptParser("--left --debug:3 -l -r:2")
      p = initOptParser("--left --debug:3 -l -r:2",
                        shortNoVal = {'l'}, longNoVal = @["left"])

    result.pos = 0
    result.idx = 0
    result.inShortState = false
    result.shortNoVal = shortNoVal
    result.longNoVal = longNoVal
    result.allowWhitespaceAfterColon = allowWhitespaceAfterColon
    if cmdline != "":
      result.cmds = parseCmdLine(cmdline)
    else:
      result.cmds = newSeq[string](paramCount())
      for i in countup(1, paramCount()):
        result.cmds[i-1] = paramStr(i).string

    result.kind = cmdEnd
    result.key = TaintedString""
    result.val = TaintedString""

  proc initOptParser*(cmdline: seq[TaintedString], shortNoVal: set[char]={},
                      longNoVal: seq[string] = @[];
                      allowWhitespaceAfterColon = true): OptParser =
    ## Initializes the command line parser.
    ##
    ## If ``cmdline.len == 0``, the real command line as provided by the
    ## ``os`` module is retrieved instead. Behavior of the other parameters
    ## remains the same as in `initOptParser(string, ...)
    ## <#initOptParser,string,set[char],seq[string]>`_.
    ##
    ## See also:
    ## * `getopt iterator<#getopt.i,seq[TaintedString],set[char],seq[string]>`_
    runnableExamples:
      var p = initOptParser()
      p = initOptParser(@["--left", "--debug:3", "-l", "-r:2"])
      p = initOptParser(@["--left", "--debug:3", "-l", "-r:2"],
                        shortNoVal = {'l'}, longNoVal = @["left"])

    result.pos = 0
    result.idx = 0
    result.inShortState = false
    result.shortNoVal = shortNoVal
    result.longNoVal = longNoVal
    result.allowWhitespaceAfterColon = allowWhitespaceAfterColon
    if cmdline.len != 0:
      result.cmds = newSeq[string](cmdline.len)
      for i in 0..<cmdline.len:
        result.cmds[i] = cmdline[i].string
    else:
      result.cmds = newSeq[string](paramCount())
      for i in countup(1, paramCount()):
        result.cmds[i-1] = paramStr(i).string
    result.kind = cmdEnd
    result.key = TaintedString""
    result.val = TaintedString""

proc handleShortOption(p: var OptParser; cmd: string) =
  var i = p.pos
  p.kind = cmdShortOption
  add(p.key.string, cmd[i])
  inc(i)
  p.inShortState = true
  while i < cmd.len and cmd[i] in {'\t', ' '}:
    inc(i)
    p.inShortState = false
  if i < cmd.len and cmd[i] in {':', '='} or
      card(p.shortNoVal) > 0 and p.key.string[0] notin p.shortNoVal:
    if i < cmd.len and cmd[i] in {':', '='}:
      inc(i)
    p.inShortState = false
    while i < cmd.len and cmd[i] in {'\t', ' '}: inc(i)
    p.val = TaintedString substr(cmd, i)
    p.pos = 0
    inc p.idx
  else:
    p.pos = i
  if i >= cmd.len:
    p.inShortState = false
    p.pos = 0
    inc p.idx

proc next*(p: var OptParser) {.rtl, extern: "npo$1".} =
  ## Parses the next token.
  ##
  ## ``p.kind`` describes what kind of token has been parsed. ``p.key`` and
  ## ``p.val`` are set accordingly.
  runnableExamples:
    var p = initOptParser("--left -r:2 file.txt")
    p.next()
    doAssert p.kind == cmdLongOption and p.key == "left"
    p.next()
    doAssert p.kind == cmdShortOption and p.key == "r" and p.val == "2"
    p.next()
    doAssert p.kind == cmdArgument and p.key == "file.txt"
    p.next()
    doAssert p.kind == cmdEnd

  if p.idx >= p.cmds.len:
    p.kind = cmdEnd
    return

  var i = p.pos
  while i < p.cmds[p.idx].len and p.cmds[p.idx][i] in {'\t', ' '}: inc(i)
  p.pos = i
  setLen(p.key.string, 0)
  setLen(p.val.string, 0)
  if p.inShortState:
    p.inShortState = false
    if i >= p.cmds[p.idx].len:
      inc(p.idx)
      p.pos = 0
      if p.idx >= p.cmds.len:
        p.kind = cmdEnd
        return
    else:
      handleShortOption(p, p.cmds[p.idx])
      return

  if i < p.cmds[p.idx].len and p.cmds[p.idx][i] == '-':
    inc(i)
    if i < p.cmds[p.idx].len and p.cmds[p.idx][i] == '-':
      p.kind = cmdLongOption
      inc(i)
      i = parseWord(p.cmds[p.idx], i, p.key.string, {' ', '\t', ':', '='})
      while i < p.cmds[p.idx].len and p.cmds[p.idx][i] in {'\t', ' '}: inc(i)
      if i < p.cmds[p.idx].len and p.cmds[p.idx][i] in {':', '='}:
        inc(i)
        while i < p.cmds[p.idx].len and p.cmds[p.idx][i] in {'\t', ' '}: inc(i)
        # if we're at the end, use the next command line option:
        if i >= p.cmds[p.idx].len and p.idx < p.cmds.len and p.allowWhitespaceAfterColon:
          inc p.idx
          i = 0
        p.val = TaintedString p.cmds[p.idx].substr(i)
      elif len(p.longNoVal) > 0 and p.key.string notin p.longNoVal and p.idx+1 < p.cmds.len:
        p.val = TaintedString p.cmds[p.idx+1]
        inc p.idx
      else:
        p.val = TaintedString""
      inc p.idx
      p.pos = 0
    else:
      p.pos = i
      handleShortOption(p, p.cmds[p.idx])
  else:
    p.kind = cmdArgument
    p.key = TaintedString p.cmds[p.idx]
    inc p.idx
    p.pos = 0

when declared(os.paramCount):
  proc cmdLineRest*(p: OptParser): TaintedString {.rtl, extern: "npo$1".} =
    ## Retrieves the rest of the command line that has not been parsed yet.
    ##
    ## See also:
    ## * `remainingArgs proc<#remainingArgs,OptParser>`_
    ##
    ## **Examples:**
    ##
    ## .. code-block::
    ##   var p = initOptParser("--left -r:2 -- foo.txt bar.txt")
    ##   while true:
    ##     p.next()
    ##     if p.kind == cmdLongOption and p.key == "":  # Look for "--"
    ##       break
    ##     else: continue
    ##   doAssert p.cmdLineRest == "foo.txt bar.txt"
    result = p.cmds[p.idx .. ^1].quoteShellCommand.TaintedString

  proc remainingArgs*(p: OptParser): seq[TaintedString] {.rtl, extern: "npo$1".} =
    ## Retrieves a sequence of the arguments that have not been parsed yet.
    ##
    ## See also:
    ## * `cmdLineRest proc<#cmdLineRest,OptParser>`_
    ##
    ## **Examples:**
    ##
    ## .. code-block::
    ##   var p = initOptParser("--left -r:2 -- foo.txt bar.txt")
    ##   while true:
    ##     p.next()
    ##     if p.kind == cmdLongOption and p.key == "":  # Look for "--"
    ##       break
    ##     else: continue
    ##   doAssert p.remainingArgs == @["foo.txt", "bar.txt"]
    result = @[]
    for i in p.idx..<p.cmds.len: result.add TaintedString(p.cmds[i])

iterator getopt*(p: var OptParser): tuple[kind: CmdLineKind, key, val: TaintedString] =
  ## Convenience iterator for iterating over the given
  ## `OptParser<#OptParser>`_.
  ##
  ## There is no need to check for ``cmdEnd`` while iterating.
  ##
  ## See also:
  ## * `initOptParser proc<#initOptParser,string,set[char],seq[string]>`_
  ##
  ## **Examples:**
  ##
  ## .. code-block::
  ##   # these are placeholders, of course
  ##   proc writeHelp() = discard
  ##   proc writeVersion() = discard
  ##
  ##   var filename: string
  ##   var p = initOptParser("--left --debug:3 -l -r:2")
  ##
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
  ##     # no filename has been given, so we show the help
  ##     writeHelp()
  p.pos = 0
  p.idx = 0
  while true:
    next(p)
    if p.kind == cmdEnd: break
    yield (p.kind, p.key, p.val)

when declared(initOptParser):
  iterator getopt*(cmdline: seq[TaintedString] = commandLineParams(),
                   shortNoVal: set[char]={}, longNoVal: seq[string] = @[]):
             tuple[kind: CmdLineKind, key, val: TaintedString] =
    ## Convenience iterator for iterating over command line arguments.
    ##
    ## This creates a new `OptParser<#OptParser>`_. If no command line
    ## arguments are provided, the real command line as provided by the
    ## ``os`` module is retrieved instead.
    ##
    ## ``shortNoVal`` and ``longNoVal`` are used to specify which options
    ## do not take values. See the `documentation about these
    ## parameters<#shortnoval-and-longnoval>`_ for more information on
    ## how this affects parsing.
    ##
    ## There is no need to check for ``cmdEnd`` while iterating.
    ##
    ## See also:
    ## * `initOptParser proc<#initOptParser,seq[TaintedString],set[char],seq[string]>`_
    ##
    ## **Examples:**
    ##
    ## .. code-block::
    ##
    ##   # these are placeholders, of course
    ##   proc writeHelp() = discard
    ##   proc writeVersion() = discard
    ##
    ##   var filename: string
    ##   let params = @["--left", "--debug:3", "-l", "-r:2"]
    ##
    ##   for kind, key, val in getopt(params):
    ##     case kind
    ##     of cmdArgument:
    ##       filename = key
    ##     of cmdLongOption, cmdShortOption:
    ##       case key
    ##       of "help", "h": writeHelp()
    ##       of "version", "v": writeVersion()
    ##     of cmdEnd: assert(false) # cannot happen
    ##   if filename == "":
    ##     # no filename has been written, so we show the help
    ##     writeHelp()
    var p = initOptParser(cmdline, shortNoVal=shortNoVal, longNoVal=longNoVal)
    while true:
      next(p)
      if p.kind == cmdEnd: break
      yield (p.kind, p.key, p.val)

{.pop.}
