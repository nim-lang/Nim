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
2'''
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

for word, isSep in tokenize2("ta da", whiteSpace):
  if not isSep:
    stdout.write(word)
echo ""

proc inProc() =
  for c in count3():
    echo c
  
  for word, isSep in tokenize2("ta da", whiteSpace):
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
proc invoke(iter: proc(): int {.closure.}) =
  for x in iter(): echo x

invoke(count0)
invoke(count2)
