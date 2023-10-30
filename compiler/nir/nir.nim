#
#
#           The Nim Compiler
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Nim Intermediate Representation, designed to capture all of Nim's semantics without losing too much
## precious information. Can easily be translated into C. And to JavaScript, hopefully.

from std/os import addFileExt, `/`, createDir

import std / assertions
import ".." / [ast, modulegraphs, renderer, transf, options, msgs, lineinfos]
import nirtypes, nirinsts, ast2ir, nirlineinfos, nirfiles, nirvm

import ".." / ic / [rodfiles, bitabs]

type
  PCtx* = ref object of TPassContext
    m: ModuleCon
    c: ProcCon
    oldErrorCount: int
    bytecode: Bytecode

proc newCtx*(module: PSym; g: ModuleGraph; idgen: IdGenerator): PCtx =
  var lit = Literals()
  var nirm = (ref NirModule)(types: initTypeGraph(lit), lit: lit)
  var m = initModuleCon(g, g.config, idgen, module, nirm)
  m.noModularity = true
  PCtx(m: m, c: initProcCon(m, nil, g.config), idgen: idgen, bytecode: initBytecode(nirm))

proc refresh*(c: PCtx; module: PSym; idgen: IdGenerator) =
  #c.m = initModuleCon(c.m.graph, c.m.graph.config, idgen, module, c.m.nirm)
  #c.m.noModularity = true
  c.c = initProcCon(c.m, nil, c.m.graph.config)
  c.idgen = idgen

proc setupGlobalCtx*(module: PSym; graph: ModuleGraph; idgen: IdGenerator) =
  if graph.repl.isNil:
    graph.repl = newCtx(module, graph, idgen)
    #registerAdditionalOps(PCtx graph.repl)
  else:
    refresh(PCtx graph.repl, module, idgen)

proc setupNirReplGen*(graph: ModuleGraph; module: PSym; idgen: IdGenerator): PPassContext =
  setupGlobalCtx(module, graph, idgen)
  result = PCtx graph.repl

proc evalStmt(c: PCtx; n: PNode) =
  let n = transformExpr(c.m.graph, c.idgen, c.m.module, n)
  let pc = genStmt(c.c, n)
  #var res = ""
  #toString c.m.nirm.code, NodePos(pc), c.m.nirm.lit.strings, c.m.nirm.lit.numbers, c.m.symnames, res
  #res.add "\n--------------------------\n"
  #toString res, c.m.types.g
  if pc.int < c.m.nirm.code.len:
    execCode c.bytecode, c.m.nirm.code, pc
  #echo res

proc runCode*(c: PPassContext; n: PNode): PNode =
  let c = PCtx(c)
  # don't eval errornous code:
  if c.oldErrorCount == c.m.graph.config.errorCounter:
    evalStmt(c, n)
    result = newNodeI(nkEmpty, n.info)
  else:
    result = n
  c.oldErrorCount = c.m.graph.config.errorCounter

type
  NirPassContext* = ref object of TPassContext
    m: ModuleCon
    c: ProcCon

proc openNirBackend*(g: ModuleGraph; module: PSym; idgen: IdGenerator): PPassContext =
  var lit = Literals()
  var nirm = (ref NirModule)(types: initTypeGraph(lit), lit: lit)
  let m = initModuleCon(g, g.config, idgen, module, nirm)
  NirPassContext(m: m, c: initProcCon(m, nil, g.config), idgen: idgen)

proc gen(c: NirPassContext; n: PNode) =
  let n = transformExpr(c.m.graph, c.idgen, c.m.module, n)
  let pc = genStmt(c.c, n)

proc nirBackend*(c: PPassContext; n: PNode): PNode =
  gen(NirPassContext(c), n)
  result = n

proc closeNirBackend*(c: PPassContext; finalNode: PNode) =
  discard nirBackend(c, finalNode)

  let c = NirPassContext(c)
  let nimcache = getNimcacheDir(c.c.config).string
  createDir nimcache
  let outp = nimcache / c.m.module.name.s.addFileExt("nir")
  #c.m.nirm.code = move c.c.code
  try:
    store c.m.nirm[], outp
    echo "created: ", outp
  except IOError:
    rawMessage(c.c.config, errFatal, "serialization failed: " & outp)
