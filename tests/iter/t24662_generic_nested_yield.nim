discard """
  targets: "c cpp js"
  output: '''
at 0
7#1
at 1
7#2
7 4
twice 7
twice 7
at 0
a#1
at 1
a#2
a 4
twice a
twice a
at 0
1.5#1
at 1
1.5#2
1.5 4
twice 1.5
twice 1.5
at 0
c#1
c 3
'''
"""

# Refs #24662. Generic closure iterators that contain a nested closure iterator,
# a `yield` inside an expression and an inline iterator (whose locals are
# renamed each time it is inlined), instantiated for several types and used
# from different places.

template yieldThen(v: string, e: untyped): untyped =
  yield v
  e

iterator twice[T](x: T): T =
  var tmp = @[x, x]
  for e in tmp:
    yield e

iterator gen[T](x: T; n: int): string {.closure.} =
  # parameters captured by a nested closure iterator are not reliable yet, so
  # the nested iterator only uses locals
  let xx = x
  let count = n
  var acc: seq[T]
  var tag = $x
  iterator inner(): string {.closure.} =
    for i in 0 ..< count:
      acc.add xx
      let r = tag & "#" & yieldThen("at " & $i, $acc.len)
      yield r
  let it = inner
  for s in it():
    yield s
  for e in twice(x):
    acc.add e
  yield tag & " " & $acc.len

proc useGen[T](x: T) =
  for s in gen(x, 2):
    echo s
  for e in twice(x):
    echo "twice ", e

useGen(7)
useGen("a")
useGen(1.5)
for s in gen('c', 1):
  echo s
