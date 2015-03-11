discard """
  disabled: "true"
"""

# Now the compiler fails with OOM. yay.

# bug #794
type TRange = range[0..3]

const str = "123456789"

for i in TRange.low .. TRange.high:
  echo str[i]                          #This works fine
  echo str[int(i) .. int(TRange.high)] #So does this
  echo str[i .. TRange.high]           #The compiler complains about this
