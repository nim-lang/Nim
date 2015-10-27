discard """
  output: "12false3ha"
"""

proc f(x: varargs[string, `$`]) = discard
template optF{f(x)}(x: varargs[expr]) =
  writeLine(stdout, x)

f 1, 2, false, 3, "ha"
