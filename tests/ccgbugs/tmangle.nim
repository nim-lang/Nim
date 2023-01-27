block:
  proc hello() =
    let NAN_INFINITY = 12
    doAssert NAN_INFINITY == 12
    let INF = "2.0"
    doAssert INF == "2.0"
    let NAN = 2.3
    doAssert NAN == 2.3

  hello()

block:
  proc hello(NAN: float) =
    doAssert NAN == 2.0

  hello(2.0)
