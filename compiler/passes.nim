#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements the passes functionality. A pass must implement the
# `TPass` interface.

import 
  strutils, lists, options, ast, astalgo, llstream, msgs, platform, os, 
  condsyms, idents, renderer, types, extccomp, math, magicsys, nversion, 
  nimsets, syntaxes, times, rodread, semthreads, idgen

type
  TPassComm* = object {.pure.} ## communication object between passes
    optimizers*: TSymSeq       ## filled by semantic pass; used in HLO
  PPassComm* = ref TPassComm
  
  TPassContext* = object of TObject # the pass's context
    comm*: PPassComm
    fromCache*: bool  # true if created by "openCached"
    
  PPassContext* = ref TPassContext
  TPass* = tuple[
    open: proc (module: PSym, filename: string): PPassContext, 
    openCached: proc (module: PSym, filename: string,
                     rd: PRodReader): PPassContext, 
    close: proc (p: PPassContext, n: PNode): PNode, 
    process: proc (p: PPassContext, topLevelStmt: PNode): PNode] 
    
# a pass is a tuple of procedure vars ``TPass.close`` may produce additional 
# nodes. These are passed to the other close procedures. 
# This mechanism used to be used for the instantiation of generics.

proc registerPass*(p: TPass)
proc initPass*(p: var TPass)
  # This implements a memory preserving scheme: Top level statements are
  # processed in a pipeline. The compiler never looks at a whole module
  # any longer. However, this is simple to change, as new passes may perform
  # whole program optimizations. For now, we avoid it to save a lot of memory.
proc processModule*(module: PSym, filename: string, stream: PLLStream, 
                    rd: PRodReader)

# the semantic checker needs these:
var 
  gImportModule*: proc (filename: string): PSym
  gIncludeFile*: proc (filename: string): PNode

# implementation

proc skipCodegen*(n: PNode): bool {.inline.} = 
  # can be used by codegen passes to determine whether they should do 
  # something with `n`. Currently, this ignores `n` and uses the global
  # error count instead.
  result = msgs.gErrorCounter > 0

proc astNeeded*(s: PSym): bool = 
  # The ``rodwrite`` module uses this to determine if the body of a proc
  # needs to be stored. The passes manager frees s.sons[codePos] when
  # appropriate to free the procedure body's memory. This is important
  # to keep memory usage down.
  if (s.kind in {skMethod, skProc}) and
      ({sfCompilerProc, sfCompileTime} * s.flags == {}) and
      (s.typ.callConv != ccInline) and 
      (s.ast.sons[genericParamsPos].kind == nkEmpty): 
    result = semthreads.needsGlobalAnalysis()
  else:
    result = true
  
const 
  maxPasses = 10

type 
  TPassContextArray = array[0..maxPasses - 1, PPassContext]

var 
  gPasses: array[0..maxPasses - 1, TPass]
  gPassesLen: int

proc registerPass(p: TPass) = 
  gPasses[gPassesLen] = p
  inc(gPassesLen)

proc newPassComm(): PPassComm =
  new(result)
  result.optimizers = @[]

proc openPasses(a: var TPassContextArray, module: PSym, filename: string) = 
  var comm = newPassComm()
  for i in countup(0, gPassesLen - 1): 
    if not isNil(gPasses[i].open): 
      a[i] = gPasses[i].open(module, filename)
      if a[i] != nil: a[i].comm = comm
    else: a[i] = nil
  
proc openPassesCached(a: var TPassContextArray, module: PSym, filename: string, 
                      rd: PRodReader) = 
  var comm = newPassComm()
  for i in countup(0, gPassesLen - 1): 
    if not isNil(gPasses[i].openCached): 
      a[i] = gPasses[i].openCached(module, filename, rd)
      if a[i] != nil: 
        a[i].comm = comm
        a[i].fromCache = true
    else:
      a[i] = nil
  
proc closePasses(a: var TPassContextArray) = 
  var m: PNode = nil
  for i in countup(0, gPassesLen - 1): 
    if not isNil(gPasses[i].close): m = gPasses[i].close(a[i], m)
    a[i] = nil                # free the memory here
  
proc processTopLevelStmt(n: PNode, a: var TPassContextArray) = 
  # this implements the code transformation pipeline
  var m = n
  for i in countup(0, gPassesLen - 1): 
    if not isNil(gPasses[i].process): m = gPasses[i].process(a[i], m)
  
proc processTopLevelStmtCached(n: PNode, a: var TPassContextArray) = 
  # this implements the code transformation pipeline
  var m = n
  for i in countup(0, gPassesLen - 1): 
    if not isNil(gPasses[i].openCached): m = gPasses[i].process(a[i], m)
  
proc closePassesCached(a: var TPassContextArray) = 
  var m: PNode = nil
  for i in countup(0, gPassesLen - 1): 
    if not isNil(gPasses[i].openCached) and not isNil(gPasses[i].close): 
      m = gPasses[i].close(a[i], m)
    a[i] = nil                # free the memory here
  
proc processModule(module: PSym, filename: string, stream: PLLStream, 
                   rd: PRodReader) = 
  var 
    p: TParsers
    a: TPassContextArray
    s: PLLStream
  if rd == nil: 
    openPasses(a, module, filename)
    if stream == nil: 
      s = LLStreamOpen(filename, fmRead)
      if s == nil: 
        rawMessage(errCannotOpenFile, filename)
        return 
    else: 
      s = stream
    while true: 
      openParsers(p, filename, s)
      while true: 
        var n = parseTopLevelStmt(p)
        if n.kind == nkEmpty: break 
        processTopLevelStmt(n, a)
      closeParsers(p)
      if s.kind != llsStdIn: break 
    closePasses(a)
    # id synchronization point for more consistent code generation:
    IDsynchronizationPoint(1000)
  else: 
    openPassesCached(a, module, filename, rd)
    var n = loadInitSection(rd)
    for i in countup(0, sonsLen(n) - 1): processTopLevelStmtCached(n.sons[i], a)
    closePassesCached(a)

proc initPass(p: var TPass) = 
  p.open = nil
  p.openCached = nil
  p.close = nil
  p.process = nil
