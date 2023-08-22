discard """
  output: true
"""

proc cmpx(d: int): bool {.inline.} = d > 0

proc abc[C](cx: C, d: int) =
  echo cx(d)
  
abc(cmpx, 10)
