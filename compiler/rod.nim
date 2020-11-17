#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the canonalization for the various caching mechanisms.

import ast, idgen, lineinfos, incremental, modulegraphs, pathutils

when not nimIncremental:
  template setupModuleCache*(g: ModuleGraph) = discard
  template storeNode*(g: ModuleGraph; module: PSym; n: PNode) = discard
  template loadNode*(g: ModuleGraph; module: PSym): PNode = newNode(nkStmtList)

  proc loadModuleSym*(g: ModuleGraph; fileIdx: FileIndex; fullpath: AbsoluteFile): (PSym, int) {.inline.} = (nil, getID())

  template addModuleDep*(g: ModuleGraph; module, fileIdx: FileIndex; isIncludeFile: bool) = discard

  template storeRemaining*(g: ModuleGraph; module: PSym) = discard

  template registerModule*(g: ModuleGraph; module: PSym) = discard

else:
  include rodimpl

  # idea for testing all this logic: *Always* load the AST from the DB, whether
  # we already have it in RAM or not!
