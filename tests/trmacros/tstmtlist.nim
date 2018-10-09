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
