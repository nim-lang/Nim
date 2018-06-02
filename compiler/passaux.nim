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
  strutils, ast, astalgo, passes, idents, msgs, options, idgen, lineinfos

from modulegraphs import ModuleGraph

type
  VerboseRef = ref object of TPassContext
    config: ConfigRef

proc verboseOpen(graph: ModuleGraph; s: PSym): PPassContext =
  #MessageOut('compiling ' + s.name.s);
  result = VerboseRef(config: graph.config)
  rawMessage(graph.config, hintProcessing, s.name.s)

proc verboseProcess(context: PPassContext, n: PNode): PNode =
  result = n
  let v = VerboseRef(context)
  if v.config.verbosity == 3:
    # system.nim deactivates all hints, for verbosity:3 we want the processing
    # messages nonetheless, so we activate them again unconditionally:
    incl(v.config.notes, hintProcessing)
    message(v.config, n.info, hintProcessing, $idgen.gFrontendId)

const verbosePass* = makePass(open = verboseOpen, process = verboseProcess)
