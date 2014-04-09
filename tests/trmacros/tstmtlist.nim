discard """
  output: '''0
|12|
34
'''
"""

template optWrite{
  write(f, x)
  ((write|writeln){w})(f, y)
}(x, y: varargs[expr], f, w: expr) =
  w(f, "|", x, y, "|")

if true:
  echo "0"
  write stdout, "1"
  writeln stdout, "2"
  write stdout, "3"
  echo "4"
