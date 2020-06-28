#
#
#            Nim's Runtime Library
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Cycle collector based on
# https://researcher.watson.ibm.com/researcher/files/us-bacon/Bacon01Concurrent.pdf
# And ideas from Lins' in 2008 by the notion of "critical links", see
# "Cyclic reference counting" by Rafael Dueire Lins
# R.D. Lins / Information Processing Letters 109 (2008) 71–78
#

type PT = Cell
include cellseqs_v2

const
  colBlack = 0b000
  colGray = 0b001
  colWhite = 0b010
  colPurple = 0b011
  isCycleCandidate = 0b100 # cell is marked as a cycle candidate
  jumpStackFlag = 0b1000
  colorMask = 0b011

type
  TraceProc = proc (p, env: pointer) {.nimcall, benign.}
  DisposeProc = proc (p: pointer) {.nimcall, benign.}

template color(c): untyped = c.rc and colorMask
template setColor(c, col) =
  when col == colBlack:
    c.rc = c.rc and not colorMask
  else:
    c.rc = c.rc and not colorMask or col

proc nimIncRefCyclic(p: pointer) {.compilerRtl, inl.} =
  let h = head(p)
  inc h.rc, rcIncrement
  h.setColor colPurple # mark as potential cycle!

const
  useJumpStack = false # for thavlak the jump stack doesn't improve the performance at all

type
  GcEnv = object
    traceStack: CellSeq
    when useJumpStack:
      jumpStack: CellSeq   # Lins' jump stack in order to speed up traversals
    freed, touched: int

proc trace(s: Cell; desc: PNimType; j: var GcEnv) {.inline.} =
  if desc.traceImpl != nil:
    var p = s +! sizeof(RefHeader)
    cast[TraceProc](desc.traceImpl)(p, addr(j))

when true:
  template debug(str: cstring; s: Cell) = discard
else:
  proc debug(str: cstring; s: Cell) =
    let p = s +! sizeof(RefHeader)
    cprintf("[%s] name %s RC %ld\n", str, p, s.rc shr rcShift)

proc free(s: Cell; desc: PNimType) {.inline.} =
  when traceCollector:
    cprintf("[From ] %p rc %ld color %ld\n", s, s.rc shr rcShift, s.color)
  let p = s +! sizeof(RefHeader)

  debug("free", s)

  if desc.disposeImpl != nil:
    cast[DisposeProc](desc.disposeImpl)(p)
  nimRawDispose(p)

proc nimTraceRef(q: pointer; desc: PNimType; env: pointer) {.compilerRtl.} =
  let p = cast[ptr pointer](q)
  if p[] != nil:
    var j = cast[ptr GcEnv](env)
    j.traceStack.add(head p[], desc)

proc nimTraceRefDyn(q: pointer; env: pointer) {.compilerRtl.} =
  let p = cast[ptr pointer](q)
  if p[] != nil:
    var j = cast[ptr GcEnv](env)
    j.traceStack.add(head p[], cast[ptr PNimType](p[])[])

var
  roots {.threadvar.}: CellSeq

proc unregisterCycle(s: Cell) =
  # swap with the last element. O(1)
  let idx = s.rootIdx
  when false:
    if idx >= roots.len or idx < 0:
      cprintf("[Bug!] %ld\n", idx)
      quit 1
  roots.d[idx] = roots.d[roots.len-1]
  roots.d[idx][0].rootIdx = idx
  dec roots.len

proc scanBlack(s: Cell; desc: PNimType; j: var GcEnv) =
  #[
  proc scanBlack(s: Cell) =
    setColor(s, colBlack)
    for t in sons(s):
      t.rc = t.rc + rcIncrement
      if t.color != colBlack:
        scanBlack(t)
  ]#
  debug "scanBlack", s
  s.setColor colBlack
  trace(s, desc, j)
  while j.traceStack.len > 0:
    let (t, desc) = j.traceStack.pop()
    inc t.rc, rcIncrement
    debug "incRef", t
    if t.color != colBlack:
      t.setColor colBlack
      trace(t, desc, j)

proc markGray(s: Cell; desc: PNimType; j: var GcEnv) =
  #[
  proc markGray(s: Cell) =
    if s.color != colGray:
      setColor(s, colGray)
      for t in sons(s):
        t.rc = t.rc - rcIncrement
        if t.color != colGray:
          markGray(t)
  ]#
  if s.color != colGray:
    s.setColor colGray
    inc j.touched
    trace(s, desc, j)
    while j.traceStack.len > 0:
      let (t, desc) = j.traceStack.pop()
      dec t.rc, rcIncrement
      when useJumpStack:
        if (t.rc shr rcShift) >= 0 and (t.rc and jumpStackFlag) == 0:
          t.rc = t.rc or jumpStackFlag
          when traceCollector:
            cprintf("[Now in jumpstack] %p %ld color %ld in jumpstack %ld\n", t, t.rc shr rcShift, t.color, t.rc and jumpStackFlag)
          j.jumpStack.add(t, desc)
      if t.color != colGray:
        t.setColor colGray
        inc j.touched
        trace(t, desc, j)

proc scan(s: Cell; desc: PNimType; j: var GcEnv) =
  #[
  proc scan(s: Cell) =
    if s.color == colGray:
      if s.rc > 0:
        scanBlack(s)
      else:
        s.setColor(colWhite)
        for t in sons(s): scan(t)
  ]#
  if s.color == colGray:
    if (s.rc shr rcShift) >= 0:
      scanBlack(s, desc, j)
      # XXX this should be done according to Lins' paper but currently breaks
      #when useJumpStack:
      #  s.setColor colPurple
    else:
      when useJumpStack:
        # first we have to repair all the nodes we have seen
        # that are still alive; we also need to mark what they
        # refer to as alive:
        while j.jumpStack.len > 0:
          let (t, desc) = j.jumpStack.pop
          # not in jump stack anymore!
          t.rc = t.rc and not jumpStackFlag
          if t.color == colGray and (t.rc shr rcShift) >= 0:
            scanBlack(t, desc, j)
            # XXX this should be done according to Lins' paper but currently breaks
            #t.setColor colPurple
            when traceCollector:
              cprintf("[jump stack] %p %ld\n", t, t.rc shr rcShift)

      s.setColor(colWhite)
      trace(s, desc, j)
      while j.traceStack.len > 0:
        let (t, desc) = j.traceStack.pop()
        if t.color == colGray:
          if (t.rc shr rcShift) >= 0:
            scanBlack(t, desc, j)
          else:
            when useJumpStack:
              # first we have to repair all the nodes we have seen
              # that are still alive; we also need to mark what they
              # refer to as alive:
              while j.jumpStack.len > 0:
                let (t, desc) = j.jumpStack.pop
                # not in jump stack anymore!
                t.rc = t.rc and not jumpStackFlag
                if t.color == colGray and (t.rc shr rcShift) >= 0:
                  scanBlack(t, desc, j)
                  # XXX this should be done according to Lins' paper but currently breaks
                  #t.setColor colPurple
                  when traceCollector:
                    cprintf("[jump stack] %p %ld\n", t, t.rc shr rcShift)

            t.setColor(colWhite)
            trace(t, desc, j)

proc collectWhite(s: Cell; desc: PNimType; j: var GcEnv) =
  #[
  proc collectWhite(s: Cell) =
    if s.color == colWhite and not buffered(s):
      s.setColor(colBlack)
      for t in sons(s):
        collectWhite(t)
      free(s) # watch out, a bug here!
  ]#
  if s.color == colWhite and (s.rc and isCycleCandidate) == 0:
    s.setColor(colBlack)
    when false:
      # optimized version (does not work)
      j.traceStack.add(s, desc)
      # this way of writing the loop means we can free all the nodes
      # afterwards avoiding the "use after free" bug in the paper.
      var i = 0
      while i < j.traceStack.len:
        let (t, desc) = j.traceStack.d[j.traceStack.len-1]
        inc i
        if t.color == colWhite and (t.rc and isCycleCandidate) == 0:
          t.setColor(colBlack)
          trace(t, desc, j)

      for i in 0 ..< j.traceStack.len:
        free(j.traceStack.d[i][0], j.traceStack.d[i][1])
      j.traceStack.len = 0
    else:
      var subgraph: CellSeq
      init subgraph
      subgraph.add(s, desc)
      trace(s, desc, j)
      while j.traceStack.len > 0:
        let (t, desc) = j.traceStack.pop()
        if t.color == colWhite and (t.rc and isCycleCandidate) == 0:
          subgraph.add(t, desc)
          t.setColor(colBlack)
          trace(t, desc, j)
      for i in 0 ..< subgraph.len:
        free(subgraph.d[i][0], subgraph.d[i][1])
      inc j.freed, subgraph.len
      deinit subgraph

proc collectCyclesBacon(j: var GcEnv) =
  # pretty direct translation from
  # https://researcher.watson.ibm.com/researcher/files/us-bacon/Bacon01Concurrent.pdf
  # Fig. 2. Synchronous Cycle Collection
  #[
    for s in roots:
      markGray(s)
    for s in roots:
      scan(s)
    for s in roots:
      remove s from roots
      s.buffered = false
      collectWhite(s)
  ]#
  for i in 0 ..< roots.len:
    markGray(roots.d[i][0], roots.d[i][1], j)
  for i in 0 ..< roots.len:
    scan(roots.d[i][0], roots.d[i][1], j)

  for i in 0 ..< roots.len:
    let s = roots.d[i][0]
    s.rc = s.rc and not isCycleCandidate
    collectWhite(s, roots.d[i][1], j)
  #roots.len = 0

const
  defaultThreshold = 10_000

var
  rootsThreshold = defaultThreshold

proc collectCycles() =
  ## Collect cycles.
  var j: GcEnv
  init j.traceStack
  when useJumpStack:
    init j.jumpStack
    collectCyclesBacon(j)
    while j.jumpStack.len > 0:
      let (t, desc) = j.jumpStack.pop
      # not in jump stack anymore!
      t.rc = t.rc and not jumpStackFlag
    deinit j.jumpStack
  else:
    collectCyclesBacon(j)

  deinit j.traceStack
  deinit roots
  # compute the threshold based on the previous history
  # of the cycle collector's effectiveness:
  # we're effective when we collected 50% or more of the nodes
  # we touched. If we're effective, we can reset the threshold:
  if j.freed * 2 >= j.touched:
    rootsThreshold = defaultThreshold
  else:
    rootsThreshold = rootsThreshold * 3 div 2
  when false:
    cprintf("[collectCycles] freed %ld new threshold %ld\n", j.freed, rootsThreshold)

proc registerCycle(s: Cell; desc: PNimType) =
  if roots.d == nil: init(roots)
  s.rootIdx = roots.len
  add(roots, s, desc)
  if roots.len >= rootsThreshold:
    collectCycles()

proc GC_fullCollect* =
  ## Forces a full garbage collection pass. With ``--gc:orc`` triggers the cycle
  ## collector.
  collectCycles()

proc GC_enableMarkAndSweep() =
  rootsThreshold = defaultThreshold

proc GC_disableMarkAndSweep() =
  rootsThreshold = high(int)

proc rememberCycle(isDestroyAction: bool; s: Cell; desc: PNimType) {.noinline.} =
  if isDestroyAction:
    if (s.rc and isCycleCandidate) != 0:
      s.rc = s.rc and not isCycleCandidate
      unregisterCycle(s)
  else:
    # do not call 'rememberCycle' again unless this cell
    # got an 'incRef' event:
    #s.setColor colGreen  # XXX This is wrong!
    if (s.rc and isCycleCandidate) == 0:
      s.rc = s.rc or isCycleCandidate
      registerCycle(s, desc)

proc nimDecRefIsLastCyclicDyn(p: pointer): bool {.compilerRtl, inl.} =
  if p != nil:
    var cell = head(p)
    if (cell.rc and not rcMask) == 0:
      result = true
      #cprintf("[DESTROY] %p\n", p)
    else:
      dec cell.rc, rcIncrement
    if cell.color == colPurple:
      rememberCycle(result, cell, cast[ptr PNimType](p)[])

proc nimDecRefIsLastCyclicStatic(p: pointer; desc: PNimType): bool {.compilerRtl, inl.} =
  if p != nil:
    var cell = head(p)
    if (cell.rc and not rcMask) == 0:
      result = true
      #cprintf("[DESTROY] %p %s\n", p, desc.name)
    else:
      dec cell.rc, rcIncrement
    if cell.color == colPurple:
      rememberCycle(result, cell, desc)
