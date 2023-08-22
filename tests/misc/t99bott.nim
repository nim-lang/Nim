discard """
  errormsg: "cannot evaluate at compile time: bn"
  file: "t99bott.nim"
  line: 26
"""

## 99 Bottles of Beer
## http://www.99-bottles-of-beer.net/
## Nim version

## Author: Philippe Lhoste <PhiLho(a)GMX.net> http://Phi.Lho.free.fr
# 2012-11-25
# Loosely based on my old Lua version... Updated to current official lyrics.

proc GetBottleNumber(n: int): string =
  var bs: string
  if n == 0:
    bs = "No more bottles"
  elif n == 1:
    bs = "1 bottle"
  else:
    bs = $n & " bottles"
  return bs & " of beer"

for bn in countdown(99, 1):
  const cur = GetBottleNumber(bn)
  echo(cur, " on the wall, ", cur, ".")
  echo("Take one down and pass it around, ", GetBottleNumber(bn-1),
       " on the wall.\n")

echo "No more bottles of beer on the wall, no more bottles of beer."
echo "Go to the store and buy some more, 99 bottles of beer on the wall."
