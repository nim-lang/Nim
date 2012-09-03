discard """
  output: "12false3ha"
"""

proc f(x: varargs[string, `$`]) = nil
template optF{f(X)}(x: varargs[expr]) = 
  writeln(stdout, x)

f 1, 2, false, 3, "ha"
