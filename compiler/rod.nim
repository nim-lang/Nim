#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the canonalization for the various caching mechanisms.

import ast, idgen, msgs

when not defined(nimSymbolfiles):
  template setupModuleCache* = discard
  template storeNode*(module: PSym; n: PNode) = discard
  template loadNode*(module: PSym; index: var int): PNode = PNode(nil)

  template getModuleId*(fileIdx: FileIndex; fullpath: string): int = getID()

  template addModuleDep*(module, fileIdx: FileIndex; isIncludeFile: bool) = discard

  template storeRemaining*(module: PSym) = discard

else:
  include rodimpl
