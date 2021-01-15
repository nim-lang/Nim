discard """
  targets:  "c"
  output:   "test AObj"
  action:   "compile"
  exitcode: 0
  timeout:  60.0
"""
import streams

block:
  type Mine = ref object
    a: int

  proc write(io: Stream, t: Mine) =
    io.write("sure")

  let str = newStringStream()
  let mi = new Mine

  str.write(mi)

block:
  type
    AObj = object
      x: int

  proc foo(a: int): string = ""

  proc test(args: varargs[string, foo]) =
    echo "varargs"

  proc test(a: AObj) =
    echo "test AObj"

  let x = AObj()
  test(x)
