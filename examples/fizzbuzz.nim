# Fizz Buzz program

var f = "Fizz"
var b = "Buzz"
for i in 1..100:
  if i mod 15 == 0:
    echo f & b
    continue
  if i mod 5 == 0:
    echo b
    continue
  if i mod 3 == 0:
    echo f
    continue
  echo i

