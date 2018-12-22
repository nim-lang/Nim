discard """
  output: "2 3"
"""
# Test the new tuple unpacking

proc divmod(a, b: int): tuple[di, mo: int] =
  return (a div b, a mod b)

var (x, y) = divmod(15, 6)
echo x, " ", y
