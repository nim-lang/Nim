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
## 1. short options - `-abcd`, where a, b, c, d are names
## 2. long option - `--foo:bar`, `--foo=bar` or `--foo`
## 3. argument - everything else

{.deprecated: "Use the 'parseopt' module instead".}
{.push debugger: off.}

include "system/inclrtl"

import
  os, strutils

type
  CmdLineKind* = enum         ## the detected command line token
    cmdEnd,                   ## end of command line reached
    cmdArgument,              ## argument detected
    cmdLongOption,            ## a long option `--option` detected
    cmdShortOption            ## a short option `-c` detected
  OptParser* =
      object of RootObj ## this object implements the command line parser
    cmd: seq[string]
    pos: int
    remainingShortOptions: string
    kind*: CmdLineKind        ## the detected command line token
    key*, val*: string        ## key and value pair; `key` is the option
                              ## or the argument, `value` is not "" if
                              ## the option was given a value

proc initOptParser*(cmdline: seq[string]): OptParser {.rtl.} =
  ## Initializes option parses with cmdline. cmdline should not contain
  ## argument 0 - program name.
  ## If cmdline.len == 0 default to current command line arguments.
  result.remainingShortOptions = ""
  when not defined(createNimRtl):
    if cmdline.len == 0:
      result.cmd = commandLineParams()
      return
  else:
    assert cmdline != nil, "Cannot determine command line arguments."

  result.cmd = @cmdline

when not defined(createNimRtl):
  proc initOptParser*(): OptParser =
    ## Initializes option parser from current command line arguments.
    return initOptParser(commandLineParams())

proc next*(p: var OptParser) {.rtl, extern: "npo2$1".}

proc nextOption(p: var OptParser, token: string, allowEmpty: bool) =
  for splitchar in [':', '=']:
    if splitchar in token:
      let pos = token.find(splitchar)
      p.key = token[0..pos-1]
      p.val = token[pos+1..token.len-1]
      return

  p.key = token
  if allowEmpty:
    p.val = ""
  else:
    p.remainingShortOptions = token[0..token.len-1]
    p.next()

proc next(p: var OptParser) =
  if p.remainingShortOptions.len != 0:
    p.kind = cmdShortOption
    p.key = p.remainingShortOptions[0..0]
    p.val = ""
    p.remainingShortOptions = p.remainingShortOptions[1..p.remainingShortOptions.len-1]
    return

  if p.pos >= p.cmd.len:
    p.kind = cmdEnd
    return

  let token = p.cmd[p.pos]
  p.pos += 1

  if token.startsWith("--"):
    p.kind = cmdLongOption
    nextOption(p, token[2..token.len-1], allowEmpty=true)
  elif token.startsWith("-"):
    p.kind = cmdShortOption
    nextOption(p, token[1..token.len-1], allowEmpty=true)
  else:
    p.kind = cmdArgument
    p.key = token
    p.val = ""

proc cmdLineRest*(p: OptParser): string {.rtl, extern: "npo2$1".} =
  ## Returns the part of command line string that has not been parsed yet,
  ## properly quoted.
  return p.cmd[p.pos..p.cmd.len-1].quoteShellCommand

type
  GetoptResult* = tuple[kind: CmdLineKind, key, val: string]

iterator getopt*(p: var OptParser): GetoptResult =
  ## This is an convenience iterator for iterating over the given OptParser object.
  ## Example:
  ##
  ## .. code-block:: nim
  ##   var p = initOptParser("--left --debug:3 -l=4 -r:2")
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

when declared(paramCount):
  iterator getopt*(): GetoptResult =
    ## This is an convenience iterator for iterating over the command line arguments.
    ## This create a new OptParser object.
    ## See above for a more detailed example
    ##
    ## .. code-block:: nim
    ##   for kind, key, val in getopt():
    ##     # this will iterate over all arguments passed to the cmdline.
    ##     continue
    ##
    var p = initOptParser()
    while true:
      next(p)
      if p.kind == cmdEnd: break
      yield (p.kind, p.key, p.val)

{.pop.}
