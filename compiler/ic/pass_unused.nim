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
  ".."/[ast, passes, idents, msgs, options, pathutils,
  modulegraphs, astalgo],
  std/options as stdoptions

import
  store, packed_ast, contexts, to_packed_ast, from_packed_ast

type
  IncrementalRef* = ref object of PPassContext
    config: ConfigRef
    graph: ModuleGraph
    name: string
    s: PSym
    m: Module
    encoder: ref PackedEncoder      # avoid the refs when possible

proc available*(context: PPassContext): bool =
  if context == nil:
    result = false
  else:
    result = IncrementalRef(context).encoder == nil

proc rodFile(ic: IncrementalRef): AbsoluteFile =
  result = rodFile(ic.graph.config, ic.s)

proc opener(graph: ModuleGraph; s: PSym; idgen: IdGenerator): PPassContext =
  ## the opener discovers whether the module is available in IC
  when not defined(disruptic): return nil
  var ic = IncrementalRef(idgen: idgen, graph: graph, config: graph.config,
                          name: s.name.s, s: s)
  let maybe = tryReadModule(ic.config, ic.rodFile)
  if maybe.isSome:
    ic.m = get maybe
  else:
    ic.m = Module(name: ic.name)
    ic.m.ast.sh = Shared(config: ic.config)

    template iface: Iface = graph.ifaces[s.position]
    iface.encoder = (ref PackedEncoder)()
    initEncoder(iface.encoder[], s)

    when defined(disruptic):
      # hook the recordStmt() from the graph
      ic.graph.recordStmt = proc(g: ModuleGraph; m: PSym; n: PNode) {.nimcall.} =
        echo "record"
        debug n
        template iface: Iface = g.ifaces[m.position]
        toPackedNode(n, iface.tree, iface.encoder[])

    # retain the encoder; this also signifies rodfile write versus read
    ic.encoder = iface.encoder

  result = ic

proc processor(context: PPassContext, n: PNode): PNode =
  ## the processor merely returns the input if IC is unavailable
  var ic = IncrementalRef context
  if ic.available:
    result = nil
  else:
    # we now use recordStmt to pack the node; see opener()
    result = n

template performCaching*(context: PPassContext, n: PNode; body: untyped) =
  ## wraps a sem call to stow the result; presumed useful in future
  var ic = IncrementalRef context
  if ic.available:
    result = nil
  else:
    body

proc addGeneric*(context: PPassContext, s: PSym; types: seq[PType]) =
  ## add a generic
  when defined(disruptic):
    var ic = IncrementalRef context
    assert not ic.available
    let key = initGenericKey(s, types)
    addGeneric(ic.m, ic.encoder[], key, s)

proc closer(graph: ModuleGraph; context: PPassContext, n: PNode): PNode =
  ## the closer writes the module to a rodfile if necessary, and parses
  ## the packed ast in any event
  result = n
  var ic = IncrementalRef context
  if ic.available:
    when false:
      template iface: Iface = graph.ifaces[ic.s.position]

      # the result is immediately parsed from the rodfile
      var decoder: PackedDecoder
      initDecoder(decoder, graph.cache, makeResolver graph)
      result = irToModule(iface.tree, ic.s, decoder)
  else:
    when defined(disruptic):
      if not tryWriteModule(ic.m, ic.rodFile):
        # XXX: turn this into a warning
        internalError(graph.config, "failed to write " & ic.name & " rod file")

const icPass* = makePass(open = opener, process = processor, close = closer)
