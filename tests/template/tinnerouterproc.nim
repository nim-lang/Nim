block: # #20002
  proc bar(x: int): int = 10
  template foo =
    proc bar(x: int): int {.gensym.} = x + 2
    doAssert bar(3) == 5
    discard 3.bar # evaluates to 10 but only check if it compiles for now
  block:
    foo()
