#
#
#           The Nim Compiler
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## incremental compilation passes

import
  ".."/[ast, passes, idents, msgs, options, lineinfos, pathutils,
  modulegraphs, astalgo],
  std/[sequtils, hashes],
  std/options as stdoptions

import
  store, packed_ast, to_packed_ast, from_packed_ast

type
  IncrementalRef* = ref object of PPassContext
    config: ConfigRef
    graph: ModuleGraph
    name: string
    s: PSym
    m: Option[Module]

proc rodFile(ic: IncrementalRef): AbsoluteFile =
  result = rodFile(ic.graph.config, ic.s)

proc opener(graph: ModuleGraph; s: PSym; idgen: IdGenerator): PPassContext =
  var ic = IncrementalRef(idgen: idgen, graph: graph, config: graph.config,
                          name: s.name.s, s: s)
  ic.m = tryReadModule(graph.config, ic.rodFile)
  result = ic

proc processor(context: PPassContext, n: PNode): PNode =
  var ic = IncrementalRef(context)
  if ic.m.isNone:
    result = n

proc closer(graph: ModuleGraph; context: PPassContext, n: PNode): PNode =
  var ic = IncrementalRef(context)
  var m = Module(name: ic.name)
  m.ast.sh = Shared(config: ic.config)
  moduleToIr(n, m.ast, ic.s)
  if ic.m.isSome:
    m = get ic.m
  else:
    if not tryWriteModule(m, ic.rodFile):
      internalError(graph.config, "failed to write " & ic.name & " rod file")
  proc resolver(id: int32; s: string): PSym =
    {.warning: "impl this".}
    echo "resolve"
    discard

  # the result is immediately parsed from the rodfile
  var decoder: PackedDecoder
  initDecoder(decoder, graph.cache, resolver)
  result = irToModule(m.ast, ic.s, decoder)

const icPass* = makePass(open = opener, process = processor, close = closer)
