discard """
  output: '''0
11
1
11
2
11
3
11
4
11
5
11
6
11
7
11
8
11
9
11
11
py
py
py
py
px
6'''
"""

when true:
  proc ax =
    for xxxx in 0..9:
      var i = 0
      proc bx =
        if i > 10:
          echo xxxx
          return
        i += 1
        #for j in 0 .. 0: echo i
        bx()

      bx()
      echo i

  ax()

when true:
  proc accumulator(start: int): (proc(): int {.closure.}) =
    var x = start-1
    #let dummy = proc =
    #  discard start

    result = proc (): int =
      #var x = 9
      for i in 0 .. 0: x = x + 1

      return x

  var a = accumulator(3)
  let b = accumulator(4)
  echo a() + b() + a()


  proc outer =

    proc py() =
      # no closure here:
      for i in 0..3: echo "py"

    py()

  outer()


when true:
  proc outer2 =
    var errorValue = 3
    proc fac[T](n: T): T =
      if n < 0: result = errorValue
      elif n <= 1: result = 1
      else: result = n * fac(n-1)

    proc px() {.closure.} =
      echo "px"

    proc py() {.closure.} =
      echo "py"

    const
      mapping = {
        "abc": px,
        "xyz": py
      }
    mapping[0][1]()

    echo fac(3)


  outer2()

