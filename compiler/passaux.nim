#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## implements some little helper passes

import 
  strutils, ast, astalgo, passes, msgs, options, idgen

proc verboseOpen(s: PSym): PPassContext =
  #MessageOut('compiling ' + s.name.s);
  result = nil                # we don't need a context
  if gVerbosity > 0: rawMessage(hintProcessing, s.name.s)
  
proc verboseProcess(context: PPassContext, n: PNode): PNode = 
  result = n
  if context != nil: internalError("logpass: context is not nil")
  if gVerbosity == 3: 
    # system.nim deactivates all hints, for verbosity:3 we want the processing
    # messages nonetheless, so we activate them again unconditionally:
    incl(msgs.gNotes, hintProcessing)
    message(n.info, hintProcessing, $idgen.gBackendId)
  
const verbosePass* = makePass(open = verboseOpen, process = verboseProcess)

proc cleanUp(c: PPassContext, n: PNode): PNode = 
  result = n
  # we cannot clean up if dead code elimination is activated
  if optDeadCodeElim in gGlobalOptions or n == nil: return 
  case n.kind
  of nkStmtList: 
    for i in countup(0, sonsLen(n) - 1): discard cleanUp(c, n.sons[i])
  of nkProcDef, nkMethodDef: 
    if n.sons[namePos].kind == nkSym: 
      var s = n.sons[namePos].sym
      if sfDeadCodeElim notin getModule(s).flags and not astNeeded(s): 
        s.ast.sons[bodyPos] = ast.emptyNode # free the memory
  else: 
    discard

const cleanupPass* = makePass(process = cleanUp, close = cleanUp)

