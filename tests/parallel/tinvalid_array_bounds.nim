discard """
  errormsg: "cannot prove (i)..(i) disjoint from (i + 1)..(i + 1)"
  line: 20
"""

import threadpool

proc f(a: openArray[int]) =
  for x in a: echo x

proc f(a: int) = echo a

proc main() =
  var a: array[0..30, int]
  parallel:
    spawn f(a[0..15])
    spawn f(a[16..30])
    var i = 0
    while i <= 30:
      spawn f(a[i])
      spawn f(a[i+1])
      inc i
      #inc i  # inc i, 2  would be correct here

main()
