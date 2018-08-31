discard """
  output: "1"
"""

converter toInt*(x: char): int = 
  x.int

case 0
of 'a': echo 0
else: echo 1
