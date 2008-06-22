# Test the new iterators

import
  io

iterator xrange(fromm, to: int, step = 1): (a: int) =
  a = fromm
  while a <= to:
    yield a
    inc(a, step)

iterator interval[T](a, b: T): (x: T)

iterator interval[T](a, b: T): (x: T) =
  x = a
  while x <= b:
    yield x
    inc(x)

#
#iterator lines(filename: string): (line: string) =
#  var
#    f: tTextfile
#    shouldClose = open(f, filename)
#  if shouldClose:
#    setSpace(line, 256)
#    while readTextLine(f, line):
#      yield line
#  finally:
#    if shouldClose: close(f)
#

for i in xrange(0, 5):
  for k in xrange(1, 7):
    write(stdout, "test")

for j in interval(45, 45):
  write(stdout, "test2!")
  write(stdout, "test3?")
