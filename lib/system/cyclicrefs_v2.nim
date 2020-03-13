#
#
#            Nim's Runtime Library
#        (c) Copyright 2019 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Cycle collector based on Lins' Jump Stack and other ideas,
# see for example:
# https://pdfs.semanticscholar.org/f2b2/0d168acf38ff86305809a55ef2c5d6ebc787.pdf
# Further refinement in 2008 by the notion of "critical links", see
# "Cyclic reference counting" by Rafael Dueire Lins
# R.D. Lins / Information Processing Letters 109 (2008) 71–78

const
  colGreen = 0b000
  colYellow = 0b001
  colRed = 0b010
  jumpStackFlag = 0b100  # stored in jumpstack
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
  h.setColor colYellow # mark as potential cycle!

proc markCyclic*[T](x: ref T) {.inline.} =
  ## Mark the underlying object as a candidate for cycle collections.
  ## Experimental API. Do not use!
  let h = head(cast[pointer](x))
  h.setColor colYellow
type
  CellTuple = (Cell, PNimType)
  CellArray = ptr UncheckedArray[CellTuple]
  CellSeq = object
    len, cap: int
    d: CellArray

  GcEnv = object
    traceStack: CellSeq
    jumpStack: CellSeq

# ------------------- cell seq handling --------------------------------------

proc add(s: var CellSeq, c: Cell; t: PNimType) {.inline.} =
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

proc pop(s: var CellSeq): (Cell, PNimType) =
  result = s.d[s.len-1]
  dec s.len

# ----------------------------------------------------------------------------

proc trace(s: Cell; desc: PNimType; j: var GcEnv) {.inline.} =
  if desc.traceImpl != nil:
    var p = s +! sizeof(RefHeader)
    cast[TraceProc](desc.traceImpl)(p, addr(j))

proc free(s: Cell; desc: PNimType) {.inline.} =
  when traceCollector:
    cprintf("[From ] %p rc %ld color %ld in jumpstack %ld\n", s, s.rc shr rcShift,
            s.color, s.rc and jumpStackFlag)
  var p = s +! sizeof(RefHeader)
  if desc.disposeImpl != nil:
    cast[DisposeProc](desc.disposeImpl)(p)
  nimRawDispose(p)

proc collect(s: Cell; desc: PNimType; j: var GcEnv) =
  if s.color == colRed:
    s.setColor colGreen
    trace(s, desc, j)
    while j.traceStack.len > 0:
      let (t, desc) = j.traceStack.pop()
      if t.color == colRed:
        t.setColor colGreen
        trace(t, desc, j)
        free(t, desc)
    free(s, desc)
    #cprintf("[Cycle free] %p %ld\n", s, s.rc shr rcShift)

proc markRed(s: Cell; desc: PNimType; j: var GcEnv) =
  if s.color != colRed:
    s.setColor colRed
    trace(s, desc, j)
    while j.traceStack.len > 0:
      let (t, desc) = j.traceStack.pop()
      when traceCollector:
        cprintf("[Cycle dec] %p %ld color %ld in jumpstack %ld\n", t, t.rc shr rcShift, t.color, t.rc and jumpStackFlag)
      dec t.rc, rcIncrement
      if (t.rc and not rcMask) >= 0 and (t.rc and jumpStackFlag) == 0:
        t.rc = t.rc or jumpStackFlag
        when traceCollector:
          cprintf("[Now in jumpstack] %p %ld color %ld in jumpstack %ld\n", t, t.rc shr rcShift, t.color, t.rc and jumpStackFlag)
        j.jumpStack.add(t, desc)
      if t.color != colRed:
        t.setColor colRed
        trace(t, desc, j)

proc scanGreen(s: Cell; desc: PNimType; j: var GcEnv) =
  s.setColor colGreen
  trace(s, desc, j)
  while j.traceStack.len > 0:
    let (t, desc) = j.traceStack.pop()
    if t.color != colGreen:
      t.setColor colGreen
      trace(t, desc, j)
    inc t.rc, rcIncrement
    when traceCollector:
      cprintf("[Cycle inc] %p %ld color %ld\n", t, t.rc shr rcShift, t.color)

proc nimTraceRef(p: pointer; desc: PNimType; env: pointer) {.compilerRtl.} =
  if p != nil:
    var t = head(p)
    var j = cast[ptr GcEnv](env)
    j.traceStack.add(t, desc)

proc nimTraceRefDyn(p: pointer; env: pointer) {.compilerRtl.} =
  if p != nil:
    let desc = cast[ptr PNimType](p)[]
    var t = head(p)
    var j = cast[ptr GcEnv](env)
    j.traceStack.add(t, desc)

proc scan(s: Cell; desc: PNimType; j: var GcEnv) =
  when traceCollector:
    cprintf("[doScanGreen] %p %ld\n", s, s.rc shr rcShift)
  # even after trial deletion, `s` is still alive, so undo
  # the decrefs by calling `scanGreen`:
  if (s.rc and not rcMask) >= 0:
    scanGreen(s, desc, j)
    s.setColor colYellow
  else:
    # first we have to repair all the nodes we have seen
    # that are still alive; we also need to mark what they
    # refer to as alive:
    while j.jumpStack.len > 0:
      let (t, desc) = j.jumpStack.pop
      # not in jump stack anymore!
      t.rc = t.rc and not jumpStackFlag
      if t.color == colRed and (t.rc and not rcMask) >= 0:
        scanGreen(t, desc, j)
        t.setColor colYellow
        when traceCollector:
          cprintf("[jump stack] %p %ld\n", t, t.rc shr rcShift)
    # we have proven that `s` and its subgraph are dead, so we can
    # collect these nodes:
    collect(s, desc, j)

proc traceCycle(s: Cell; desc: PNimType) {.noinline.} =
  when traceCollector:
    cprintf("[traceCycle] %p %ld\n", s, s.rc shr rcShift)
  var j: GcEnv
  init j.jumpStack
  init j.traceStack
  markRed(s, desc, j)
  scan(s, desc, j)
  while j.jumpStack.len > 0:
    let (t, desc) = j.jumpStack.pop
    # not in jump stack anymore!
    t.rc = t.rc and not jumpStackFlag
  deinit j.jumpStack
  deinit j.traceStack

proc nimDecRefIsLastCyclicDyn(p: pointer): bool {.compilerRtl, inl.} =
  if p != nil:
    var cell = head(p)
    if (cell.rc and not rcMask) == 0:
      result = true
      #cprintf("[DESTROY] %p\n", p)
    else:
      dec cell.rc, rcIncrement
      if cell.color == colYellow:
        let desc = cast[ptr PNimType](p)[]
        traceCycle(cell, desc)
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
      if cell.color == colYellow: traceCycle(cell, desc)
      #cprintf("[DeCREF] %p %s %ld\n", p, desc.name, cell.rc)
