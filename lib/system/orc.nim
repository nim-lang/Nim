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

  logOrc = defined(nimArcIds)

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
  #h.setColor colPurple # mark as potential cycle!
  h.setColor colBlack

const
  useJumpStack = false # for thavlak the jump stack doesn't improve the performance at all

type
  GcEnv = object
    traceStack: CellSeq
    when useJumpStack:
      jumpStack: CellSeq   # Lins' jump stack in order to speed up traversals
    toFree: CellSeq
    freed, touched: int

proc trace(s: Cell; desc: PNimTypeV2; j: var GcEnv) {.inline.} =
  if desc.traceImpl != nil:
    var p = s +! sizeof(RefHeader)
    cast[TraceProc](desc.traceImpl)(p, addr(j))

when logOrc:
  proc writeCell(msg: cstring; s: Cell; desc: PNimTypeV2) =
    cfprintf(cstderr, "%s %s %ld root index: %ld; RC: %ld; color: %ld\n",
      msg, desc.name, s.refId, s.rootIdx, s.rc shr rcShift, s.color)

proc free(s: Cell; desc: PNimTypeV2) {.inline.} =
  when traceCollector:
    cprintf("[From ] %p rc %ld color %ld\n", s, s.rc shr rcShift, s.color)
  let p = s +! sizeof(RefHeader)

  when logOrc: writeCell("free", s, desc)

  if desc.disposeImpl != nil:
    cast[DisposeProc](desc.disposeImpl)(p)

  when false:
    cstderr.rawWrite desc.name
    cstderr.rawWrite " "
    if desc.disposeImpl == nil:
      cstderr.rawWrite "lacks dispose"
      if desc.traceImpl != nil:
        cstderr.rawWrite ", but has trace\n"
      else:
        cstderr.rawWrite ", and lacks trace\n"
    else:
      cstderr.rawWrite "has dispose!\n"

  nimRawDispose(p)

proc nimTraceRef(q: pointer; desc: PNimTypeV2; env: pointer) {.compilerRtl, inline.} =
  let p = cast[ptr pointer](q)
  if p[] != nil:
    var j = cast[ptr GcEnv](env)
    j.traceStack.add(head p[], desc)

proc nimTraceRefDyn(q: pointer; env: pointer) {.compilerRtl, inline.} =
  let p = cast[ptr pointer](q)
  if p[] != nil:
    var j = cast[ptr GcEnv](env)
    j.traceStack.add(head p[], cast[ptr PNimTypeV2](p[])[])

template orcAssert(cond, msg) =
  when logOrc:
    if not cond:
      cfprintf(cstderr, "[Bug!] %s\n", msg)
      quit 1

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

proc scanBlack(s: Cell; desc: PNimTypeV2; j: var GcEnv) =
  #[
  proc scanBlack(s: Cell) =
    setColor(s, colBlack)
    for t in sons(s):
      t.rc = t.rc + rcIncrement
      if t.color != colBlack:
        scanBlack(t)
  ]#
  s.setColor colBlack
  let until = j.traceStack.len
  trace(s, desc, j)
  when logOrc: writeCell("root still alive", s, desc)
  while j.traceStack.len > until:
    let (t, desc) = j.traceStack.pop()
    inc t.rc, rcIncrement
    if t.color != colBlack:
      t.setColor colBlack
      trace(t, desc, j)
      when logOrc: writeCell("child still alive", t, desc)

proc markGray(s: Cell; desc: PNimTypeV2; j: var GcEnv) =
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
    orcAssert(j.traceStack.len == 0, "markGray: trace stack not empty")
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

proc scan(s: Cell; desc: PNimTypeV2; j: var GcEnv) =
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

      orcAssert(j.traceStack.len == 0, "scan: trace stack not empty")
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

when false:
  proc writeCell(msg: cstring; s: Cell) =
    cfprintf(cstderr, "%s %p root index: %ld; RC: %ld; color: %ld\n",
      msg, s, s.rootIdx, s.rc shr rcShift, s.color)

proc collectWhite(s: Cell; desc: PNimTypeV2; j: var GcEnv) =
  #[
  proc collectWhite(s: Cell) =
    if s.color == colWhite and not buffered(s):
      s.setColor(colBlack)
      for t in sons(s):
        collectWhite(t)
      free(s) # watch out, a bug here!
  ]#
  if s.color == colWhite and (s.rc and isCycleCandidate) == 0:
    orcAssert(j.traceStack.len == 0, "collectWhite: trace stack not empty")

    s.setColor(colBlack)
    j.toFree.add(s, desc)
    trace(s, desc, j)
    while j.traceStack.len > 0:
      let (t, desc) = j.traceStack.pop()
      if t.color == colWhite and (t.rc and isCycleCandidate) == 0:
        j.toFree.add(t, desc)
        t.setColor(colBlack)
        trace(t, desc, j)

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
  when logOrc:
    for i in 0 ..< roots.len:
      writeCell("root", roots.d[i][0], roots.d[i][1])

  for i in 0 ..< roots.len:
    markGray(roots.d[i][0], roots.d[i][1], j)
  for i in 0 ..< roots.len:
    scan(roots.d[i][0], roots.d[i][1], j)

  init j.toFree
  for i in 0 ..< roots.len:
    let s = roots.d[i][0]
    s.rc = s.rc and not isCycleCandidate
    collectWhite(s, roots.d[i][1], j)

  for i in 0 ..< j.toFree.len:
    free(j.toFree.d[i][0], j.toFree.d[i][1])

  inc j.freed, j.toFree.len
  deinit j.toFree
  #roots.len = 0

const
  defaultThreshold = when defined(nimAdaptiveOrc): 128 else: 10_000

when defined(nimStressOrc):
  const rootsThreshold = 10 # broken with -d:nimStressOrc: 10 and for havlak iterations 1..8
else:
  var rootsThreshold = defaultThreshold

proc collectCycles() =
  ## Collect cycles.
  when logOrc:
    cfprintf(cstderr, "[collectCycles] begin\n")

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

  when not defined(nimStressOrc):
    # compute the threshold based on the previous history
    # of the cycle collector's effectiveness:
    # we're effective when we collected 50% or more of the nodes
    # we touched. If we're effective, we can reset the threshold:
    if j.freed * 2 >= j.touched:
      when defined(nimAdaptiveOrc):
        rootsThreshold = max(rootsThreshold div 2, 16)
      else:
        rootsThreshold = defaultThreshold
      #cfprintf(cstderr, "[collectCycles] freed %ld, touched %ld new threshold %ld\n", j.freed, j.touched, rootsThreshold)
    elif rootsThreshold < high(int) div 4:
      rootsThreshold = rootsThreshold * 3 div 2
  when logOrc:
    cfprintf(cstderr, "[collectCycles] end; freed %ld new threshold %ld touched: %ld mem: %ld\n", j.freed, rootsThreshold, j.touched,
      getOccupiedMem())

proc registerCycle(s: Cell; desc: PNimTypeV2) =
  s.rootIdx = roots.len
  if roots.d == nil: init(roots)
  add(roots, s, desc)

  if roots.len >= rootsThreshold:
    collectCycles()
  #writeCell("[added root]", s)

proc GC_runOrc* =
  ## Forces a cycle collection pass.
  collectCycles()

proc GC_enableOrc*() =
  ## Enables the cycle collector subsystem of ``--gc:orc``. This is a ``--gc:orc``
  ## specific API. Check with ``when defined(gcOrc)`` for its existence.
  when not defined(nimStressOrc):
    rootsThreshold = defaultThreshold

proc GC_disableOrc*() =
  ## Disables the cycle collector subsystem of ``--gc:orc``. This is a ``--gc:orc``
  ## specific API. Check with ``when defined(gcOrc)`` for its existence.
  when not defined(nimStressOrc):
    rootsThreshold = high(int)


proc GC_fullCollect* =
  ## Forces a full garbage collection pass. With ``--gc:orc`` triggers the cycle
  ## collector. This is an alias for ``GC_runOrc``.
  collectCycles()

proc GC_enableMarkAndSweep*() =
  ## For ``--gc:orc`` an alias for ``GC_enableOrc``.
  GC_enableOrc()

proc GC_disableMarkAndSweep*() =
  ## For ``--gc:orc`` an alias for ``GC_disableOrc``.
  GC_disableOrc()

proc rememberCycle(isDestroyAction: bool; s: Cell; desc: PNimTypeV2) {.noinline.} =
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
      s.setColor colBlack
      registerCycle(s, desc)

proc nimDecRefIsLastCyclicDyn(p: pointer): bool {.compilerRtl, inl.} =
  if p != nil:
    var cell = head(p)
    if (cell.rc and not rcMask) == 0:
      result = true
      #cprintf("[DESTROY] %p\n", p)
    else:
      dec cell.rc, rcIncrement
    #if cell.color == colPurple:
    rememberCycle(result, cell, cast[ptr PNimTypeV2](p)[])

proc nimDecRefIsLastCyclicStatic(p: pointer; desc: PNimTypeV2): bool {.compilerRtl, inl.} =
  if p != nil:
    var cell = head(p)
    if (cell.rc and not rcMask) == 0:
      result = true
      #cprintf("[DESTROY] %p %s\n", p, desc.name)
    else:
      dec cell.rc, rcIncrement
    #if cell.color == colPurple:
    rememberCycle(result, cell, desc)
