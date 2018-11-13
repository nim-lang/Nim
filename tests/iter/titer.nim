discard """
output: '''
testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest2!test3?hi
what's
your
name
hi
what's
your
name
'''
"""

# Test the new iterators

iterator xrange(fromm, to: int, step = 1): int =
  var a = fromm
  while a <= to:
    yield a
    inc(a, step)

iterator interval[T](a, b: T): T =
  var x = a
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

for x in items(["hi", "what's", "your", "name"]):
  echo(x)

const
  stringArray = ["hi", "what's", "your", "name"]

for i in 0..len(stringArray)-1:
  echo(stringArray[i])

