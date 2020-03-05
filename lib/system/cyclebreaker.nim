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
const
  colGreen = 0b000
  colYellow = 0b001
  colRed = 0b010
  rcShift = 3      # shift by rcShift to get the reference counter
  colorMask = 0b011

type
  TraceProc = proc (p, env: pointer) {.nimcall, benign.}
  DisposeProc = proc (p: pointer) {.nimcall, benign.}

template color(c): untyped = c.rc and colorMask
template setColor(c, col) =
  when col == colGreen:
    c.rc = c.rc and not colorMask
  else:
    c.rc = c.rc and not colorMask or col

proc nimIncRefCyclic(p: pointer) {.compilerRtl, inl.} =
  let h = head(p)
  inc h.rc, rcIncrement

type
  CellTuple = (ptr pointer, PNimType)
  CellArray = ptr UncheckedArray[CellTuple]
  CellSeq = object
    len, cap: int
    d: CellArray

  GcEnv = object
    traceStack: CellSeq

# ------------------- cell seq handling --------------------------------------

proc add(s: var CellSeq, c: ptr pointer; t: PNimType) {.inline.} =
  if s.len >= s.cap:
    s.cap = s.cap * 3 div 2
    when defined(useMalloc):
      var d = cast[CellArray](c_malloc(uint(s.cap * sizeof(CellTuple))))
    else:
      var d = cast[CellArray](alloc(s.cap * sizeof(CellTuple)))
    copyMem(d, s.d, s.len * sizeof(CellTuple))
    when defined(useMalloc):
      c_free(s.d)
    else:
      dealloc(s.d)
    s.d = d
    # XXX: realloc?
  s.d[s.len] = (c, t)
  inc(s.len)

proc init(s: var CellSeq, cap: int = 1024) =
  s.len = 0
  s.cap = cap
  when defined(useMalloc):
    s.d = cast[CellArray](c_malloc(uint(s.cap * sizeof(CellTuple))))
  else:
    s.d = cast[CellArray](alloc(s.cap * sizeof(CellTuple)))

proc deinit(s: var CellSeq) =
  when defined(useMalloc):
    c_free(s.d)
  else:
    dealloc(s.d)
  s.d = nil
  s.len = 0
  s.cap = 0

proc pop(s: var CellSeq): (ptr pointer, PNimType) =
  result = s.d[s.len-1]
  dec s.len

# ----------------------------------------------------------------------------

proc trace(p: pointer; desc: PNimType; j: var GcEnv) {.inline.} =
  if desc.traceImpl != nil:
    cast[TraceProc](desc.traceImpl)(p, addr(j))

proc nimTraceRef(p: ptr pointer; desc: PNimType; env: pointer) {.compilerRtl.} =
  if p[] != nil:
    var j = cast[ptr GcEnv](env)
    j.traceStack.add(p, desc)

proc nimTraceRefDyn(p: ptr pointer; env: pointer) {.compilerRtl.} =
  if p[] != nil:
    let desc = cast[ptr PNimType](p)[]
    var j = cast[ptr GcEnv](env)
    j.traceStack.add(p, desc)

proc breakCycles(s: Cell; desc: PNimType) =
  var j: GcEnv
  init j.traceStack
  s.setColor colRed
  var p = s +! sizeof(RefHeader)
  trace(p, desc, j)
  while j.traceStack.len > 0:
    let (u, desc) = j.traceStack.pop()
    let p = u[]
    let t = head(p)
    if t.color != colRed:
      t.setColor colRed
      trace(p, desc, j)
    else:
      if (t.rc shr rcShift) > 0:
        cprintf("[YES!] %p\n", t)
        dec t.rc, rcIncrement
      else:
        cprintf("[Come on!] %p\n", t)
      u[] = nil
  deinit j.traceStack

proc spanningTree*[T](x: ref T) {.inline.} =
  ## turn the subgraph starting with `x` into its spanning tree by
  ## `nil`'ing out any pointers that would harm the spanning tree
  ## structure. Any back pointers that introduced cycles
  ## and thus would keep the graph from being freed are `nil`'ed.
  ## This is a form of cycle collection that works well with Nim's ARC
  ## and its associated cost model.
  proc getTypeInfo[T](x: T): PNimType {.magic: "GetTypeInfo", noSideEffect, locks: 0.}

  breakCycles(head(cast[pointer](x)), getTypeInfo(x[]))
  # XXX Use the dynamic type for this!

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

proc nimDecRefIsLastCyclicStatic(p: pointer; desc: PNimType): bool {.compilerRtl, inl.} =
  if p != nil:
    var cell = head(p)
    if (cell.rc and not rcMask) == 0:
      result = true
      #cprintf("[DESTROY] %p %s\n", p, desc.name)
    else:
      dec cell.rc, rcIncrement
      #cprintf("[DeCREF] %p %s %ld\n", p, desc.name, cell.rc)
