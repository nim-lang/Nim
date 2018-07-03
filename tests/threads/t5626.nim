import threadpool

var ch: Channel[int]
ch.open
var pch = ch.addr

proc run(f: proc(): int {.gcsafe.}): proc() =
  let r = spawn f()
  return proc() = await(r)

var working = false

proc handler(): int =
  while true:
    let (h, v) = pch[].tryRecv()
    if not h:
      discard cas(working.addr, true, false)
      break
  1

proc send(x: int) =
  ch.send(x)
  if cas(working.addr, false, true):
    discard run(handler)

for x in 0..1000000:
  send(x)