#
# YRC: Thread-safe ORC (concurrent cycle collector).
# Same API as orc.nim but with striped queues and global lock for merge/collect.
# Destructors for refs run at collection time, not immediately on last decRef.
#

{.push raises: [].}

include cellseqs_v2

import std/locks

const
  NumStripes = 64
  QueueSize = 128
  RootsThreshold = 10

  colBlack = 0b000
  colGray = 0b001
  colWhite = 0b010
  maybeCycle = 0b100
  inRootsFlag = 0b1000
  colorMask = 0b011
  logOrc = defined(nimArcIds)

type
  TraceProc = proc (p, env: pointer) {.nimcall, benign, raises: [].}
  DisposeProc = proc (p: pointer) {.nimcall, benign, raises: [].}

template color(c): untyped = c.rc and colorMask
template setColor(c, col) =
  when col == colBlack:
    c.rc = c.rc and not colorMask
  else:
    c.rc = c.rc and not colorMask or col

const
  optimizedOrc = false
  useJumpStack = false

type
  GcEnv = object
    traceStack: CellSeq[ptr pointer]
    when useJumpStack:
      jumpStack: CellSeq[ptr pointer]
    toFree: CellSeq[Cell]
    freed, touched, edges, rcSum: int
    keepThreshold: bool

proc trace(s: Cell; desc: PNimTypeV2; j: var GcEnv) {.inline.} =
  if desc.traceImpl != nil:
    var p = s +! sizeof(RefHeader)
    cast[TraceProc](desc.traceImpl)(p, addr(j))

include threadids

type
  Stripe = object
    lockInc: Lock
    toIncLen: int
    toInc: array[QueueSize, Cell]
    lockDec: Lock
    toDecLen: int
    toDec: array[QueueSize, (Cell, PNimTypeV2)]

var
  gYrcGlobalLock: Lock
  roots: CellSeq[Cell]  # merged roots, used under global lock
  stripes: array[NumStripes, Stripe]
  rootsThreshold: int = 128
  defaultThreshold = when defined(nimFixedOrc): 10_000 else: 128

proc getStripeIdx(): int {.inline.} =
  getThreadId() and (NumStripes - 1)

proc nimIncRefCyclic(p: pointer; cyclic: bool) {.compilerRtl, inl.} =
  let h = head(p)
  when optimizedOrc:
    if cyclic: h.rc = h.rc or maybeCycle
  let idx = getStripeIdx()
  while true:
    var overflow = false
    withLock stripes[idx].lockInc:
      if stripes[idx].toIncLen < QueueSize:
        stripes[idx].toInc[stripes[idx].toIncLen] = h
        stripes[idx].toIncLen += 1
      else:
        overflow = true
    if overflow:
      withLock gYrcGlobalLock:
        for i in 0..<NumStripes:
          withLock stripes[i].lockInc:
            for j in 0..<stripes[i].toIncLen:
              let x = stripes[i].toInc[j]
              x.rc = x.rc +% rcIncrement
            stripes[i].toIncLen = 0
    else:
      break

proc mergePendingRoots() =
  for i in 0..<NumStripes:
    withLock stripes[i].lockInc:
      for j in 0..<stripes[i].toIncLen:
        let x = stripes[i].toInc[j]
        x.rc = x.rc +% rcIncrement
      stripes[i].toIncLen = 0
    withLock stripes[i].lockDec:
      for j in 0..<stripes[i].toDecLen:
        let (c, desc) = stripes[i].toDec[j]
        c.rc = c.rc -% rcIncrement
        if (c.rc and inRootsFlag) == 0:
          c.rc = c.rc or inRootsFlag
          if roots.d == nil: init(roots)
          add(roots, c, desc)
      stripes[i].toDecLen = 0

proc collectCycles()

when logOrc or orcLeakDetector:
  proc writeCell(msg: cstring; s: Cell; desc: PNimTypeV2) =
    when orcLeakDetector:
      cfprintf(cstderr, "%s %s file: %s:%ld; color: %ld; thread: %ld\n",
        msg, desc.name, s.filename, s.line, s.color, getThreadId())
    else:
      cfprintf(cstderr, "%s %s %ld root index: %ld; RC: %ld; color: %ld; thread: %ld\n",
        msg, desc.name, s.refId, (if (s.rc and inRootsFlag) != 0: 1 else: 0), s.rc shr rcShift, s.color, getThreadId())

proc free(s: Cell; desc: PNimTypeV2) {.inline.} =
  when traceCollector:
    cprintf("[From ] %p rc %ld color %ld\n", s, s.rc shr rcShift, s.color)
  let p = s +! sizeof(RefHeader)
  when logOrc: writeCell("free", s, desc)
  if desc.destructor != nil:
    cast[DestructorProc](desc.destructor)(p)
  nimRawDispose(p, desc.align)

template orcAssert(cond, msg) =
  when logOrc:
    if not cond:
      cfprintf(cstderr, "[Bug!] %s\n", msg)
      rawQuit 1

when logOrc:
  proc strstr(s, sub: cstring): cstring {.header: "<string.h>", importc.}

proc nimTraceRef(q: pointer; desc: PNimTypeV2; env: pointer) {.compilerRtl, inl.} =
  let p = cast[ptr pointer](q)
  if p[] != nil:
    orcAssert strstr(desc.name, "TType") == nil, "following a TType but it's acyclic!"
    var j = cast[ptr GcEnv](env)
    j.traceStack.add(p, desc)

proc nimTraceRefDyn(q: pointer; env: pointer) {.compilerRtl, inl.} =
  let p = cast[ptr pointer](q)
  if p[] != nil:
    var j = cast[ptr GcEnv](env)
    j.traceStack.add(p, cast[ptr PNimTypeV2](p[])[])

proc scanBlack(s: Cell; desc: PNimTypeV2; j: var GcEnv) =
  s.setColor colBlack
  let until = j.traceStack.len
  trace(s, desc, j)
  when logOrc: writeCell("root still alive", s, desc)
  while j.traceStack.len > until:
    let (entry, desc) = j.traceStack.pop()
    let t = head entry[]
    t.rc = t.rc +% rcIncrement
    if t.color != colBlack:
      t.setColor colBlack
      trace(t, desc, j)
      when logOrc: writeCell("child still alive", t, desc)

proc markGray(s: Cell; desc: PNimTypeV2; j: var GcEnv) =
  if s.color != colGray:
    s.setColor colGray
    j.touched = j.touched +% 1
    j.rcSum = j.rcSum +% (s.rc shr rcShift) +% 1
    orcAssert(j.traceStack.len == 0, "markGray: trace stack not empty")
    trace(s, desc, j)
    while j.traceStack.len > 0:
      let (entry, desc) = j.traceStack.pop()
      let t = head entry[]
      t.rc = t.rc -% rcIncrement
      j.edges = j.edges +% 1
      if t.color != colGray:
        t.setColor colGray
        j.touched = j.touched +% 1
        j.rcSum = j.rcSum +% (t.rc shr rcShift) +% 2
        trace(t, desc, j)

proc scan(s: Cell; desc: PNimTypeV2; j: var GcEnv) =
  if s.color == colGray:
    if (s.rc shr rcShift) >= 0:
      scanBlack(s, desc, j)
    else:
      orcAssert(j.traceStack.len == 0, "scan: trace stack not empty")
      s.setColor(colWhite)
      trace(s, desc, j)
      while j.traceStack.len > 0:
        let (entry, desc) = j.traceStack.pop()
        let t = head entry[]
        if t.color == colGray:
          if (t.rc shr rcShift) >= 0:
            scanBlack(t, desc, j)
          else:
            t.setColor(colWhite)
            trace(t, desc, j)

proc collectColor(s: Cell; desc: PNimTypeV2; col: int; j: var GcEnv) =
  if s.color == col and (s.rc and inRootsFlag) == 0:
    orcAssert(j.traceStack.len == 0, "collectWhite: trace stack not empty")
    s.setColor(colBlack)
    j.toFree.add(s, desc)
    trace(s, desc, j)
    while j.traceStack.len > 0:
      let (entry, desc) = j.traceStack.pop()
      let t = head entry[]
      entry[] = nil
      if t.color == col and (t.rc and inRootsFlag) == 0:
        j.toFree.add(t, desc)
        t.setColor(colBlack)
        trace(t, desc, j)

proc collectCyclesBacon(j: var GcEnv; lowMark: int) =
  let last = roots.len -% 1
  when logOrc:
    for i in countdown(last, lowMark):
      writeCell("root", roots.d[i][0], roots.d[i][1])
  for i in countdown(last, lowMark):
    markGray(roots.d[i][0], roots.d[i][1], j)
  var colToCollect = colWhite
  if j.rcSum == j.edges:
    colToCollect = colGray
    j.keepThreshold = true
  else:
    for i in countdown(last, lowMark):
      scan(roots.d[i][0], roots.d[i][1], j)
  init j.toFree
  for i in 0 ..< roots.len:
    let s = roots.d[i][0]
    s.rc = s.rc and not inRootsFlag
    collectColor(s, roots.d[i][1], colToCollect, j)
  when not defined(nimStressOrc):
    let oldThreshold = rootsThreshold
    rootsThreshold = high(int)
  roots.len = 0
  for i in 0 ..< j.toFree.len:
    when orcLeakDetector:
      writeCell("CYCLIC OBJECT FREED", j.toFree.d[i][0], j.toFree.d[i][1])
    free(j.toFree.d[i][0], j.toFree.d[i][1])
  when not defined(nimStressOrc):
    rootsThreshold = oldThreshold
  j.freed = j.freed +% j.toFree.len
  deinit j.toFree

when defined(nimOrcStats):
  var freedCyclicObjects {.threadvar.}: int

proc collectCycles() =
  when logOrc:
    cfprintf(cstderr, "[collectCycles] begin\n")
  withLock gYrcGlobalLock:
    mergePendingRoots()
    if roots.len >= RootsThreshold:
      var j: GcEnv
      init j.traceStack
      collectCyclesBacon(j, 0)
      if roots.len == 0 and roots.d != nil:
        deinit roots
      when not defined(nimStressOrc):
        if j.keepThreshold:
          discard
        elif j.freed *% 2 >= j.touched:
          when not defined(nimFixedOrc):
            rootsThreshold = max(rootsThreshold div 3 *% 2, 16)
          else:
            rootsThreshold = 0
        elif rootsThreshold < high(int) div 4:
          rootsThreshold = (if rootsThreshold <= 0: defaultThreshold else: rootsThreshold)
          rootsThreshold = rootsThreshold div 2 +% rootsThreshold
      when logOrc:
        cfprintf(cstderr, "[collectCycles] end; freed %ld new threshold %ld\n", j.freed, rootsThreshold)
      when defined(nimOrcStats):
        inc freedCyclicObjects, j.freed
      deinit j.traceStack

when defined(nimOrcStats):
  type
    OrcStats* = object
      freedCyclicObjects*: int
  proc GC_orcStats*(): OrcStats =
    result = OrcStats(freedCyclicObjects: freedCyclicObjects)

proc GC_runOrc* =
  withLock gYrcGlobalLock:
    mergePendingRoots()
    var j: GcEnv
    init j.traceStack
    collectCyclesBacon(j, 0)
    deinit j.traceStack
    roots.len = 0
  when logOrc: orcAssert roots.len == 0, "roots not empty!"

proc GC_enableOrc*() =
  when not defined(nimStressOrc):
    rootsThreshold = 0

proc GC_disableOrc*() =
  when not defined(nimStressOrc):
    rootsThreshold = high(int)

proc GC_prepareOrc*(): int {.inline.} =
  withLock gYrcGlobalLock:
    mergePendingRoots()
    result = roots.len

proc GC_partialCollect*(limit: int) =
  withLock gYrcGlobalLock:
    mergePendingRoots()
    if roots.len > limit:
      var j: GcEnv
      init j.traceStack
      collectCyclesBacon(j, limit)
      deinit j.traceStack
      roots.len = limit

proc GC_fullCollect* =
  collectCycles()

proc GC_enableMarkAndSweep*() = GC_enableOrc()
proc GC_disableMarkAndSweep*() = GC_disableOrc()

const acyclicFlag = 1

when optimizedOrc:
  template markedAsCyclic(s: Cell; desc: PNimTypeV2): bool =
    (desc.flags and acyclicFlag) == 0 and (s.rc and maybeCycle) != 0
else:
  template markedAsCyclic(s: Cell; desc: PNimTypeV2): bool =
    (desc.flags and acyclicFlag) == 0

proc nimDecRefIsLastCyclicDyn(p: pointer): bool {.compilerRtl, inl.} =
  result = false
  if p != nil:
    let cell = head(p)
    let desc = cast[ptr PNimTypeV2](p)[]
    let idx = getStripeIdx()
    while true:
      var overflow = false
      withLock stripes[idx].lockDec:
        if stripes[idx].toDecLen < QueueSize:
          stripes[idx].toDec[stripes[idx].toDecLen] = (cell, desc)
          stripes[idx].toDecLen += 1
        else:
          overflow = true
      if overflow:
        collectCycles()
      else:
        break

proc nimDecRefIsLastDyn(p: pointer): bool {.compilerRtl, inl.} =
  nimDecRefIsLastCyclicDyn(p)

proc nimDecRefIsLastCyclicStatic(p: pointer; desc: PNimTypeV2): bool {.compilerRtl, inl.} =
  result = false
  if p != nil:
    let cell = head(p)
    let idx = getStripeIdx()
    while true:
      var overflow = false
      withLock stripes[idx].lockDec:
        if stripes[idx].toDecLen < QueueSize:
          stripes[idx].toDec[stripes[idx].toDecLen] = (cell, desc)
          stripes[idx].toDecLen += 1
        else:
          overflow = true
      if overflow:
        collectCycles()
      else:
        break

proc unsureAsgnRef(dest: ptr pointer, src: pointer) {.inline.} =
  dest[] = src
  if src != nil: nimIncRefCyclic(src, true)

proc nimMarkCyclic(p: pointer) {.compilerRtl, inl.} =
  when optimizedOrc:
    if p != nil:
      let h = head(p)
      h.rc = h.rc or maybeCycle

# Initialize locks at module load
initLock(gYrcGlobalLock)
for i in 0..<NumStripes:
  initLock(stripes[i].lockInc)
  initLock(stripes[i].lockDec)

{.pop.}
