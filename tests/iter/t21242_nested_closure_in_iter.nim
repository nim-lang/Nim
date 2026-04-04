# Regression test for bug #21242
discard """
  action: compile
"""

iterator iterSome(): int =
  proc inner1() =
    let something = 6
    proc inner2() =
      let othersomething = something
    inner2()

  for n in 0 .. 10:
    inner1()
    yield n

proc test() =
  proc test1() =
    for v in iterSome():
      discard
  test1()

test()
