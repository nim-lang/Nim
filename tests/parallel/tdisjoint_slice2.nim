
import threadpool

proc f(a: openArray[int]) =
  for x in a: echo x

proc f(a: int) = echo a

proc main() =
  var a: array[0..30, int]
  parallel:
    spawn f(a[0..15])
    #spawn f(a[16..30])
    var i = 16
    while i <= 29:
      spawn f(a[i])
      spawn f(a[i+1])
      inc i, 2
      # is correct here

main()
