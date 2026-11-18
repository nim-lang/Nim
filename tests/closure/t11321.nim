discard """
  output: '''1
2
@[1, 2]'''
"""

# bug #11321: a top level closure iterator used in a nested closure iterator
iterator foo: int {.closure.} =
  yield 1
  yield 2

iterator bar: int {.closure.} =
  var x = iterator: int =
    var it = foo
    yield it()
    yield it()
  yield x()
  yield x()

proc p(): seq[int] =
  let q = proc (): seq[int] =
    var it = foo
    result.add it()
    result.add it()
  result = q()

for v in bar(): echo v
echo p()
