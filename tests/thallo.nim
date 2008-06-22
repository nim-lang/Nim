# Hallo

import
  os

when isMainModule:
  {.hint: "this is the main file".}

proc fac[T](x: T): T =
  # test recursive generic procs
  if x <= 1: return 1
  else: return x * fac(x-1)

#GC_disable()

echo("This was compiled by Nimrod version " & system.nimrodVersion)

echo(["a", "b", "c", "d"].len)
for x in items(["What's", "your", "name", "?"]):
  echo(x = x)
var `name` = readLine(stdin)
{.breakpoint.}
echo("Hi " & thallo.name & "!\n")

for i in 2..6:
  for j in countdown(i+4, 2):
    echo(fac(i * j))

when isMainModule:
  {.hint: "this is the main file".}
