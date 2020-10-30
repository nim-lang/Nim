discard """
  targets:  "c"
  nimout:   ""
  action:   "compile"
  exitcode: 0
  timeout:  60.0
"""
import streams

type Mine = ref object
  a: int

proc write*(io: Stream, t: Mine) =
  io.write("sure")

let str = newStringStream()
let mi = new Mine

str.write(mi)