discard """
  output: '''1
1234
2
234
3
34
4
4'''
"""

# bug #794
type TRange = range[0..3]

const str = "123456789"

for i in TRange.low .. TRange.high:
  echo str[i]                          #This works fine
  echo str[int(i) .. int(TRange.high)] #So does this
  #echo str[i .. TRange.high]           #The compiler complains about this
