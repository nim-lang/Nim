import std/private/digitsutils

template main =
  block: # digits10
    doAssert digits10(0'u64) == 1
    # checks correctness on all powers of 10 + [0,-1,1]
    var x = 1'u64
    var num = 1
    while true:
      # echo (x, num)
      doAssert digits10(x) == num
      doAssert digits10(x+1) == num
      if x > 1:
        doAssert digits10(x-1) == num - 1
      num += 1
      let xOld = x
      x *= 10
      if x < xOld:
        # wrap-around
        break

static: main()
main()
