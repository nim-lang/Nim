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
  when not defined(nimIcSem):
    body
  else:
    var ic = IncrementalRef context.ic
    if ic.ready:
      result = nil
    else:
      body
      toPackedNode(result, ic.m.ast, ic.encoder[])

proc closer(graph: ModuleGraph; context: PPassContext, n: PNode): PNode =
  ## the closer writes the module to a rodfile if necessary, and parses
  ## the packed ast in any event
  var ic = IncrementalRef context
  if ic.ready:
    if not tryWriteModule(ic.m, ic.rodFile):
      internalError(graph.config, "failed to write " & ic.name & " rod file")

  proc resolver(module: int32; name: string): PSym =
    let ident = getIdent(graph.cache, name)
    if module == PackageModuleId:
      result = strTableGet(graph.packageSyms, ident)
    else:
      block found:
        # we'll just do this stupidly for now
        for i in countup(0, graph.ifaces.high):
          template iface: Iface = graph.ifaces[i]
          if iface.module != nil:
            if iface.module.itemId.module == module:
              result = getExport(graph, iface.module, ident)
              break found
        internalError(graph.config, "unable to resolve module " & $module)
    if result == nil:
      internalError(graph.config, "unable to retrieve " & name)

  # the result is immediately parsed from the rodfile
  var decoder: PackedDecoder
  initDecoder(decoder, graph.cache, resolver)
  result = irToModule(ic.m.ast, ic.s, decoder)

const icPass* = makePass(open = opener, process = processor, close = closer)
