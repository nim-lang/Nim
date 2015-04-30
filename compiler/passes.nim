#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements the passes functionality. A pass must implement the
# `TPass` interface.

import
  strutils, lists, options, ast, astalgo, llstream, msgs, platform, os,
  condsyms, idents, renderer, types, extccomp, math, magicsys, nversion,
  nimsets, syntaxes, times, rodread, idgen

type
  TPassContext* = object of RootObj # the pass's context
    fromCache*: bool  # true if created by "openCached"

  PPassContext* = ref TPassContext

  TPassOpen* = proc (module: PSym): PPassContext {.nimcall.}
  TPassOpenCached* =
    proc (module: PSym, rd: PRodReader): PPassContext {.nimcall.}
  TPassClose* = proc (p: PPassContext, n: PNode): PNode {.nimcall.}
  TPassProcess* = proc (p: PPassContext, topLevelStmt: PNode): PNode {.nimcall.}

  TPass* = tuple[open: TPassOpen, openCached: TPassOpenCached,
                 process: TPassProcess, close: TPassClose]

  TPassData* = tuple[input: PNode, closeOutput: PNode]
  TPasses* = openArray[TPass]

# a pass is a tuple of procedure vars ``TPass.close`` may produce additional
# nodes. These are passed to the other close procedures.
# This mechanism used to be used for the instantiation of generics.

proc makePass*(open: TPassOpen = nil,
               openCached: TPassOpenCached = nil,
               process: TPassProcess = nil,
               close: TPassClose = nil): TPass =
  result.open = open
  result.openCached = openCached
  result.close = close
  result.process = process

  # This implements a memory preserving scheme: Top level statements are
  # processed in a pipeline. The compiler never looks at a whole module
  # any longer. However, this is simple to change, as new passes may perform
  # whole program optimizations. For now, we avoid it to save a lot of memory.
proc processModule*(module: PSym, stream: PLLStream, rd: PRodReader)

# the semantic checker needs these:
var
  gImportModule*: proc (m: PSym, fileIdx: int32): PSym {.nimcall.}
  gIncludeFile*: proc (m: PSym, fileIdx: int32): PNode {.nimcall.}

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
    result = false
    # XXX this doesn't really make sense with excessive CTFE
  else:
    result = true

const
  maxPasses = 10

type
  TPassContextArray = array[0..maxPasses - 1, PPassContext]

var
  gPasses: array[0..maxPasses - 1, TPass]
  gPassesLen*: int

proc clearPasses* =
  gPassesLen = 0

proc registerPass*(p: TPass) =
  gPasses[gPassesLen] = p
  inc(gPassesLen)

proc carryPass*(p: TPass, module: PSym, m: TPassData): TPassData =
  var c = p.open(module)
  result.input = p.process(c, m.input)
  result.closeOutput = if p.close != nil: p.close(c, m.closeOutput)
                       else: m.closeOutput

proc carryPasses*(nodes: PNode, module: PSym, passes: TPasses) =
  var passdata: TPassData
  passdata.input = nodes
  for pass in passes:
    passdata = carryPass(pass, module, passdata)

proc openPasses(a: var TPassContextArray, module: PSym) =
  for i in countup(0, gPassesLen - 1):
    if not isNil(gPasses[i].open):
      a[i] = gPasses[i].open(module)
    else: a[i] = nil

proc openPassesCached(a: var TPassContextArray, module: PSym, rd: PRodReader) =
  for i in countup(0, gPassesLen - 1):
    if not isNil(gPasses[i].openCached):
      a[i] = gPasses[i].openCached(module, rd)
      if a[i] != nil:
        a[i].fromCache = true
    else:
      a[i] = nil

proc closePasses(a: var TPassContextArray) =
  var m: PNode = nil
  for i in countup(0, gPassesLen - 1):
    if not isNil(gPasses[i].close): m = gPasses[i].close(a[i], m)
    a[i] = nil                # free the memory here

proc processTopLevelStmt(n: PNode, a: var TPassContextArray): bool =
  # this implements the code transformation pipeline
  var m = n
  for i in countup(0, gPassesLen - 1):
    if not isNil(gPasses[i].process):
      m = gPasses[i].process(a[i], m)
      if isNil(m): return false
  result = true

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

proc processImplicits(implicits: seq[string], nodeKind: TNodeKind,
                      a: var TPassContextArray) =
  for module in items(implicits):
    var importStmt = newNodeI(nodeKind, gCmdLineInfo)
    var str = newStrNode(nkStrLit, module)
    str.info = gCmdLineInfo
    importStmt.addSon str
    if not processTopLevelStmt(importStmt, a): break

proc processModule(module: PSym, stream: PLLStream, rd: PRodReader) =
  var
    p: TParsers
    a: TPassContextArray
    s: PLLStream
    fileIdx = module.fileIdx
  if rd == nil:
    openPasses(a, module)
    if stream == nil:
      let filename = fileIdx.toFullPathConsiderDirty
      if module.name.s == "-":
        module.name.s = "stdinfile"
        s = llStreamOpen(stdin)
      else:
        s = llStreamOpen(filename, fmRead)
      if s == nil:
        rawMessage(errCannotOpenFile, filename)
        return
    else:
      s = stream
    while true:
      openParsers(p, fileIdx, s)

      if sfSystemModule notin module.flags:
        # XXX what about caching? no processing then? what if I change the
        # modules to include between compilation runs? we'd need to track that
        # in ROD files. I think we should enable this feature only
        # for the interactive mode.
        processImplicits implicitImports, nkImportStmt, a
        processImplicits implicitIncludes, nkIncludeStmt, a

      while true:
        var n = parseTopLevelStmt(p)
        if n.kind == nkEmpty: break
        if not processTopLevelStmt(n, a): break

      closeParsers(p)
      if s.kind != llsStdIn: break
    closePasses(a)
    # id synchronization point for more consistent code generation:
    idSynchronizationPoint(1000)
  else:
    openPassesCached(a, module, rd)
    var n = loadInitSection(rd)
    for i in countup(0, sonsLen(n) - 1): processTopLevelStmtCached(n.sons[i], a)
    closePassesCached(a)

