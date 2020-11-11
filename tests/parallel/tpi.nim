discard """
  output: '''3.141792613595791
3.141792613595791'''
"""

import strutils, math, threadpool

proc term(k: float): float = 4 * math.pow(-1, k) / (2*k + 1)

proc piU(n: int): float =
  var ch = newSeq[FlowVar[float]](n+1)
  for k in 0..ch.high:
    ch[k] = spawn term(float(k))
  for k in 0..ch.high:
    result += ^ch[k]

proc piS(n: int): float =
  var ch = newSeq[float](n+1)
  parallel:
    for k in 0..ch.high:
      ch[k] = spawn term(float(k))
  for k in 0..ch.high:
    result += ch[k]

echo formatFloat(piU(5000))
echo formatFloat(piS(5000))
