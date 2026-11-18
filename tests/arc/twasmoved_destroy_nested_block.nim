discard """
  matrix: "--mm:orc; --mm:arc; --mm:orc -d:release"
  output: '''
@[@[1, 2, 3], @[7, 8]]
@[@[1, 2, 3], @[7, 8]]
'''
"""

# The optimizer removes a `wasMoved(x)` / `=destroy(x)` pair only if nothing
# uses `x` between them. A use inside a loop must still count when the loop
# body also contains a nested block (here the bound check that `items` does,
# or an `if`).

proc collectFor(a: seq[int]; bs: seq[seq[int]]): seq[seq[int]] =
  var r = a
  result.add r
  for x in bs:
    r = x
    result.add r

proc collectWhile(a: seq[int]; bs: seq[seq[int]]): seq[seq[int]] =
  var r = a
  result.add r
  var i = 0
  while i < bs.len:
    r = bs[i]
    result.add r
    if i > 10:
      break
    inc i

echo collectFor(@[1, 2, 3], @[@[7, 8]])
echo collectWhile(@[1, 2, 3], @[@[7, 8]])
