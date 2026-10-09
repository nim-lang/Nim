discard """
  targets: "c cpp js"
  output: '''zero
after
nonzero
after
zero
after'''
"""

iterator it(k: int): int {.closure.} =
  var kk = k
  case (if kk > 100: 0 else: kk)
  of 0:
    echo "zero"
  else:
    yield 1
    echo "nonzero"
  echo "after"

for value in it(0):
  doAssert false, "the zero branch must not yield"
var count = 0
for value in it(5):
  doAssert value == 1
  inc count
doAssert count == 1
for value in it(101):
  doAssert false, "the zero branch must not yield"
