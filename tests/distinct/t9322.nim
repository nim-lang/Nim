discard """
  output: apr
"""

type Fix = distinct string

proc `$`(f: Fix): string {.borrow.}

proc mystr(s: string) =
  echo s

mystr($Fix("apr"))
