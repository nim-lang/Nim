proc foo() = discard
proc bar(x: int): int = x
proc baz(x, y: int): string = $(x + y)

proc baz(a: bool; b: string; c: int): float =
  if a and b == "" and c == 0:
    result = 0.0
  else:
    result = 1.0
