# Test in out checking for parameters

proc abc(x: var int) =
    x = 0

proc b() =
    abc(3) #ERROR

b()
