discard """
  output: '''tada
1
2
3
ta da1 1
1 2
1 3
2 1
2 2
2 3
3 1
3 2
3 3
0
1
2
a1: A
a2: A
a1: B
a2: B
a1: C
a2: C
a1: D'''
"""
# Test first class iterator:

import strutils

iterator tokenize2(s: string, seps: set[char] = Whitespace): tuple[
  token: string, isSep: bool] {.closure.} =
  var i = 0
  while i < s.len:
    var j = i
    if s[j] in seps:
      while j < s.len and s[j] in seps: inc(j)
      if j > i:
        yield (substr(s, i, j-1), true)
    else:
      while j < s.len and s[j] notin seps: inc(j)
      if j > i:
        yield (substr(s, i, j-1), false)
    i = j

iterator count3(): int {.closure.} =
  yield 1
  yield 2
  yield 3

for word, isSep in tokenize2("ta da", WhiteSpace):
  if not isSep:
    stdout.write(word)
echo ""

proc inProc() =
  for c in count3():
    echo c

  for word, isSep in tokenize2("ta da", WhiteSpace):
    stdout.write(word)

  for c in count3():
    for d in count3():
      echo c, " ", d


inProc()

iterator count0(): int {.closure.} =
  # note: doesn't require anything in its closure (except 'state')
  yield 0

iterator count2(): int {.closure.} =
  # note: requires 'x' in its closure
  var x = 1
  yield x
  inc x
  yield x

# a first class iterator has the type 'proc {.closure.}', but maybe
# it shouldn't:
proc invoke(iter: iterator(): int {.closure.}) =
  for x in iter(): echo x

invoke(count0)
invoke(count2)


# simple tasking:
type
  TTask = iterator (ticker: int)

iterator a1(ticker: int) {.closure.} =
  echo "a1: A"
  yield
  echo "a1: B"
  yield
  echo "a1: C"
  yield
  echo "a1: D"

iterator a2(ticker: int) {.closure.} =
  echo "a2: A"
  yield
  echo "a2: B"
  yield
  echo "a2: C"

proc runTasks(t: varargs[TTask]) =
  var ticker = 0
  while true:
    let x = t[ticker mod t.len]
    if finished(x): break
    x(ticker)
    inc ticker

runTasks(a1, a2)
