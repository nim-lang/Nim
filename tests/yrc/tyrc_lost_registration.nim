discard """
  cmd: "nim c --mm:yrc -d:useMalloc --threads:on $file"
  output: "ok"
  disabled: "windows"
  disabled: "freebsd"
  disabled: "openbsd"
"""

# Regression test for the YRC "lost registration" leak found by the TLA
# model (tlanif examples/yrc2):
# a drain whose registerLocal fails because the cell's inRootsFlag is held by
# a collection's in-flight slice; that collection captured the cell while it
# was still referenced, judges it live and clears the flag. Nothing ever
# looks at the cell again.

import std/[typedthreads, atomics]

type
  Tok = object
    live: bool
  Obj = ref object
    next: Obj
    tok: Tok

var created, destroyed: Atomic[int]

proc `=destroy`(t: Tok) =
  if t.live: discard destroyed.fetchAdd(1)

proc mk(): Obj =
  discard created.fetchAdd(1)
  Obj(tok: Tok(live: true))

const Rounds = 100
const ChainLen = 50_000

var gShared: Obj
var gTmp: Obj
var go, ack: Atomic[int]
var spin: Atomic[int]

proc chain(n: int): Obj =
  result = mk()
  var c = result
  for i in 1 ..< n:
    c.next = mk()
    c = c.next

proc collectorImpl() =
  for r in 1 .. Rounds:
    var ch = chain(ChainLen)
    gTmp = ch          # dec of the chain head -> registered first
    gTmp = nil
    gShared = mk()     # o: rc = gShared
    gTmp = gShared     # copy: rc 2
    gTmp = nil         # dec of o -> registered last, captured first
    go.store(r)
    GC_runOrc()        # drains, steals {chainHead, o}, captures o then the chain
    while ack.load < r: cpuRelax()
    ch = nil

proc mutatorImpl() =
  var delay = 1
  for r in 1 .. Rounds:
    while go.load < r: cpuRelax()
    for i in 0 ..< delay: discard spin.fetchAdd(1, moRelaxed)
    gShared = nil      # last reference: dec into this thread's stripe
    discard GC_prepareOrc()    # drain it while the collector is (hopefully) capturing
    delay = (delay * 7 + 13) mod 20_000
    ack.store(r)

proc collector() {.thread.} =
  {.cast(gcsafe).}: collectorImpl()
proc mutator() {.thread.} =
  {.cast(gcsafe).}: mutatorImpl()

var a, b: Thread[void]
createThread(a, collector)
createThread(b, mutator)
joinThreads(a, b)
for i in 0 ..< 4: GC_fullCollect()
let c = created.load
let d = destroyed.load
doAssert c == d, "leaked " & $(c - d) & " of " & $c
echo "ok"
