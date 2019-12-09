discard """
  errormsg: "cannot convert array[0..0, string] to varargs[string]"
  line: 11
"""

proc f(v: varargs[string]) =
  echo(v)

f("b", "c")   # Works
f(["b", "c"]) # Works
f("b", ["c"]) # Fails
