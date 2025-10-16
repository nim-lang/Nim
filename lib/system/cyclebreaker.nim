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

when not declared(benign):
  {.pragma: benign.}
when not declared(compilerRtl):
  {.pragma: compilerRtl.}
when not declared(inl):
  {.pragma: inl.}

when not declared(traceCollector):
  const traceCollector = defined(nimTraceCollector)

when traceCollector:
  proc cprintf(fmt: cstring) {.importc: "printf", header: "<stdio.h>", varargs, discardable.}

when not declared(head):
  type RefHeader* = object
    rc: int
  template head(p: pointer): ptr RefHeader =
    cast[ptr RefHeader](cast[int](p) -% sizeof(RefHeader))

when not declared(Cell):
  type Cell = ptr RefHeader

template payloadPtr(c: Cell): pointer =
  cast[pointer](cast[int](c) +% sizeof(RefHeader))

when not declared(rcIncrement):
  when defined(gcOrc):
    const
      rcIncrement* = 0b10000
      rcMask* = 0b1111
      rcShift* = 4
  else:
    const
      rcIncrement* = 0b1000
      rcMask* = 0b111
      rcShift* = 3

when not declared(maybeCycleFlag):
  when declared(maybeCycle):
    const maybeCycleFlag = maybeCycle
  elif defined(gcOrc):
    const maybeCycleFlag = 0b100
  else:
    const maybeCycleFlag = 0

when not declared(nimRawDispose):
  proc nimRawDispose(p: pointer, alignment: int) {.importc: "nimRawDispose", raises: [].}

include cellseqs_v2

proc releaseGraph(p: pointer; desc: PNimTypeV2) {.gcsafe, raises: [].}

const
  colGreen = 0b000
  colYellow = 0b001
  colRed = 0b010
  colorMask = 0b011

when not declared(TraceProc):
  type TraceProc = proc (p, env: pointer) {.nimcall, benign, gcsafe, raises: [].}
when not declared(DisposeProc):
  type DisposeProc = proc (p: pointer) {.nimcall, benign, gcsafe, raises: [].}
when not declared(DestructorProc):
  type DestructorProc = proc (p: pointer) {.nimcall, benign, gcsafe, raises: [].}

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

proc trace(p: pointer; desc: PNimTypeV2; j: var GcEnv) {.inline, gcsafe, raises: [].} =
  when false:
    cprintf("[Trace] desc: %p %p\n", desc, p)
    cprintf("[Trace] trace: %p\n", desc.traceImpl)
  if desc.traceImpl != nil:
    cast[TraceProc](desc.traceImpl)(p, addr(j))

proc nimTraceRefImpl*(q: pointer; desc: PNimTypeV2; env: pointer) {.compilerRtl, gcsafe.} =
  let p = cast[ptr pointer](q)
  when traceCollector:
    cprintf("[Trace] raw: %p\n", p)
    cprintf("[Trace] deref: %p\n", p[])
  if p[] != nil:
    var j = cast[ptr GcEnv](env)
    j.traceStack.add(p, desc)

proc nimTraceRefDynImpl*(q: pointer; env: pointer) {.compilerRtl, gcsafe.} =
  let p = cast[ptr pointer](q)
  when traceCollector:
    cprintf("[TraceDyn] raw: %p\n", p)
    cprintf("[TraceDyn] deref: %p\n", p[])
  if p[] != nil:
    var j = cast[ptr GcEnv](env)
    j.traceStack.add(p, cast[ptr PNimTypeV2](p[])[])

when not declared(nimTraceClosure):
  proc nimTraceClosureImpl*(p, env: pointer) {.compilerRtl, nimcall, benign, gcsafe, raises: [].} =
    let slot = cast[ptr pointer](cast[int](p) +% sizeof(pointer))
    nimTraceRefImpl(slot, cast[ptr PNimTypeV2](slot[])[], env)

when not declared(nimTraceRef):
  proc nimTraceRef(q: pointer; desc: PNimTypeV2; env: pointer) {.compilerRtl, inline, gcsafe.} =
    nimTraceRefImpl(q, desc, env)

when not declared(nimTraceRefDyn):
  proc nimTraceRefDyn(q: pointer; env: pointer) {.compilerRtl, inline, gcsafe.} =
    nimTraceRefDynImpl(q, env)

var markerGeneration: int

proc breakCycles(s: Cell; desc: PNimTypeV2) {.gcsafe, raises: [].} =
  let markerColor = if (markerGeneration and 1) == 0: colRed
                    else: colYellow
  inc markerGeneration
  when traceCollector:
    cprintf("[BreakCycles] starting: %p desc=%p RC %ld trace proc %p\n",
      s, desc, s.rc shr rcShift, desc.traceImpl)

  var j: GcEnv
  init j.traceStack
  s.setColor markerColor
  when maybeCycleFlag != 0:
    s.rc = s.rc and not maybeCycleFlag
  trace(payloadPtr(s), desc, j)

  while j.traceStack.len > 0:
    let (u, desc) = j.traceStack.pop()
    let p = u[]
    let t = head(p)
    if t.color != markerColor:
      t.setColor markerColor
      when maybeCycleFlag != 0:
        t.rc = t.rc and not maybeCycleFlag
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
        when traceCollector:
          cprintf("[Bug] %p desc=%p RC %ld\n", t, desc, t.rc shr rcShift)
  deinit j.traceStack

proc thinout*[T](x: ref T) {.inline, gcsafe, raises: [].} =
  ## turn the subgraph starting with `x` into its spanning tree by
  ## `nil`'ing out any pointers that would harm the spanning tree
  ## structure. Any back pointers that introduced cycles
  ## and thus would keep the graph from being freed are `nil`'ed.
  ## This is a form of cycle collection that works well with Nim's ARC
  ## and its associated cost model.
  proc getDynamicTypeInfo[T](x: T): PNimTypeV2 {.magic: "GetTypeInfoV2", noSideEffect.}

  var desc: PNimTypeV2
  when declared(getDynamicTypeInfo):
    desc = getDynamicTypeInfo(x[])
  let dynDesc = cast[ptr PNimTypeV2](cast[pointer](x))[]
  if desc == nil:
    desc = dynDesc
  let ti = desc
  when defined(debugThinout):
    echo "[thinout ref] ptr=", cast[int](x), " desc=", cast[int](ti), " traceImpl=", cast[int](ti.traceImpl)
  releaseGraph(cast[pointer](x), ti)
  when not defined(gcOrc) or defined(nimThinout):
    breakCycles(head(cast[pointer](x)), ti)

proc thinout*[T: proc](x: T) {.inline, gcsafe, raises: [].} =
  proc rawEnv[T: proc](x: T): pointer {.noSideEffect, inline.} =
    {.emit: """
    `result` = `x`.ClE_0;
    """.}

  let p = rawEnv(x)
  let desc = cast[ptr PNimTypeV2](p)[]
  when defined(debugThinout):
    echo "[thinout] env=", cast[int](p), " typeInfo=", cast[int](desc), " traceImpl=", cast[int](desc.traceImpl)
  releaseGraph(p, desc)
  when not defined(gcOrc) or defined(nimThinout):
    breakCycles(head(p), desc)

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

proc releaseGraph(p: pointer; desc: PNimTypeV2) {.gcsafe, raises: [].} =
  if desc == nil or desc.traceImpl == nil: return
  var env: GcEnv
  init env.traceStack
  trace(p, desc, env)
  while env.traceStack.len > 0:
    let (slot, childDesc) = env.traceStack.pop()
    let child = slot[]
    if child != nil:
      slot[] = nil
      releaseGraph(child, childDesc)
      let cell = head(child)
      when maybeCycleFlag != 0:
        cell.rc = cell.rc and not maybeCycleFlag
      let isLast = nimDecRefIsLastCyclicStatic(child, childDesc)
      if isLast:
        if childDesc.destructor != nil:
          cast[DestructorProc](childDesc.destructor)(child)
        let disposer = cast[proc (p: pointer, alignment: int) {.nimcall, gcsafe, raises: [].}](nimRawDispose)
        disposer(child, childDesc.align)
  deinit env.traceStack
