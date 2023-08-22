discard """
  output: '''3
4
5
6
7'''
  sortoutput: true
"""

import threadpool, os

proc p(x: int) =
  os.sleep(100 - x*10)
  echo x

proc testFor(a, b: int; foo: var openArray[int]) =
  parallel:
    for i in max(a, 0) .. min(b, foo.high):
      spawn p(foo[i])

var arr = [0, 1, 2, 3, 4, 5, 6, 7]

testFor(3, 10, arr)


