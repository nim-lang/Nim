discard """
  output: '''0
|12|
34
'''
"""

template optWrite{
  write(f, x)
  ((write|writeLine){w})(f, y)
}(x, y: varargs[untyped], f, w: untyped) =
  w(f, "|", x, y, "|")

if true:
  echo "0"
  write stdout, "1"
  writeLine stdout, "2"
  write stdout, "3"
  echo "4"

# bug #7972

template optimizeLogWrites*{
  write(f, x)
  write(f, y)
}(x, y: string{lit}, f: File) =
  write(f, x & y)

proc foo() =
  const N = 1
  stdout.write("")
  stdout.write("")

foo()
