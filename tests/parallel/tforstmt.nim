discard """
  output: '''3
4
5
6
7'''
  sortoutput: true
"""

import threadpool, math

proc p(x: int) =
  echo x

proc testFor(a, b: int; foo: var openArray[int]) =
  parallel:
    for i in max(a, 0) .. min(b, foo.len-1):
      spawn p(foo[i])

var arr = [0, 1, 2, 3, 4, 5, 6, 7]

testFor(3, 10, arr)


