discard """
output: '''
123
113283
0
123
1
113283
'''
"""

let t1 = (1, 2, 3)
let t2 = (11, 32, 83)
let s = @[t1, t2]

for (a, b, c) in s:
  echo a, b, c

for i, (a, b, c) in s:
  echo i
  echo a, b, c

