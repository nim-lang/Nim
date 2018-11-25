import locks, threadpool, os

# read-only global access
let g1 = @[42]

proc f1() {.gcsafe.} =
  discard g1[0]

spawn f1()

# guarded global access
var
  l2: Lock
  g2 {.guard: l2.} = @[42]

initLock(l2)

proc f2() {.gcsafe.} =
  sleep(100)
  l2.acquire()
  {.locks: [l2].}:
    if g2[0] == 42:
      g2[0] = 2
  l2.release()

proc f3() {.gcsafe.} =
  sleep(100)
  l2.acquire()
  {.locks: [l2].}:
    if g2[0] == 42:
      g2[0] = 3
  l2.release()

spawn f2()
spawn f3()

sync()
doAssert(g2[0] != 42)
# echo "the winner is f", g2[0]

