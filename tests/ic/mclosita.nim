import mclositlib

# a non-generic caller: lowered by `lower`, so this module's `cg` names `getP`
# before anything lifts it in that process
proc fa*(s: StateA): int =
  for x in getP(s, 0): result += x
