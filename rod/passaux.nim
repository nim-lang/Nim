#
#
#           The Nimrod Compiler
#        (c) Copyright 2008 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# implements some little helper passes

import 
  strutils, ast, astalgo, passes, msgs, options

proc verbosePass*(): TPass
proc cleanupPass*(): TPass
# implementation

proc verboseOpen(s: PSym, filename: string): PPassContext = 
  #MessageOut('compiling ' + s.name.s);
  result = nil                # we don't need a context
  if gVerbosity > 0: rawMessage(hintProcessing, s.name.s)
  
proc verboseProcess(context: PPassContext, n: PNode): PNode = 
  result = n
  if context != nil: InternalError("logpass: context is not nil")
  if gVerbosity == 3: liMessage(n.info, hintProcessing, $(ast.gid))
  
proc verbosePass(): TPass = 
  initPass(result)
  result.open = verboseOpen
  result.process = verboseProcess

proc cleanUp(c: PPassContext, n: PNode): PNode = 
  var s: PSym
  result = n                  # we cannot clean up if dead code elimination is activated
  if (optDeadCodeElim in gGlobalOptions): return 
  case n.kind
  of nkStmtList: 
    for i in countup(0, sonsLen(n) - 1): discard cleanup(c, n.sons[i])
  of nkProcDef, nkMethodDef: 
    if (n.sons[namePos].kind == nkSym): 
      s = n.sons[namePos].sym
      if not (sfDeadCodeElim in getModule(s).flags) and not astNeeded(s): 
        s.ast.sons[codePos] = nil # free the memory
  else: 
    nil

proc cleanupPass(): TPass = 
  initPass(result)
  result.process = cleanUp
  result.close = cleanUp
