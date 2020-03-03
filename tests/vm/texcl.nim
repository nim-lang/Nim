discard """
  output: '''false'''
"""

import macros

type
  nlOptions = enum
    nloNone
    nloDebug

var nlOpts {.compileTime.} = {nloDebug}

proc initOpts(): set[nlOptions] =
  result.incl nloDebug
  result.incl nloNone
  result.excl nloDebug

const cOpts = initOpts()

macro nlo() =
  nlOpts.incl(nloNone)
  nlOpts.excl(nloDebug)
  result = newEmptyNode()

nlo()
echo nloDebug in cOpts
