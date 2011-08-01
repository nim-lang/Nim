discard """
  output: "11"
"""

proc p(x, y: int): int = 
  result = x + y

echo p((proc (): int = 
          var x = 7
          return x)(),
       (proc (): int = return 4)())

