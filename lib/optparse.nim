#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2006 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


## This module provides a command line parser.
## It supports one iterator over all command line options.

#interface

{.push debugger: off.}

import
  os

proc findSep(s: string): int {.nostatic.} =
  for i in 0 .. high(s)-1:
    if s[i] in {'=', ':'}: return i
  return high(s)+1

iterator getopt*(): tuple[string, string] =
  # returns a (cmd, arg) tuple.
  for k in 1 .. ParamCount():
    var param = paramStr(k)
    if param[0] == '-':
      var j = findSep(param)
      cmd = copy(param, 0, j-1)
      arg = copy(param, j+1)
    else:
      cmd = ""
      arg = param
    yield cmd, arg

{.pop.}
