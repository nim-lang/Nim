discard """
  output: "(x: string here, a: 1)"
"""

proc simple[T](a: T) =
  var
    x = "string here"
  echo locals()

simple(1)

