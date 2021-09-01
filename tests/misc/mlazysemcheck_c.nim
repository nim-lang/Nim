when defined case_cyclic:
  import mlazysemcheck
  import mlazysemcheck_b

  proc hc*(a: int): int =
    if a>0:
      ha(a-1)*5 + hb(a-1)*6
    else:
      3

  proc gc*[T](a: T): T =
    if a>0:
      ga(a-1)*5 + gb(a-1)*6
    else:
      3

  proc someOverload*(a: int32): string = "int32"
