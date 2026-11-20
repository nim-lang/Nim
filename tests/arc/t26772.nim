discard """
  matrix: "--mm:orc; --mm:refc"
  output: '''
2
3
hello
world
'''
"""

# bug #26772
proc sinkInto[T](tgt, src: var T) =
  `=sink`(tgt, src)

proc copyInto[T](tgt, src: var T) =
  `=copy`(tgt, src)

var
  a = 1
  b = 2
  c = 3
sinkInto(a, b)
echo a
copyInto(a, c)
echo a

var
  s1 = "x"
  s2 = "hello"
  s3 = "world"
sinkInto(s1, s2)
echo s1
copyInto(s1, s3)
echo s1
