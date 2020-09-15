discard """
  cmd: "nim c --gc:arc $file"
  nimout: '''tcopytosink_warning.nim(17, 7) Hint: myhint [User]
tcopytosink_warning.nim(19, 9) Hint: passing 'x' to a sink parameter introduces an implicit copy; if possible, rearrange your program's control flow to prevent it or use 'copy(x)' to hint the compiler it is intentional [Performance]
'''
  output: "x"
"""
import macros

proc test(v: var seq[string], x: sink string) =
  v.add x

var v = @["a", "b", "c"]
var x = "x"

static:
  hint("myhint")
test(v, copy(x)) # no warning
test(v, x)  # produces warning

echo x  # use after sink

