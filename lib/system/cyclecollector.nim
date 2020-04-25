#
#
#            Nim's Runtime Library
#        (c) Copyright 2019 Andreas Rumpf
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
# However, I used my own ideas on top of Lins'. We detect a garbage cycle
# directly without all this complexity. A garbage cycle is *always* when the
# number of outgoing refs is the same as the number of incoming refs. We
# do this for every potential cycle root:
#
# - Traverse the graph beginning at the root. Count the number of incoming
#   refs. Count the number of outgoing refs. If identical, free the cycle.
# - Do not mutate the reference counts so that this step can run concurrently.
# - Do not patch the incref/decref operations, they are slow already and not
#   under the programmer's control. Usually the programmer has more control
#   over the creation via `new`. On the other hand, only if the structure
#   got incRef'ed, we need to re-trace it, there is no need for "generations" then.
# - The two hooks should be 'registerPotentialCycleRoot' and
#   'unregisterPotentialCycleRoot'.

#[

The problem with attaching any operation to the 'decref(x) > 0' event is that it
is super expensive for the common "thunder herd" problem. That's a lot of calls
to 'registerPotentialCycleRoot' -- that's not how this algorithm works! Only
yellow stuff is traversed. However, alive stuff is marked yellow if the object
is still alive, that's very bad.

]#

type PT = Cell
include cellseqs_v2

const
  colGreen = 0b000
  colYellow = 0b001
  isCycleCandidate = 0b10 # cell is marked as a cycle candidate
  rcShift = 3      # shift by rcShift to get the reference counter
  colorMask = 0b01

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

type
  GcEnv = object
    traceStack: CellSeq

proc trace(s: Cell; desc: PNimType; j: var GcEnv) {.inline.} =
  if desc.traceImpl != nil:
    var p = s +! sizeof(RefHeader)
    cast[TraceProc](desc.traceImpl)(p, addr(j))

when true:
  template debug(str: cstring; s: Cell) = discard
else:
  proc debug(str: cstring; s: Cell) =
    let p = s +! sizeof(RefHeader)
    cprintf("[%s] name %s %ld\n", str, p, s.rootIdx)

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
  roots: CellSeq

proc unregisterCycle(s: Cell) =
  # swap with the last element. O(1)
  let idx = s.rootIdx
  if idx >= roots.len or idx < 0:
    cprintf("[Bug!] %ld\n", idx)
    quit 1

  roots.d[idx] = roots.d[roots.len-1]
  roots.d[idx][0].rootIdx = idx
  dec roots.len

#[

lin2010 corse-grained analysis of cycles.
However here is the problem. Let's say we analyse
graph G1, it is dead but points to G2 which is alive.
Then we never free G1.

  G1 -> G2
         ^ R

However, we will traverse G2 and if we randomize the order
the next time G2 will be scanned first. It's alive and yet
a different strongly connected component. We then traverse
G1 again and do not follow nor count the pointers to ID(G2).
Thus we will detect that G1 is garbage and can be collected.

]#

proc scanBlack(s: Cell) =
  setColor(s, colBlack)
  for t in sons(s):
    t.rc = t.rc + rcIncrement
    if t.color != colBlack:
      scanBlack(t)

proc markGray(s: Cell) =
  if s.color == colGray:
    setColor(s, colGray)
    for t in sons(s):
      t.rc = t.rc - rcIncrement
      if t.color != colGray:
        markGray(t)

proc scan(s: Cell) =
  if s.color == colGray:
    if (s.rc shr rcShift) >= 0:
      scanBlack(s)
    else:
      s.setColor(colWhite)
      for t in sons(s): scan(t)

proc collectWhite(s: Cell) =
  if s.color == colWhite and not buffered(s):
    s.setColor(colBlack)
    for t in sons(s):
      collectWhite(t)
    free(s) # watch out, a bug here!

proc collectCyclesBackup() =
  # pretty direct translation from
  # https://researcher.watson.ibm.com/researcher/files/us-bacon/Bacon01Concurrent.pdf
  # Fig. 2. Synchronous Cycle Collection
  for s in roots:
    markGray(s)
  for s in roots:
    scan(s)
  for s in roots:
    remove s
    s.buffered = false
    collectWhite(s)


proc collectCycles*(): int =
  ## Collect cycles. Returns the number of collected cycles.
  var j: GcEnv
  var subgraph: CellSeq
  var moreRoots: CellSeq
  init subgraph
  init j.traceStack
  init moreRoots
  var sccId = -1
  cprintf("[#Roots] %ld\n", roots.len)
  while roots.len > 0:
    # we compute "strongly connected components",
    # this is the coarse-grained algorithm (CGA) from
    # An efficient approach to cyclic reference counting based on a coarse-grained search
    # Chin-Yang Lin, Ting-Wei Hou
    # Information Processing Letters 111 (2010) 1–10
    let (s, desc) = roots.pop()
    subgraph.add(s, desc)
    debug("root", s)
    s.rc = s.rc and not isCycleCandidate
    var indegree = (s.rc shr rcShift) + 1
    var outdegree = 0
    #let oldMoreRootsLen = moreRoots.len

    if s.rootIdx >= 0:
      s.rootIdx = sccId
      trace(s, desc, j)
    while j.traceStack.len > 0:
      let (t, desc) = j.traceStack.pop()
      debug("traversed", t)

      inc outdegree
      if t.rootIdx != sccId:
        if t.rootIdx < 0:
          # this node was traversed for a previous SCC computation.
          dec outdegree
          debug("in a different SCC", t)
        else:
          inc indegree, (t.rc shr rcShift) + 1
          if (t.rc and isCycleCandidate) != 0:
            debug("not a root anymore", t)
            unregisterCycle(t)
            t.rc = t.rc and not isCycleCandidate
            moreRoots.add(t, desc)
          t.rootIdx = sccId
          subgraph.add(t, desc)
          trace(t, desc, j)

    if indegree == outdegree:
      # it's a dead cycle, free all nodes that have 'rootIdx == sccId'.
      # And by construction, these are all in subgraph:
      while subgraph.len > 0:
        let (t, desc) = subgraph.pop()
        if t.rootIdx != sccId:
          subgraph.add(t, desc)
          break
        free(t, desc)
      inc result
      cprintf("[luck] %ld %ld\n", indegree, outdegree)
      moreRoots.len = 0
    else:
      cprintf("[No luck this time] %ld %ld\n", indegree, outdegree)
      while moreRoots.len > 0:
        let (t, desc) = moreRoots.pop()
        roots.add(t, desc)

    dec sccId
  # and now reset the still alive nodes to something sane:
  cprintf("[Erok] %ld\n", subgraph.len)
  while subgraph.len > 0:
    let (t, desc) = subgraph.pop()
    if (t.rc and isCycleCandidate) != 0:
      cprintf("[Bug 2!]\n")
      quit 1
    t.rootIdx = 0

  deinit subgraph
  deinit j.traceStack
  deinit moreRoots
  deinit roots

proc registerCycle(s: Cell; desc: PNimType) =
  if roots.d == nil: init(roots)
  s.rootIdx = roots.len
  add(roots, s, desc)
  if roots.len >= 10_000:
    discard collectCycles()

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
    if cell.color == colYellow:
      rememberCycle(result, cell, cast[ptr PNimType](p)[])

proc nimDecRefIsLastCyclicStatic(p: pointer; desc: PNimType): bool {.compilerRtl, inl.} =
  if p != nil:
    var cell = head(p)
    if (cell.rc and not rcMask) == 0:
      result = true
      #cprintf("[DESTROY] %p %s\n", p, desc.name)
    else:
      dec cell.rc, rcIncrement
    if cell.color == colYellow:
      rememberCycle(result, cell, desc)
