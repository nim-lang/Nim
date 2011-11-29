# Fizz Buzz program

const f = "Fizz"
const b = "Buzz"
for i in 1..100:
  if i mod 3 == 0:
    echo f
  elif i mod 5 == 0:
    echo b
  elif i mod 15 == 0:
    echo f, b
  else:
    echo i

