discard """
  matrix: "--mm:orc; --mm:refc"
  output: '''
1
2
1
2
10
20
'''
"""

# bug #12848: a closure iterator argument that creates a closure was
# re-created on every resumption
iterator count2(): int {.closure.} =
  var x = 1
  yield x
  inc x
  yield x

iterator iterinvoke[T](iter: iterator(): T {.closure.}): T {.closure.} =
  for x in iter(): yield x

for e in iterinvoke(count2): echo e

proc main =
  for e in iterinvoke(count2): echo e
  var k = 10
  for e in iterinvoke(iterator(): int {.closure.} =
                        yield k
                        yield 2*k):
    echo e
main()
