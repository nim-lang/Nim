discard """
  targets: "c cpp js"
  output: '''
got 31
inner 31 31 32
inner r=3263
sum 3356
inner 32 31 32
inner r=3263
got 3295
got 32
got 32
got 11
inner 11 11 12
inner r=1223
sum 1256
inner 12 11 12
inner r=1223
got 1235
got 12
got 12
hop 9
hop 46
'''
"""

# Refs #24662. Closure iterators nested two levels deep (outerIt > mid > inner),
# where the innermost captures variables of both enclosing iterators and is used
# from procs nested below it. Every nested iterator has an `up` link to the
# environment of its parent, and creating the iterator walks those links from
# the proc that uses it to the one that declares it. A `yield` inside an
# expression makes `inner` need temporaries as well.
#
# The iterators are called through a closure variable (`let it = inner`);
# a direct `for v in inner()` from a nested proc does not compile yet.

template yieldThen(v: int, e: untyped): untyped =
  yield v
  e

iterator outerIt(n: int): int {.closure.} =
  var base = n * 10
  iterator mid(): int {.closure.} =
    var m = base + 1
    iterator inner(): int {.closure.} =
      var i = m + 1
      inc base
      echo "inner ", base, " ", m, " ", i
      let r = i * 100 + (if base > 0: yieldThen(base, m + i) else: 0)
      echo "inner r=", r
      yield r

    # the proc that uses `inner` is one level below the iterator that declares it
    proc sum(): int =
      let it = inner
      for v in it():
        result += v + m

    yield m
    echo "sum ", sum()
    var t = 0
    let it = inner
    for v in it():
      t += v
    yield t
    yield base

  let it = mid
  for v in it():
    yield v
  yield base

for n in [3, 1]:
  let it = outerIt
  for v in it(n):
    echo "got ", v

# The proc that uses the iterator is two levels below the proc that declares it.
proc multiHop(k: int) =
  var x = k
  iterator bar(): int {.closure.} =
    yield x * 10 + (if x > 0: yieldThen(x, 1) else: 0)
  proc mid() =
    var q = x + 1
    proc deeper() =
      let z = bar
      for y in z():
        echo "hop ", y + q
    deeper()
  mid()

multiHop(4)
