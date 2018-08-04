discard """
  targets: "c c++ js"
  output: '''1000
0
set is empty
'''
"""

import sets

var a = initSet[int]()
for i in 1..1000:
  a.incl(i)
echo len(a)
for i in 1..1000:  
  discard a.pop()
echo len(a)

try:
  echo a.pop()
except KeyError as e:
  echo e.msg