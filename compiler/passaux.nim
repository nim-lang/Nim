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
  strutils, ast, astalgo, passes, idents, msgs, options, idgen

from modulegraphs import ModuleGraph

proc verboseOpen(graph: ModuleGraph; s: PSym; cache: IdentCache): PPassContext =
  #MessageOut('compiling ' + s.name.s);
  result = nil                # we don't need a context
  rawMessage(hintProcessing, s.name.s)

proc verboseProcess(context: PPassContext, n: PNode): PNode =
  result = n
  if context != nil: internalError("logpass: context is not nil")
  if gVerbosity == 3:
    # system.nim deactivates all hints, for verbosity:3 we want the processing
    # messages nonetheless, so we activate them again unconditionally:
    incl(msgs.gNotes, hintProcessing)
    message(n.info, hintProcessing, $idgen.gFrontendId)

const verbosePass* = makePass(open = verboseOpen, process = verboseProcess)
