discard """
  output: '''
'''
"""

# parallel convex hull for Nim bigbreak
# nim c --threads:on -d:release pconvex_hull.nim
import algorithm, sequtils, threadpool

type Point = tuple[x, y: float]

proc cmpPoint(a, b: Point): int =
  result = cmp(a.x, b.x)
  if result == 0:
    result = cmp(a.y, b.y)

template cross[T](o, a, b: T): untyped =
  (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)

template pro(): untyped =
  while lr1 > 0 and cross(result[lr1 - 1], result[lr1], p[i]) <= 0:
    discard result.pop
    lr1 -= 1
  result.add(p[i])
  lr1 += 1

proc half[T](p: seq[T]; upper: bool): seq[T] =
  var i, lr1: int
  result = @[]
  lr1 = -1
  if upper:
    i = 0
    while i <= high(p):
      pro()
      i += 1
  else:
    i = high(p)
    while i >= low(p):
      pro()
      i -= 1
  discard result.pop

proc convex_hull[T](points: var seq[T], cmp: proc(x, y: T): int {.closure.}) : seq[T] =
  if len(points) < 2: return points
  points.sort(cmp)
  var ul: array[2, FlowVar[seq[T]]]
  parallel:
    for k in 0..ul.high:
      ul[k] = spawn half[T](points, k == 0)
  result = concat(^ul[0], ^ul[1])

var s = map(toSeq(0..9999), proc(x: int): Point = (float(x div 100), float(x mod 100)))
# On some runs, this pool size reduction will set the "shutdown" attribute on the
# worker thread that executes our spawned task, before we can read the flowvars.
setMaxPoolSize 2

for i in 0..2:
  doAssert convex_hull[Point](s, cmpPoint) ==
      @[(0.0, 0.0), (99.0, 0.0), (99.0, 99.0), (0.0, 99.0)]
