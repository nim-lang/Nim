#
#
#           The Nim Compiler
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## incremental compilation interface

import
  ast, passes, idents, msgs, options, lineinfos, pathutils,
  modulegraphs, astalgo,
  std/[sequtils, hashes],
  std/options as stdoptions

import ic/[ store, packed_ast, to_packed_ast, from_packed_ast ]

type
  IncrementalRef* = ref object of PPassContext
    config: ConfigRef
    graph: ModuleGraph
    name: string
    s: PSym
    m: Option[Module]

proc rodFile(g: ModuleGraph; m: PSym): AbsoluteFile =
  result = AbsoluteFile toFullPath(g.config, m.info.fileIndex)
  result = result.changeFileExt "rod"

proc rodFile(ic: IncrementalRef): AbsoluteFile =
  result = rodFile(ic.graph, ic.s)

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
  result = irToModule(m.ast, graph, ic.s)

const icPass* {.deprecated.} =
  makePass(open = opener, process = processor, close = closer)

proc initIface*(g: ModuleGraph; iface: var Iface; s: PSym) =
  ## try to initialize the iface with an available rodfile
  if iface.state == ifaceUninitialized:
    let m = tryReadModule(g.config, rodFile(g, s))
    iface.state =
      if m.isNone:
        ifaceUnloaded
      else:
        # XXX:
        # for now, we unpack all the symbols at once; the rational here
        # is that we don't currently store the packed ast and the churn
        # from lazily performing the i/o is far worse than simply doing
        # the complete unpack into psyms.
        # NOTE:
        # if we later retain the packed ast in memory, then it will make
        # more sense to lazily unpack each symbol on demand, add lazy load
        # of proc bodies, and so on...
        iface.patterns = unpackAllSymbols((get m).ast, g, s)
        iface.converters = iface.patterns.filterIt: it.kind == skConverter
        ifaceLoaded

proc icReady*(g: ModuleGraph; s: PSym): bool =
  ## true if we are prepared to yield symbols from cache, for module `s`
  var iface = g.ifaces[s.position]
  initIface(g, iface, s)
  result = iface.state == ifaceLoaded

proc nextIdentIter*(it: var TIdentIter; g: ModuleGraph; m: PSym): PSym =
  ## replicate the existing iterator semantics for the iface cache
  var iface = g.ifaces[m.position]
  if iface.state == ifaceLoaded:
    for i, s in pairs iface.patterns[1 + it.h.int .. ^1]:
      if s.name.s == it.name.s:
        it.name = s.name
        it.h = i.Hash
        return s
  else:
    result = nextIdentIter(it, iface)

proc initIdentIter*(it: var TIdentIter; g: ModuleGraph; m: PSym;
                    name: PIdent): PSym =
  ## replicate the existing iterator semantics for the iface cache
  var iface = g.ifaces[m.position]
  initIface(g, iface, m)
  if iface.state == ifaceLoaded:
    it.name = name
    it.h = 0.Hash
    result = nextIdentIter(it, g, m)
  else:
    result = initIdentIter(it, iface, name)

proc firstSymbolNamed*(g: ModuleGraph; m: PSym; name: PIdent): PSym =
  ## return the first symbol matching the given name
  for s in moduleSymbols(g, m):
    if s.name.s == name.s:
      return s
