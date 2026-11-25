discard """
  output: '''
0
1
done
0
1
inner done
2
3
done
0
1
finally
done
0
returned
'''
"""

# bug #26582: `break`/`return` inside an `if`/`while` condition of a
# closure iterator did not leave the state machine.

iterator ifCond(n: int): int {.closure.} =
  var i = 0
  while true:
    if (if i < n: true else: break):
      yield i
    inc i
  echo "done"

for x in ifCond(2): echo x

iterator whileCond(n: int): int {.closure.} =
  var i = 0
  block outer:
    while true:
      while (if i < n: true else: break):
        yield i
        inc i
      echo "inner done"
      while (if i < 4: true else: break outer):
        yield i
        inc i
      echo "unreachable"
  echo "done"

for x in whileCond(2): echo x

iterator withFinally(n: int): int {.closure.} =
  var i = 0
  try:
    while true:
      if (if i < n: true else: break):
        yield i
      inc i
  finally:
    echo "finally"
  echo "done"

for x in withFinally(2): echo x

iterator returnInCond(): int {.closure.} =
  var i = 0
  while true:
    if (if i < 1: true else: return):
      yield i
    inc i
  echo "unreachable"

for x in returnInCond(): echo x
echo "returned"
