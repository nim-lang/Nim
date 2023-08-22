discard """
  errorMsg: "attempting to call routine: '||'"
  file: "tissue710.nim"
  line: 8
"""
var sum = 0
for x in 3..1000:
  if (x mod 3 == 0) || (x mod 5 == 0):
    sum += x
echo(sum)
