proc resizeCints*(s: var seq[cint], n: int) =
  s.setLen(n)

proc cintLen*(s: seq[cint]): int =
  result = s.len
