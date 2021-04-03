#
#
#            Nim's Runtime Library
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the `with` macro for easy
## function chaining. See https://github.com/nim-lang/RFCs/issues/193
## and https://github.com/nim-lang/RFCs/issues/192 for details leading to this
## particular design.
##
## **Since:** version 1.2.

import macros, private / underscored_calls

macro with*(arg: typed; calls: varargs[untyped]): untyped =
  ## This macro provides `chaining`:idx: of function calls.
  ## It does so by patching every call in `calls` to
  ## use `arg` as the first argument.
  ##
  ## .. caution:: This evaluates `arg` multiple times!
  runnableExamples:
    var x = "yay"
    with x:
      add "abc"
      add "efg"
    doAssert x == "yayabcefg"

    var a = 44
    with a:
      += 4
      -= 5
    doAssert a == 43

  result = newNimNode(nnkStmtList, arg)
  underscoredCalls(result, calls, arg)
