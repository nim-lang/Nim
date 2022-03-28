# bug #9091

import streams

block:
  type Mine = ref object
    a: int

  proc write(io: Stream, t: Mine) =
    io.write("sure")

  let str = newStringStream()
  let mi = new Mine

  str.write(mi)
  str.setPosition 0
  doAssert str.readAll == "sure"

block:
  type
    AObj = object
      x: int

  proc foo(a: int): string = ""

  proc test(args: varargs[string, foo]) =
    doAssert false

  proc test(a: AObj) =
    discard

  let x = AObj()
  test(x)
