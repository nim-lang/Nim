#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import
  ast, astalgo, msgs, semdata

# Second semantic checking pass over the AST. Necessary because the old
# way had some inherent problems. Performs:
# 
# * procvar checks
# * effect tracking
# * closure analysis
# * checks for invalid usages of compiletime magics (not implemented)
# * checks for invalid usages of PNimNode (not implemented)
# * later: will do an escape analysis for closures at least

# Predefined effects:
#   io, time (time dependent), gc (performs GC'ed allocation), exceptions,
#   side effect (accesses global), store (stores into *type*),
#   store_unkown (performs some store) --> store(any)|store(x) 
#   load (loads from *type*), recursive (recursive call),
#   endless (has endless loops), --> user effects are defined over *patterns*
#   --> a TR macro can annotate the proc with user defined annotations
#   --> the effect system can access these

proc sem2call(c: PContext, n: PNode): PNode =
  assert n.kind in nkCallKinds
  
  

proc sem2sym(c: PContext, n: PNode): PNode =
  assert n.kind == nkSym
  

