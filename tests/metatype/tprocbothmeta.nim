discard """
  file: "tprocbothmeta.nim"
"""

proc myFun[A](x: A): auto =
  result = float(x+10)

proc myMap[T,S](sIn: seq[T], f: proc (q: T): S): seq[S] =
  result = newSeq[S](sIn.len)
  for i in 0..<sIn.len:
    result[i] = f(sIn[i])

doAssert myMap(@[1,2,3], myFun) == @[11.0, 12.0, 13.0]
