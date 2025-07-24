discard """
  matrix: "--mm:refc"
  nimout: '''1
2
3
[1, 2, 3]'''

  output: '''1
2
3
[1, 2, 3]'''
"""

# todo fixme it doesn't work with ORC
proc doIt(a: openArray[int]) =
  echo a

proc foo() = 
  var bug {.global, compiletime.}: seq[int]
  bug = @[1, 2 ,3]
  for i in 0 .. high(bug): echo bug[i]
  doIt(bug)

static:
  foo()
foo()
