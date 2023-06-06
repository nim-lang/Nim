when defined case1:
  proc fn1*() = discard

when defined case2:
  proc fn1*() = discard

when defined case3:
  proc fn1*() = discard
  proc fn2*() = discard

when defined case4:
  proc fn1*() = discard
  proc fn2*() = discard

when defined case5:
  proc fn1*() = discard

when defined case6:
  proc fn1*() = discard

when defined case7:
  proc fn1*() = discard

when defined case8:
  import mused3b
  export mused3b

when defined case9:
  import mused3b
  export mused3b

when defined case10:
  import mused3b
  type Bar* = object
    b0*: Foo

when defined case11:
  proc fn1*() = discard

when defined case12:
  proc fn1*() = discard
