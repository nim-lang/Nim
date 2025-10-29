var stmtListExpr = (echo "foo"; 111)

if false:
  discard
elif false:
  discard
else:
  discard

var caseExpr = true
case caseExpr
of true:
  discard
else:
  discard

when sizeof(int) == 2:
  echo "running on a 16 bit system!"
elif sizeof(int) == 4:
  echo "running on a 32 bit system!"
elif sizeof(int) == 8:
  echo "running on a 64 bit system!"
else:
  echo "cannot happen!"

while true:
  break

var x = 2

while x != 0:
  if x == 2:
    x = 0
    continue
  else:
    break

block testblock:
  while true:
    if x > -1:
      break testblock

for i in 0 .. 3:
  discard i
