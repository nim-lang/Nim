discard """
  output: '''1
2
3
4
5
0.0
-1.0
-2.0
-3.0
-4.0
-5.0
0.0
1.0
2.0
0.0
1.0
2.0
0.0
1.0
2.0
done'''
"""

# bug #1845, #2224

var arr = [3,2,1,5,4]

# bubble sort
for i in low(arr)..high(arr):
  for j in i+1..high(arr): # Error: unhandled exception: value out of range: 5 [RangeError]
    if arr[i] > arr[j]:
      let tmp = arr[i]
      arr[i] = arr[j]
      arr[j] = tmp

for i in low(arr)..high(arr):
  echo arr[i]

# check this terminates:
for x in countdown('\255', '\0'):
  discard

# PR #7668
for x in countdown(0.0, -5.0):
  echo x

for x in countup(0.0, 2.0):
  echo x

for x in 0.0 .. 2.0:
  echo x

for x in 0.0'f32 .. 2.0'f64:
  echo x

echo "done"
