discard """
  cmd: "nim c --mm:yrc -d:useMalloc --threads:on $file"
  output: "ok"
  disabled: "windows"
  disabled: "freebsd"
  disabled: "openbsd"
"""

# Generational epoch stamps, young -> old.
#
# Each thread keeps a long-lived cyclic web and promotes it past
# YrcPromoteAge with a few seeded partial collects. After that, every
# iteration allocates die-young cyclic rings that reference the web -- the
# classic new-refers-to-old pattern. Capture then prunes at the stamp
# boundary and commit `trialDec`s the young -> web edges WITHOUT re-rooting
# the web, so from that point on the web's liveness no longer rests on being
# traced: it rests on the deferred machinery (the per-thread suspect buffer
# and the pruned-target list) keeping those cells examinable and alive until
# the epoch advances.
#
# Two properties are asserted. The surviving web is walked in full at the
# end, so a web that was collected or partially collected out from under the
# deferred machinery shows up as a nil edge, a corrupted id or a short node
# count. And after every web is dropped, a full collect must reclaim all of
# it -- deferring reclamation to the epoch boundary must not turn into never
# reclaiming.
#
# Sized so the shared epoch clock (YrcEpochLen collections) turns over
# repeatedly mid-run: the steady-state suspect flush is on the path under
# test, not just the one forced by the final GC_fullCollect. Measured on the
# current collector this run remembers ~200 suspects across ~80 flushes.
#
# NOTE: this is a functional test of the generational path, not a regression
# test for the dangling-suspect use-after-free that path once had. It was
# tried in that role and does not reproduce it: the suspects it creates are
# nearly always flushed before they die, so the bad ordering never comes up.
# tests/async/tasyncawait.nim reproduces that one reliably.

const
  NumThreads = 4
  WebSize = 8_000     ## the web that survives to the integrity check
  DoomedSize = 800    ## promoted, given young -> old edges, then dropped
  WebDegree = 4
  SeedProbes = 6      ## must exceed YrcPromoteAge (3) to promote a web
  OuterIters = 40     ## with NumThreads, enough collections to cross epochs
  YoungBatches = 8
  YoungRing = 100

type
  WebNode = ref object
    id: int32
    seen: int32       ## walk marker, plain data: no GC interaction
    edges: array[WebDegree, WebNode]

  Bridge = ref object
    toWeb: WebNode
    self: Bridge

  YoungNode = ref object
    next: YoungNode
    hub: WebNode      ## the young -> old edge under test
    self: YoungNode

var probeSlot {.threadvar.}: Bridge

proc buildWebNodes(n: int): seq[WebNode] =
  ## Strongly connected mesh: one incoming edge pulls the whole web into any
  ## collector that does not prune at the stamp boundary.
  result = newSeq[WebNode](n)
  for i in 0 ..< n:
    result[i] = WebNode(id: int32(i))
  for i in 0 ..< n:
    for d in 0 ..< WebDegree:
      result[i].edges[d] = result[(i + 1 + d * 97) mod n]

proc buildWeb(n: int): WebNode = buildWebNodes(n)[0]

proc checkWeb(root: WebNode; n: int) =
  ## Every node reachable exactly once, every edge intact. A web that was
  ## collected out from under us fails here instead of faulting later.
  var stack = @[root]
  root.seen = 1
  var count = 0
  while stack.len > 0:
    let x = stack.pop()
    inc count
    doAssert x.id >= 0'i32 and x.id < int32(n), "web node corrupted: id " & $x.id
    for d in 0 ..< WebDegree:
      let e = x.edges[d]
      doAssert e != nil, "web edge nil'ed at node " & $x.id
      if e.seen != 1:
        e.seen = 1
        stack.add e
  doAssert count == n, "web lost nodes: " & $count & " of " & $n

proc paintYoung(hub: WebNode; n: int) =
  ## Ring of `n` self-referential nodes, each pointing at the web. When the
  ## seq drops, the ring is garbage whose only external edges go into the
  ## live (and by now stamp-pruned) web.
  var nodes = newSeq[YoungNode](n)
  for i in 0 ..< n:
    nodes[i] = YoungNode(hub: hub)
  for i in 0 ..< n:
    nodes[i].next = nodes[(i + 1) mod n]
    nodes[i].self = nodes[i]

proc paintYoungSpread(web: seq[WebNode]; n: int) =
  ## Same, but every young node targets a DIFFERENT old cell, so the commit
  ## deposits many distinct cells in the suspect buffer instead of just the
  ## web root. Breadth here is what makes the "suspect dies before the epoch
  ## flush" ordering likely rather than incidental.
  var nodes = newSeq[YoungNode](n)
  for i in 0 ..< n:
    nodes[i] = YoungNode(hub: web[(i * 7) mod web.len])
  for i in 0 ..< n:
    nodes[i].next = nodes[(i + 1) mod n]
    nodes[i].self = nodes[i]

proc probeBridge(b: Bridge) {.noinline.} =
  ## Seeded false alarm so a partial collect traces -- and stamps -- the web.
  ## The threadvar slot is deliberate: a stack temporary is not a reliable
  ## way to get the bridge registered as a candidate root.
  probeSlot = b
  probeSlot = nil

proc promote(b: Bridge) =
  ## Trace-and-stamp the bridge's web often enough that its cells pass
  ## YrcPromoteAge and captures start pruning at them.
  for _ in 1 .. SeedProbes:
    probeBridge(b)
    # Deliberately not GC_fullCollect: that advances the epoch and wipes the
    # stamps this test needs.
    GC_partialCollect(0)

proc cycleDoomedWeb() =
  ## Promote a web, hand it young -> old edges so its cells land in the
  ## deferred suspect buffer, then drop it. Those cells are now garbage
  ## while still listed, and an ordinary collection reclaims them well
  ## before the epoch advance that flushes the buffer. THIS is the case a
  ## live-forever web never produces: the list has to not be holding
  ## pointers to cells anyone else was free to reclaim.
  let doomedNodes = buildWebNodes(DoomedSize)
  let b = Bridge(toWeb: doomedNodes[0])
  b.self = b
  promote(b)
  for _ in 1 .. YoungBatches:
    paintYoungSpread(doomedNodes, YoungRing)
  GC_partialCollect(0)
  # `doomedNodes` and `b` die with this scope: every cell that just landed
  # in the suspect buffer is now garbage while still listed there.

proc threadWork() {.thread.} =
  let web = buildWeb(WebSize)
  let bridge = Bridge(toWeb: web)
  bridge.self = bridge
  promote(bridge)

  for i in 1 .. OuterIters:
    cycleDoomedWeb()
    for _ in 1 .. YoungBatches:
      paintYoung(web, YoungRing)
    GC_partialCollect(0)

  checkWeb(web, WebSize)
  doAssert bridge.toWeb == web, "bridge lost its web"

var threads: array[NumThreads, Thread[void]]
for i in 0 ..< NumThreads:
  createThread(threads[i], threadWork)
joinThreads(threads)

# Every web is unreachable now. The full collect advances the epoch, which
# flushes the suspect buffers into the root set -- the major-collection half
# of the scheme -- so all of it must come back.
GC_fullCollect()
doAssert getOccupiedMem() < 8 * 1024 * 1024,
  "webs not reclaimed: " & $(getOccupiedMem() div 1024) & " KiB still occupied"
echo "ok"
