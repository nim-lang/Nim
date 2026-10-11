discard """
  targets: "c js"
  output: '''
@[1, 2, 3]
[1, 2, 3]
[1, 2, 3]
6
abc
'''
"""

# bug #2652: converters producing a seq/string for an openArray parameter
type
  TestCol[T] = object
    data: seq[T]
  Name = object
    s: string

converter toSeq[T](x: TestCol[T]): seq[T] = x.data
converter toStr(x: Name): string = x.s

var y = TestCol[int](data: @[1, 2, 3])

proc f[T](x: seq[T]) = echo x
proc g[T](x: openArray[T]) = echo x
proc h(x: openArray[int]) = echo x
proc sum(x: openArray[int]): int =
  for a in x: result += a

f(y)
g(y)
h(y)
echo sum(y)

proc chars(x: openArray[char]) =
  var s = ""
  for c in x: s.add c
  echo s

chars(Name(s: "abc"))
