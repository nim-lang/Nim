#
#
#            Nim's Runtime Library
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

#[
A Cycle breaker for Nim
-----------------------

Instead of "collecting" cycles with all of its pitfalls we will break cycles.
We exploit that every 'ref' can be 'nil' for this and so get away without
a distinction between weak and strong pointers. The required runtime
mechanisms are the same though: We need to be able to traverse the graph.
This design has the tremendous benefit that it doesn't require a dedicated
'rawDispose' operation and that it plays well with Nim's cost model.
The cost of freeing a subgraph with cycles is 2 * N rather than N, that's all.

Cycles do not have to be prepared via .acyclic, there are not multiple
pointless traversals, only a single proc, `breakCycles` is exposed as a
separate module.

Algorithm
---------

We traverse the graph and notice the nodes we've already traversed. If we
marked the node already, we set the pointer that leads to this node to 'nil'
and decrement the reference count of the cell we pointed at.

We notice that multiple paths to the same object do not mean
we found a cycle, it only means the node is shared.


   a -------> b <----- c
   |          ^        ^
   +----------+        |
   |                   |
   +-------------------+

If we simply remove all links to already processed nodes we end up with:

   a -------> b        c
   |                   ^
   +                   |
   |                   |
   +-------------------+

That seems acceptable, no leak is produced. This implies that the standard
depth-first traversal suffices.

]#

include cellseqs_v2

const
  colGreen = 0b000
  colYellow = 0b001
  colRed = 0b010
  colorMask = 0b011

type
  TraceProc = proc (p, env: pointer) {.nimcall, benign.}
  DisposeProc = proc (p: pointer) {.nimcall, benign.}

template color(c): untyped = c.rc and colorMask
template setColor(c, col) =
  c.rc = c.rc and not colorMask or col

proc nimIncRefCyclic(p: pointer; cyclic: bool) {.compilerRtl, inl.} =
  let h = head(p)
  inc h.rc, rcIncrement

proc nimMarkCyclic(p: pointer) {.compilerRtl, inl.} = discard

type
  GcEnv = object
    traceStack: CellSeq[ptr pointer]

proc trace(p: pointer; desc: PNimTypeV2; j: var GcEnv) {.inline.} =
  when false:
    cprintf("[Trace] desc: %p %p\n", desc, p)
    cprintf("[Trace] trace: %p\n", desc.traceImpl)
  if desc.traceImpl != nil:
    cast[TraceProc](desc.traceImpl)(p, addr(j))

proc nimTraceRef(q: pointer; desc: PNimTypeV2; env: pointer) {.compilerRtl.} =
  let p = cast[ptr pointer](q)
  when traceCollector:
    cprintf("[Trace] raw: %p\n", p)
    cprintf("[Trace] deref: %p\n", p[])
  if p[] != nil:
    var j = cast[ptr GcEnv](env)
    j.traceStack.add(p, desc)

proc nimTraceRefDyn(q: pointer; env: pointer) {.compilerRtl.} =
  let p = cast[ptr pointer](q)
  when traceCollector:
    cprintf("[TraceDyn] raw: %p\n", p)
    cprintf("[TraceDyn] deref: %p\n", p[])
  if p[] != nil:
    var j = cast[ptr GcEnv](env)
    j.traceStack.add(p, cast[ptr PNimTypeV2](p[])[])

var markerGeneration: int

proc breakCycles(s: Cell; desc: PNimTypeV2) =
  let markerColor = if (markerGeneration and 1) == 0: colRed
                    else: colYellow
  atomicInc markerGeneration
  when traceCollector:
    cprintf("[BreakCycles] starting: %p %s RC %ld trace proc %p\n",
      s, desc.name, s.rc shr rcShift, desc.traceImpl)

  var j: GcEnv
  init j.traceStack
  s.setColor markerColor
  trace(s +! sizeof(RefHeader), desc, j)

  while j.traceStack.len > 0:
    let (u, desc) = j.traceStack.pop()
    let p = u[]
    let t = head(p)
    if t.color != markerColor:
      t.setColor markerColor
      trace(p, desc, j)
      when traceCollector:
        cprintf("[BreakCycles] followed: %p RC %ld\n", t, t.rc shr rcShift)
    else:
      if (t.rc shr rcShift) > 0:
        dec t.rc, rcIncrement
        # mark as a link that the produced destructor does not have to follow:
        u[] = nil
        when traceCollector:
          cprintf("[BreakCycles] niled out: %p RC %ld\n", t, t.rc shr rcShift)
      else:
        # anyhow as a link that the produced destructor does not have to follow:
        u[] = nil
        cprintf("[Bug] %p %s RC %ld\n", t, desc.name, t.rc shr rcShift)
  deinit j.traceStack

proc thinout*[T](x: ref T) {.inline.} =
  ## turn the subgraph starting with `x` into its spanning tree by
  ## `nil`'ing out any pointers that would harm the spanning tree
  ## structure. Any back pointers that introduced cycles
  ## and thus would keep the graph from being freed are `nil`'ed.
  ## This is a form of cycle collection that works well with Nim's ARC
  ## and its associated cost model.
  proc getDynamicTypeInfo[T](x: T): PNimTypeV2 {.magic: "GetTypeInfoV2", noSideEffect, locks: 0.}

  breakCycles(head(cast[pointer](x)), getDynamicTypeInfo(x[]))

proc thinout*[T: proc](x: T) {.inline.} =
  proc rawEnv[T: proc](x: T): pointer {.noSideEffect, inline.} =
    {.emit: """
    `result` = `x`.ClE_0;
    """.}

  let p = rawEnv(x)
  breakCycles(head(p), cast[ptr PNimTypeV2](p)[])

proc nimDecRefIsLastCyclicDyn(p: pointer): bool {.compilerRtl, inl.} =
  if p != nil:
    var cell = head(p)
    if (cell.rc and not rcMask) == 0:
      result = true
      #cprintf("[DESTROY] %p\n", p)
    else:
      dec cell.rc, rcIncrement
      # According to Lins it's correct to do nothing else here.
      #cprintf("[DeCREF] %p\n", p)

proc nimDecRefIsLastCyclicStatic(p: pointer; desc: PNimTypeV2): bool {.compilerRtl, inl.} =
  if p != nil:
    var cell = head(p)
    if (cell.rc and not rcMask) == 0:
      result = true
      #cprintf("[DESTROY] %p %s\n", p, desc.name)
    else:
      dec cell.rc, rcIncrement
      #cprintf("[DeCREF] %p %s %ld\n", p, desc.name, cell.rc)
