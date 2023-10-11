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

import ".." / [ast, modulegraphs, renderer, transf]
import nirtypes, nirinsts, ast2ir

type
  PCtx* = ref object of TPassContext
    m: ModuleCon
    c: ProcCon
    oldErrorCount: int

proc newCtx*(module: PSym; g: ModuleGraph; idgen: IdGenerator): PCtx =
  let m = initModuleCon(g, g.config, idgen, module)
  PCtx(m: m, c: initProcCon(m, nil, g.config), idgen: idgen)

proc refresh*(c: PCtx; module: PSym; idgen: IdGenerator) =
  c.m = initModuleCon(c.m.graph, c.m.graph.config, idgen, module)
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

  var res = ""
  if pc < c.c.code.len:
    toString c.c.code, NodePos(pc), c.m.strings, c.m.integers, res
  #res.add "\n"
  #toString res, c.m.types.g
  echo res


proc runCode*(c: PPassContext; n: PNode): PNode =
  let c = PCtx(c)
  # don't eval errornous code:
  if c.oldErrorCount == c.m.graph.config.errorCounter:
    evalStmt(c, n)
    result = newNodeI(nkEmpty, n.info)
  else:
    result = n
  c.oldErrorCount = c.m.graph.config.errorCounter

when false:
  type
    Module* = object
      types: TypeGraph
      data: seq[Tree]
      init: seq[Tree]
      procs: seq[Tree]

