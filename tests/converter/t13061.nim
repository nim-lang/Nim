discard """
  errormsg: "type mismatch: got <string> but expected 'int'"
  line: 10
"""

# bug #13061: a converter defined after a matching one is still checked
type
  A = distinct int
converter toA(a: A): int = (int)a
converter anotherToA(a: A): int = "lol"
