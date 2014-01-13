discard """
  output: "(x: string here, a: 1, b: 3)"
"""

proc simple[T](a, b: T) = 
  var
    x = "string here"
  echo locals()
  
simple(1, 3)

