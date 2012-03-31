
var funcs: seq[proc (): int] = @[]
for i in 0..10:
  funcs.add((proc (): int = return i * i))

echo(funcs[3]())

