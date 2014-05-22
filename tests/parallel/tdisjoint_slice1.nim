discard """
  outputsub: "EVEN 28"
"""

import threadpool

proc odd(a: int) =  echo "ODD  ", a
proc even(a: int) = echo "EVEN ", a

proc main() =
  var a: array[0..30, int]
  for i in low(a)..high(a): a[i] = i
  parallel:
    var i = 0
    while i <= 29:
      spawn even(a[i])
      spawn odd(a[i+1])
      inc i, 2
      # is correct here

main()
