discard """
  output: '''1
2
3
4
5
6
7
8
9
10
11
11
py
py
py
py'''
"""

when true:
  proc ax =
    var i = 0
    proc bx =
      if i > 10: return
      i += 1
      #for j in 0 .. 0: echo i
      bx()
    
    bx()
    echo i

  ax()

when false:
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


when false:
  proc outer =
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


  outer()

