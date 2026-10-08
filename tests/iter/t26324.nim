discard """
  output: '''
zero
after
nonzero
after
small
done
big
1
done
'''
"""

# bug #26324: case on an if expression skips all branches

iterator it(k: int): int {.closure.} =
  var kk = k
  case (if kk > 100: 0 else: kk)
  of 0: echo "zero"
  else:
    yield 1
    echo "nonzero"
  echo "after"

for _ in it(0): discard
for _ in it(5): discard

iterator it2(k: int): int {.closure.} =
  case (if k > 10: "big" else: "small")
  of "big":
    echo "big"
    yield 1
    echo 1
  else:
    echo "small"
  echo "done"

for _ in it2(1): discard
for _ in it2(20): discard
