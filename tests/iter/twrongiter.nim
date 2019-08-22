discard """
errormsg: "type mismatch"
line: 12
"""

proc first(it: iterator(): int): seq[int] =
  return @[]

iterator primes(): int =
  yield 1

for i in first(primes):
  break
