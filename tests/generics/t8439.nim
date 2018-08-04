discard """
  output: "1"
"""

type
  Cardinal = enum
    north, east, south, west

proc foo[cardinal: static[Cardinal]](): int = 1
echo(foo[north]())
