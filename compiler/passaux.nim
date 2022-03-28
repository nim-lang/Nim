#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## implements some little helper passes

import
  ast, passes, msgs, options, lineinfos

from modulegraphs import ModuleGraph, PPassContext

type
  VerboseRef = ref object of PPassContext
    config: ConfigRef

proc verboseOpen(graph: ModuleGraph; s: PSym; idgen: IdGenerator): PPassContext =
  # xxx consider either removing this or keeping for documentation for how to add a pass
  result = VerboseRef(config: graph.config, idgen: idgen)

proc verboseProcess(context: PPassContext, n: PNode): PNode =
  # called from `process` in `processTopLevelStmt`.
  result = n
  let v = VerboseRef(context)
  message(v.config, n.info, hintProcessingStmt, $v.idgen[])

const verbosePass* = makePass(open = verboseOpen, process = verboseProcess)
