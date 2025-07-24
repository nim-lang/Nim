#
#
#            Nim's Runtime Library
#        (c) Copyright 2022 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## `outParamsAt` macro for easy writing code that works with both 2.0 and 1.x.

import std/macros

macro outParamsAt*(positions: static openArray[int]; n: untyped): untyped =
  ## Use this macro to annotate `out` parameters in a portable way.
  runnableExamples:
    proc p(x: var int) {.outParamsAt: [1].} =
      discard "x is really an 'out int' if the Nim compiler supports 'out' parameters"

  result = n
  when defined(nimHasOutParams):
    var p = n.params
    for po in positions:
      p[po][^2].expectKind nnkVarTy
      p[po][^2] = newTree(nnkOutTy, p[po][^2][0])

when isMainModule:
  {.experimental: "strictDefs".}

  proc main(x: var int) {.outParamsAt: [1].} =
    x = 3

  proc us =
    var x: int
    main x
    echo x

  us()
