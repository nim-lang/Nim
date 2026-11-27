discard """
  matrix: "--mm:refc"
  output: "ok"
"""

# bug #26720: GC_unref was linear in the number of GC_ref'd objects

type
  Obj = ref object
    x: int

var freed = 0
var freedTwice = 0 # freed objects that were GC_ref'd twice

proc fin(o: Obj) =
  inc freed
  if o.x mod 3 == 0: inc freedTwice

proc keepOnlyRooted(n: int): seq[pointer] =
  # the objects are only kept alive by GC_ref
  for i in 0 ..< n:
    var o: Obj
    new(o, fin)
    o.x = i
    GC_ref(o)
    if i mod 3 == 0: GC_ref(o) # every third object is GC_ref'd twice
    result.add cast[pointer](o)

proc main =
  const N = 3000
  var objs = keepOnlyRooted(N)
  GC_fullCollect()
  doAssert freed == 0
  # release in the same order as GC_ref (the slow case before the fix):
  for i in 0 ..< N:
    GC_unref(cast[Obj](objs[i]))
  GC_fullCollect()
  doAssert freedTwice == 0
  # the stack is scanned conservatively, so allow for a few survivors:
  doAssert freed > N - N div 3 - 10, $freed
  for i in countup(0, N-1, 3):
    doAssert cast[Obj](objs[i]).x == i
    GC_unref(cast[Obj](objs[i]))
  GC_fullCollect()
  doAssert freed > N - 10, $freed

  # performance: this used to take seconds
  var big = newSeq[Obj](200_000)
  for i in 0 ..< big.len:
    big[i] = Obj(x: i)
    GC_ref(big[i])
  for i in 0 ..< big.len:
    GC_unref(big[i])

main()
echo "ok"
