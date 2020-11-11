#
#
#           The Nim Compiler
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## incremental compilation as a compiler pass run inside sem

import
  ast, passes, idents, msgs, options, lineinfos, pathutils,
  std/options as stdoptions

import ic/[ store, packed_ast, to_packed_ast, from_packed_ast ]

from modulegraphs import ModuleGraph, PPassContext

type
  IncrementalRef* = ref object of PPassContext
    config: ConfigRef
    graph: ModuleGraph
    name: string
    s: PSym
    m: Option[Module]

proc rodFile(ic: IncrementalRef): AbsoluteFile =
  result = AbsoluteFile toFullPath(ic.config, ic.s.info.fileIndex)
  result = result.changeFileExt "rod"

proc opener(graph: ModuleGraph; s: PSym; idgen: IdGenerator): PPassContext =
  var ic = IncrementalRef(idgen: idgen, graph: graph, config: graph.config,
                          name: s.name.s, s: s)
  ic.m = tryReadModule(graph.config, ic.rodFile)
  if ic.m.isSome:
    echo "🔵" & ic.name
  else:
    echo "🟡" & ic.name
  result = ic

proc processor(context: PPassContext, n: PNode): PNode =
  var ic = IncrementalRef(context)
  if ic.m.isSome:
    discard "🟣" & ic.name
  else:
    discard "🟠" & ic.name
    result = n

proc closer(graph: ModuleGraph; context: PPassContext, n: PNode): PNode =
  var ic = IncrementalRef(context)
  var m = Module(name: ic.name)
  m.ast.sh = Shared(config: ic.config)
  moduleToIr(n, m.ast, ic.s)
  if ic.m.isSome:
    if hash(m) == hash(get ic.m):
      echo "🟢" & ic.name
      m = get ic.m
    else:
      echo "🔴" & ic.name
  else:
    if tryWriteModule(m, ic.rodFile):
      echo "⚪" & ic.name
    else:
      echo "💣" & ic.name
      internalError(graph.config, "failed to write " & ic.name & " rod file")
  result = irToModule(m.ast, graph, ic.s)

const icPass* = makePass(open = opener, process = processor, close = closer)
