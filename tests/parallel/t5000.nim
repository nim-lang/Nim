discard """
  output: '''50005000'''
  disabled: "true"
"""

# XXX this seems to deadlock certain Linux machines

import threadpool, strutils

proc foo(x: int): string = $x

proc main() =
  var a = newSeq[int]()
  for i in 1..10000:
    add(a, i)

  var s = 0
  for i in a:
    s += parseInt(^spawn(foo(i)))
  echo s

setMaxPoolSize 2

parallel:
  spawn main()
