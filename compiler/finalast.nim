#
#
#           The Nim Compiler
#        (c) Copyright 2021 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a tiny intermediate layer.

import
  ast, transf,

proc finalProcBody*(prc: PSym; n: PNode): PNode =
  ## Transformations after sem'checking that we need to do.
  result = transformBody(m.g.graph, m.idgen, prc, cache = false)
  if sfInjectDestructors in prc.flags:
    result = injectDestructorCalls(m.g.graph, m.idgen, prc, result)

