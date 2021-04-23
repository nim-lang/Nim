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
  ast, transf, injectdestructors, modulegraphs

proc finalProcBody*(g: ModuleGraph; idgen: IdGenerator; prc: PSym; n: PNode): PNode =
  ## Transformations after sem'checking that we need to do.
  result = transformBody(g, idgen, prc, dontUseCache)
  if sfInjectDestructors in prc.flags:
    result = injectDestructorCalls(g, idgen, prc, result)

proc finalToplevelStmt*(g: ModuleGraph; idgen: IdGenerator; module: PSym; n: PNode): PNode =
  result = transformStmt(g, idgen, module, n)
