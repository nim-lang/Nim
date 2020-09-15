discard """
  cmd: "nim c --gc:arc $file"
  nimout: "tcopytosink_warning.nim(13, 9) Hint: passing 'x' to a sink parameter introduces an implicit copy; if possible, rearrange your program's control flow to prevent it [Performance]"
  output: "x"
"""

proc test(v: var seq[string], x: sink string) =
  v.add x

var v = @["a", "b", "c"]
var x = "x"

test(v, x)  # produces warning
test(v, copy(x)) # no warning

echo x  # use after sink