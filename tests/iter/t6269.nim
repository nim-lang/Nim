discard """
  targets: "c js"
  output: '''
1 2
1 2
1 2
1 2
1 2
1 5
3 2
3 5
'''
"""

# bug #6269: an inline iterator with closures, nested in itself
iterator it(n: int): int =
  var x = n
  yield (proc (): int = x)()
  yield (proc (): int = x)()

proc main =
  for a in it(1):
    for b in it(2):
      echo a, " ", b

main()

iterator it2(n: int): int =
  let k = n
  var x = (proc (): int = k)()
  yield x
  while true:
    x += 1
    if x > n + 1: break
    yield (proc (): int = x + k)()

for a in it2(1):
  for b in it2(2):
    echo a, " ", b
