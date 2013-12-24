discard """
line: 12
errormsg: "type mismatch"
"""

proc first(it: iterator(): int): seq[int] =
  return @[]

iterator primes(): int =
  yield 1

for i in first(primes):
  break
