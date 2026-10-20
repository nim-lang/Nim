import mclositlib

# a generic caller: transformed at `cg` time, which lifts `getP` (adding its
# hidden env param) before `getP` is named in that process
proc gg[T](s: T): int =
  for x in getP(s, 1): result += x * 3

proc ga*(s: StateA): int = gg(s)
