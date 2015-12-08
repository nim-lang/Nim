discard """
  file: "ttemplreturntype.nim"
"""

template `=~` (a: int, b: int): bool = false
var foo = 2 =~ 3
