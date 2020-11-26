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
  store, packed_ast, to_packed_ast, from_packed_ast

type
  IncrementalRef* = ref object of PPassContext
    config: ConfigRef
    graph: ModuleGraph
    name: string
    s: PSym
    m: Module
    encoder: ref PackedEncoder      # avoid the refs when possible

proc ready*(context: PPassContext): bool =
  var ic = IncrementalRef context
  result = ic.encoder == nil

proc rodFile(ic: IncrementalRef): AbsoluteFile =
  result = rodFile(ic.graph.config, ic.s)

proc opener(graph: ModuleGraph; s: PSym; idgen: IdGenerator): PPassContext =
  ## the opener discovers whether the module is available in IC
  var ic = IncrementalRef(idgen: idgen, graph: graph, config: graph.config,
                          name: s.name.s, s: s)
  let maybe = tryReadModule(ic.config, ic.rodFile)
  if maybe.isSome:
    ic.m = get maybe
  else:
    ic.m = Module(name: ic.name)
    ic.m.ast.sh = Shared(config: ic.config)
    ic.encoder = (ref PackedEncoder)(thisModule: s.itemId.module)
  result = ic

proc processor(context: PPassContext, n: PNode): PNode =
  ## the processor merely returns the input if IC is unavailable
  var ic = IncrementalRef context
  if ic.ready:
    result = nil
  else:
    toPackedNode(n, ic.m.ast, ic.encoder[])
    result = n

template performCaching*(context: PPassContext, n: PNode; body: untyped) =
  ## wraps a sem call to stow the result
  var ic = IncrementalRef context.ic
  if ic.ready:
    result = nil
  else:
    body
    toPackedNode(result, ic.m.ast, ic.encoder[])

proc addGeneric*(context: PPassContext, s: PSym; types: seq[PType]) =
  ## add a generic
  var ic = IncrementalRef context
  assert not ic.ready
  let key = initGenericKey(s, types)
  addGeneric(ic.m, ic.encoder[], key, s)

proc closer(graph: ModuleGraph; context: PPassContext, n: PNode): PNode =
  ## the closer writes the module to a rodfile if necessary, and parses
  ## the packed ast in any event
  var ic = IncrementalRef context
  if not ic.ready:
    if not tryWriteModule(ic.m, ic.rodFile):
      internalError(graph.config, "failed to write " & ic.name & " rod file")
    result = n
  else:
    # the result is immediately parsed from the rodfile
    var decoder: PackedDecoder
    initDecoder(decoder, graph.cache, makeResolver graph)
    result = irToModule(ic.m.ast, ic.s, decoder)
    echo "N"
    debug n
    echo "R"
    debug result

const icPass* = makePass(open = opener, process = processor, close = closer)
