discard """
  matrix: "--mm:orc; --mm:refc"
  output: "ok"
"""

# Multiple producers and consumers on a bounded channel: blocked senders and
# blocked receivers must not steal each other's wakeups.

const
  Producers = 4
  Consumers = 4
  PerProducer = 20_000

var chan: Channel[int]
var sums: array[Consumers, int]

proc producer(id: int) {.thread.} =
  for i in 1..PerProducer:
    chan.send(i)

proc consumer(id: int) {.thread.} =
  for i in 1..PerProducer:
    sums[id] += chan.recv()

for maxItems in [1, 2]:
  chan.open(maxItems)
  sums = default(typeof(sums))
  var p: array[Producers, Thread[int]]
  var c: array[Consumers, Thread[int]]
  for i in 0..<Consumers: createThread(c[i], consumer, i)
  for i in 0..<Producers: createThread(p[i], producer, i)
  joinThreads(p)
  joinThreads(c)
  var total = 0
  for s in sums: total += s
  doAssert total == Producers * (PerProducer * (PerProducer + 1) div 2)
  doAssert chan.peek == 0
  chan.close()

echo "ok"
