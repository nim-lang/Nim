discard """
output: '''
123
113283
0
123
1
113283
@[(88, 99, 11), (88, 99, 11)]
@[(7, 6, -28), (7, 6, -28)]
12
110100
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

var x = @[(1,2,3), (4,5,6)]

for (a, b, c) in x.mitems:
  a = 88
  b = 99
  c = 11
echo x

for i, (a, b, c) in x.mpairs:
  a = 7
  b = 6
  c = -28
echo x

proc test[n]() =
  for (a,b) in @[(1,2)]:
    echo a,b
test[string]()

iterator tuples: (int, (int, int)) = yield (1,(10, 100))

template t11164 =
  for i, (a, b) in tuples():
    echo i, a , b

t11164()
