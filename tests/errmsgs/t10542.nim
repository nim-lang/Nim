discard """
  matrix: "--hintaserror:ConvFromXtoItselfNotNeeded"
"""

# bug #10542

proc f(args: varargs[string, string], length: int) =
  doAssert args.len == length

# main use case that requires type conversion (no warning here)
f("a", "b", 2)
f("a", 1)


proc m(args: varargs[cstring, cstring]) =
  doAssert args.len == 2

# main use case that requires type conversion (no warning here)
m("a", "b")

# if an argument already is cstring there's a warning
let x: cstring = "x"
m("a", x)
m(x, "a")