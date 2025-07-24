block: # bug #13618
  proc test(x: Natural or BackwardsIndex): int =
    int(x)

  doAssert test(^1) == 1
  doAssert test(1) == 1
