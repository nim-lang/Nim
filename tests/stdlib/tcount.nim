discard """
  output: '''1
2
3
4
5
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

echo "done"
