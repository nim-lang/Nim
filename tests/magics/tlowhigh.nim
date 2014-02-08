discard """
  file: "tlowhigh.nim"
  output: "10"
"""
# Test the magic low() and high() procs

type
  myEnum = enum e1, e2, e3, e4, e5

var
  a: array [myEnum, int]

for i in low(a) .. high(a):
  a[i] = 0

proc sum(a: openarray[int]): int =
  result = 0
  for i in low(a)..high(a):
    inc(result, a[i])

write(stdout, sum([1, 2, 3, 4]))
#OUT 10


