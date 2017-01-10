discard """
  output: '''1 mod 7'''
"""

# bug #3706

type Modulo[M: static[int]] = distinct int

proc modulo(a: int, M: static[int]): Modulo[M] = Modulo[M](a %% M)

proc `+`[M: static[int]](a, b: Modulo[M]): Modulo[M] = (a.int + b.int).modulo(M)

proc `$`*[M: static[int]](a: Modulo[M]): string = $(a.int) & " mod " & $(M)

when isMainModule:
  let
    a = 3.modulo(7)
    b = 5.modulo(7)
  echo a + b

