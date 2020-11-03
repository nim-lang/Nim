discard """
  outputsub: "EVEN 28"
"""

import threadpool, locks

block one:
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


block two:
  var echoLock: Lock
  initLock echoLock

  proc f(a: openArray[int]) =
    for x in a:
      withLock echoLock:
        echo x

  proc f(a: int) =
    withLock echoLock:
      echo a

  proc main() =
    var a: array[0..9, int] = [0,1,2,3,4,5,6,7,8,9]
    parallel:
      spawn f(a[0..2])
      #spawn f(a[16..30])
      var i = 3
      while i <= 8:
        spawn f(a[i])
        spawn f(a[i+1])
        inc i, 2
        # is correct here

  main()
