discard """
  file: "toprprec.nim"
  output: "done"
"""
# Test operator precedence: 

assert 3+5*5-2 == 28- -26-28

proc `^-` (x, y: int): int =  
  # now right-associative!
  result = x - y
  
assert 34 ^- 6 ^- 2 == 30
assert 34 - 6 - 2 == 26
echo "done"



