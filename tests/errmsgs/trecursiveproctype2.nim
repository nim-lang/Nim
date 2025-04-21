discard """
  errormsg: "illegal recursion in type 'A'"
  line: 9
"""

# issue #8938

type 
  A = proc(acc, x: int, y: B): int
  B = proc(acc, x: int, y: A): int

proc fact(n: int): int =
  proc g(acc, a: int, b: proc(acc, a: int, b: A): int): A =
    if a == 0:
      acc
    else:
      b(a * acc, a - 1, b)
  g(1, n, g)
