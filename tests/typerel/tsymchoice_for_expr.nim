# bug #1988

template t(e) = discard

proc positive(x: int): int = +x
proc negative(x: int): int = -x
proc negative(x: float): float = -x

proc p1 = t(negative)
proc p2[X] = t(positive)
proc p3[X] = t(negative)

p1()      # This compiles.
p2[int]() # This compiles.
p3[int]() # This raises an error.
