#
#
#           The Nim Compiler
#        (c) Copyright 2025 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the NIF code generator.

import
  ast, astalgo, modulegraphs

type
  NifModule* = ref object of PPassContext
    graph*: ModuleGraph
    module*: PSym

proc closeNif*(graph: ModuleGraph; bModule: PPassContext; finalNode: PNode) =
  discard

proc setupNifgen*(graph: ModuleGraph; module: PSym; idgen: IdGenerator): PPassContext =
  var m = NifModule(graph: graph, module: module, idgen: idgen)
  result = m

proc genTopLevelNif*(bModule: PPassContext; finalNode: PNode) =
  let m = NifModule(bModule)
  discard "to implement"
